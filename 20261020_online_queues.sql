-- Additive migration. Existing wait_report data and policies are unchanged.
begin;

create table public.wl_venues (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 70),
  city text not null check (char_length(city) between 1 and 70),
  country text not null check (char_length(country) between 1 and 70),
  minutes integer not null default 10 check (minutes between 1 and 180),
  created_at timestamptz not null default now()
);
create index wl_venues_owner on public.wl_venues(owner_id);
create table public.wl_tickets (
  id uuid primary key default gen_random_uuid(),
  number bigint generated always as identity unique,
  venue_id uuid not null references public.wl_venues(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'waiting' check (status in ('waiting','called','done','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index wl_one_active_ticket on public.wl_tickets(venue_id,user_id)
  where status in ('waiting','called');
create index wl_ticket_queue on public.wl_tickets(venue_id,status,number);
create index wl_ticket_user on public.wl_tickets(user_id,created_at desc);
alter table public.wl_venues enable row level security;
alter table public.wl_tickets enable row level security;
create policy wl_owner_read_venues on public.wl_venues for select to authenticated
  using (owner_id=(select auth.uid()));
create policy wl_read_own_tickets on public.wl_tickets for select to authenticated
  using (user_id=(select auth.uid()) or exists (
    select 1 from public.wl_venues v where v.id=venue_id and v.owner_id=(select auth.uid())
  ));
-- All writes use narrowly scoped RPCs; clients cannot forge ownership or status.
revoke all on public.wl_venues, public.wl_tickets from anon, authenticated;
grant select on public.wl_venues, public.wl_tickets to authenticated;

create function public.wl_list_venues()
returns table(id uuid,name text,city text,country text,minutes integer,waiting bigint,called bigint)
language sql stable security definer set search_path='' as $$
 select v.id,v.name,v.city,v.country,v.minutes,
   count(t.id) filter(where t.status='waiting'),count(t.id) filter(where t.status='called')
 from public.wl_venues v left join public.wl_tickets t on t.venue_id=v.id
 group by v.id order by v.created_at desc limit 500;
$$;

create function public.wl_create_venue(p_name text,p_city text,p_country text,p_minutes integer)
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

create function public.wl_join(p_venue uuid)
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
 if (select count(*) from public.wl_tickets where user_id=caller and status in ('waiting','called'))>=5 then
   raise exception 'TICKET_LIMIT';
 end if;
 if (select count(*) from public.wl_tickets where venue_id=p_venue and status='waiting')>=500 then
   raise exception 'QUEUE_FULL';
 end if;
 insert into public.wl_tickets(venue_id,user_id) values(p_venue,caller) returning id into result;
 return result;
end; $$;

create function public.wl_my_tickets()
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

create function public.wl_manage(p_venue uuid,p_action text,p_ticket uuid default null)
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

create function public.wl_cancel(p_ticket uuid)
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

revoke all on function public.wl_list_venues() from public,anon,authenticated;
revoke all on function public.wl_create_venue(text,text,text,integer) from public,anon,authenticated;
revoke all on function public.wl_join(uuid) from public,anon,authenticated;
revoke all on function public.wl_my_tickets() from public,anon,authenticated;
revoke all on function public.wl_manage(uuid,text,uuid) from public,anon,authenticated;
revoke all on function public.wl_cancel(uuid) from public,anon,authenticated;
grant execute on function public.wl_list_venues() to anon,authenticated;
grant execute on function public.wl_create_venue(text,text,text,integer),public.wl_join(uuid),
 public.wl_my_tickets(),public.wl_manage(uuid,text,uuid),public.wl_cancel(uuid) to authenticated;
commit;
