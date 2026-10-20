-- Add queue controls and direct venue links. Privileged helpers stay outside the exposed schema.
-- Run after 20261020_online_queues.sql. No ticket or report data is deleted.
begin;
alter table public.wl_venues add column if not exists is_open boolean not null default true;
create schema if not exists waitless_private;
revoke all on schema waitless_private from public;
grant usage on schema waitless_private to anon,authenticated;

create or replace function waitless_private.list_venues_v2()
returns table(id uuid,name text,city text,country text,minutes integer,is_open boolean,waiting bigint,called bigint)
language sql stable security definer set search_path='' as $$
 select v.id,v.name,v.city,v.country,v.minutes,v.is_open,
 count(t.id) filter(where t.status='waiting'),count(t.id) filter(where t.status='called')
 from public.wl_venues v left join public.wl_tickets t on t.venue_id=v.id
 group by v.id order by v.created_at desc,v.id limit 500;
$$;

-- Direct QR links can resolve venues outside the 500-row discovery list.
create or replace function waitless_private.get_venue(p_venue uuid)
returns table(id uuid,name text,city text,country text,minutes integer,is_open boolean,waiting bigint,called bigint)
language sql stable security definer set search_path='' as $$
 select v.id,v.name,v.city,v.country,v.minutes,v.is_open,
 count(t.id) filter(where t.status='waiting'),count(t.id) filter(where t.status='called')
 from public.wl_venues v left join public.wl_tickets t on t.venue_id=v.id
 where v.id=p_venue group by v.id;
$$;

create or replace function waitless_private.set_open(p_venue uuid,p_open boolean)
returns boolean language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'SIGN_IN_REQUIRED'; end if;
 if p_open is null then raise exception 'INVALID_STATE'; end if;
 -- Same venue row lock as join/call/cancel: closing and joining are serialized.
 update public.wl_venues set is_open=p_open where id=p_venue and owner_id=auth.uid();
 if not found then raise exception 'NOT_VENUE_OWNER'; end if;
 return p_open;
end; $$;

create or replace function waitless_private.join_queue(p_venue uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare result uuid; caller uuid:=auth.uid();
begin
 if caller is null then raise exception 'SIGN_IN_REQUIRED'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(caller::text,0));
 perform 1 from public.wl_venues where id=p_venue for update;
 if not found then raise exception 'VENUE_NOT_FOUND'; end if;
 select id into result from public.wl_tickets where venue_id=p_venue and user_id=caller
   and status in ('waiting','called');
 if result is not null then return result; end if;
 if not (select is_open from public.wl_venues where id=p_venue) then
   raise exception 'QUEUE_CLOSED';
 end if;
 if (select count(*) from public.wl_tickets where user_id=caller and status in ('waiting','called'))>=5 then
   raise exception 'TICKET_LIMIT';
 end if;
 if (select count(*) from public.wl_tickets where venue_id=p_venue and status='waiting')>=500 then
   raise exception 'QUEUE_FULL';
 end if;
 insert into public.wl_tickets(venue_id,user_id) values(p_venue,caller) returning id into result;
 return result;
end; $$;


-- Public API wrappers execute with caller privileges; authority lives in private helpers.
create or replace function public.wl_list_venues_v2()
returns table(id uuid,name text,city text,country text,minutes integer,is_open boolean,waiting bigint,called bigint)
language sql stable security invoker set search_path='' as $$
 select * from waitless_private.list_venues_v2();
$$;
create or replace function public.wl_get_venue(p_venue uuid)
returns table(id uuid,name text,city text,country text,minutes integer,is_open boolean,waiting bigint,called bigint)
language sql stable security invoker set search_path='' as $$
 select * from waitless_private.get_venue(p_venue);
$$;
create or replace function public.wl_set_open(p_venue uuid,p_open boolean)
returns boolean language sql security invoker set search_path='' as $$
 select waitless_private.set_open(p_venue,p_open);
$$;
create or replace function public.wl_join(p_venue uuid)
returns uuid language sql security invoker set search_path='' as $$
 select waitless_private.join_queue(p_venue);
$$;
revoke all on function waitless_private.list_venues_v2(),waitless_private.get_venue(uuid),
 waitless_private.set_open(uuid,boolean),waitless_private.join_queue(uuid) from public,anon,authenticated;
grant execute on function waitless_private.list_venues_v2(),waitless_private.get_venue(uuid) to anon,authenticated;
grant execute on function waitless_private.set_open(uuid,boolean),waitless_private.join_queue(uuid) to authenticated;
revoke all on function public.wl_list_venues_v2(),public.wl_get_venue(uuid),
 public.wl_set_open(uuid,boolean),public.wl_join(uuid) from public,anon,authenticated;
grant execute on function public.wl_list_venues_v2(),public.wl_get_venue(uuid) to anon,authenticated;
grant execute on function public.wl_set_open(uuid,boolean),public.wl_join(uuid) to authenticated;
-- Preserve existing API signatures while moving their privileged bodies out of public.
create or replace function waitless_private.list_venues()
returns table(id uuid,name text,city text,country text,minutes integer,waiting bigint,called bigint)
language sql stable security definer set search_path='' as $$
 select v.id,v.name,v.city,v.country,v.minutes,
   count(t.id) filter(where t.status='waiting'),count(t.id) filter(where t.status='called')
 from public.wl_venues v left join public.wl_tickets t on t.venue_id=v.id
 group by v.id order by v.created_at desc limit 500;
$$;
create or replace function public.wl_list_venues()
returns table(id uuid,name text,city text,country text,minutes integer,waiting bigint,called bigint) language sql stable security invoker set search_path='' as $$
 select * from waitless_private.list_venues();
$$;
revoke all on function waitless_private.list_venues(), public.wl_list_venues() from public,anon,authenticated;
grant execute on function waitless_private.list_venues(),public.wl_list_venues() to anon,authenticated;

create or replace function waitless_private.create_venue(p_name text,p_city text,p_country text,p_minutes integer)
returns uuid language plpgsql security definer set search_path='' as $$
declare result uuid; caller uuid:=auth.uid();
begin
 if caller is null then raise exception 'SIGN_IN_REQUIRED'; end if;
 -- A per-owner lock also serializes requests from several devices.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(caller::text,0));
 if (select count(*) from public.wl_venues where owner_id=caller)>=10 then
   raise exception 'VENUE_LIMIT';
 end if;
 insert into public.wl_venues(owner_id,name,city,country,minutes)
 values(caller,btrim(p_name),btrim(p_city),btrim(p_country),p_minutes) returning id into result;
 return result;
end; $$;
create or replace function public.wl_create_venue(p_name text,p_city text,p_country text,p_minutes integer)
returns uuid language sql security invoker set search_path='' as $$
 select waitless_private.create_venue(p_name,p_city,p_country,p_minutes);
$$;
revoke all on function waitless_private.create_venue(text,text,text,integer), public.wl_create_venue(text,text,text,integer) from public,anon,authenticated;
grant execute on function waitless_private.create_venue(text,text,text,integer),public.wl_create_venue(text,text,text,integer) to authenticated;

create or replace function waitless_private.my_tickets()
returns table(id uuid,number bigint,venue_id uuid,venue_name text,city text,status text,
 created_at timestamptz,"position" bigint,estimated_minutes bigint)
language sql stable security definer set search_path='' as $$
 select t.id,t.number,t.venue_id,v.name,v.city,t.status,t.created_at,
 case when t.status='waiting' then
  (select count(*)+1 from public.wl_tickets a where a.venue_id=t.venue_id and a.status='waiting' and a.number<t.number)
 else 0 end,
 case when t.status='waiting' then
  ((select count(*) from public.wl_tickets a where a.venue_id=t.venue_id and
   (a.status='called' or (a.status='waiting' and a.number<t.number)))*v.minutes)
 else 0 end
 from public.wl_tickets t join public.wl_venues v on v.id=t.venue_id
 where t.user_id=auth.uid() order by t.number desc limit 100;
$$;
create or replace function public.wl_my_tickets()
returns table(id uuid,number bigint,venue_id uuid,venue_name text,city text,status text,created_at timestamptz,"position" bigint,estimated_minutes bigint) language sql stable security invoker set search_path='' as $$
 select * from waitless_private.my_tickets();
$$;
revoke all on function waitless_private.my_tickets(), public.wl_my_tickets() from public,anon,authenticated;
grant execute on function waitless_private.my_tickets(),public.wl_my_tickets() to authenticated;

create or replace function waitless_private.manage_queue(p_venue uuid,p_action text,p_ticket uuid default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare caller uuid:=auth.uid(); result uuid;
begin
 if caller is null then raise exception 'SIGN_IN_REQUIRED'; end if;
 perform 1 from public.wl_venues where id=p_venue and owner_id=caller for update;
 if not found then raise exception 'NOT_VENUE_OWNER'; end if;
 if p_action='call' then
   if exists(select 1 from public.wl_tickets where venue_id=p_venue and status='called') then
     raise exception 'COMPLETE_CURRENT_FIRST';
   end if;
   select id into result from public.wl_tickets where venue_id=p_venue and status='waiting'
     order by number limit 1 for update;
   if result is null then raise exception 'QUEUE_EMPTY'; end if;
   update public.wl_tickets set status='called',updated_at=now() where id=result;
 elsif p_action='complete' then
   update public.wl_tickets set status='done',updated_at=now()
     where id=p_ticket and venue_id=p_venue and status='called' returning id into result;
   if result is null then raise exception 'TICKET_NOT_CALLED'; end if;
 else raise exception 'INVALID_ACTION';
 end if;
 return result;
end; $$;
create or replace function public.wl_manage(p_venue uuid,p_action text,p_ticket uuid default null)
returns uuid language sql security invoker set search_path='' as $$
 select waitless_private.manage_queue(p_venue,p_action,p_ticket);
$$;
revoke all on function waitless_private.manage_queue(uuid,text,uuid), public.wl_manage(uuid,text,uuid) from public,anon,authenticated;
grant execute on function waitless_private.manage_queue(uuid,text,uuid),public.wl_manage(uuid,text,uuid) to authenticated;

create or replace function waitless_private.cancel_ticket(p_ticket uuid)
returns boolean language plpgsql security definer set search_path='' as $$
declare caller uuid:=auth.uid(); venue uuid;
begin
 if caller is null then raise exception 'SIGN_IN_REQUIRED'; end if;
 select venue_id into venue from public.wl_tickets where id=p_ticket and user_id=caller;
 if venue is null then raise exception 'TICKET_NOT_FOUND'; end if;
 perform 1 from public.wl_venues where id=venue for update;
 update public.wl_tickets set status='cancelled',updated_at=now()
  where id=p_ticket and user_id=caller and status in ('waiting','called');
 return found;
end; $$;
create or replace function public.wl_cancel(p_ticket uuid)
returns boolean language sql security invoker set search_path='' as $$
 select waitless_private.cancel_ticket(p_ticket);
$$;
revoke all on function waitless_private.cancel_ticket(uuid), public.wl_cancel(uuid) from public,anon,authenticated;
grant execute on function waitless_private.cancel_ticket(uuid),public.wl_cancel(uuid) to authenticated;
commit;
