# WaitLess — comptes et files partagées

## État

Le site public existant reste inchangé. `online.html` est une version en préparation,
en français et en anglais ; l’interface mondiale existante conserve ses six langues.
Les tables et fonctions SQL de ce dossier n’ont pas encore été appliquées au projet
Supabase. Aucun abonnement, encaissement ou droit payant n’est activé.

## Activation dans Supabase

1. Vérifier le projet `ropvmaqgtfjsrnipyvth` et sauvegarder son schéma.
2. Appliquer une fois `20261020_online_queues.sql`.
   La migration est transactionnelle et ne modifie pas `wait_report`.
3. Activer la connexion par e-mail avec liens de connexion, avec un SMTP de production.
4. Configurer le Site URL sur `https://voluble-pie-7e8eda.netlify.app` et autoriser
   la redirection exacte `https://voluble-pie-7e8eda.netlify.app/online.html`.
5. Tester avec deux comptes distincts : établissement et client. Vérifier qu’un
   troisième compte ne peut ni lire les tickets privés des autres ni gérer leur file.
6. Tester connexion, déconnexion, ticket en double, annulation, appel FIFO,
   fin du service et mises à jour sur deux appareils. Les mises à jour utilisent
   une actualisation toutes les 10 secondes, sans dépendre d’une publication Realtime.
7. Après validation, remplacer l’avis de préparation et ajouter un lien vers
   `online.html` dans la navigation principale. Ne pas remplacer la démo par erreur.

## Protections

- Les clients ne peuvent pas écrire directement dans les tables de tickets.
- Les opérations sensibles vérifient `auth.uid()` et le propriétaire de la file.
- Les demandes d’entrée et la gestion d’une file sont sérialisées par verrou SQL.
- Un seul ticket actif par client et établissement ; cinq tickets actifs maximum
  par compte ; dix établissements maximum par compte ; 500 clients en attente par file.
- La liste publique ne contient que les établissements et des compteurs agrégés.
- Les données d’identité et les codes de tickets ne sont pas publiés dans cette liste.
- Les liens de connexion doivent être soumis aux limites d’envoi et à la protection
  contre l’abus configurées dans Supabase ; ce code ne contourne aucune limite.

## Paiements et lancement : encore à réaliser

Connecter le compte Stripe du propriétaire. Définir et implémenter les avantages
Premium et Pro réellement livrés avant d’accepter un paiement. Les prix envisagés
restent 2,99 EUR/mois et 29 EUR/mois, sans décision fiscale implicite.

Prévoir Checkout côté serveur, une vérification de signature du webhook, la gestion
idempotente des événements, la synchronisation des droits depuis Stripe et un portail
de résiliation. Tester succès, échec, remboursement, expiration et annulation avant
le passage au mode réel. Aucune clé secrète Stripe ou Supabase ne doit être mise
dans les fichiers publics.

Finaliser les informations du vendeur, les conditions de vente et la confidentialité
avec les données exactes du propriétaire. Elles ne sont pas inventées dans cette version.

## Validation effectuée

La migration a été exécutée dans PostgreSQL via PGlite avec trois identités et
les rôles anon/authenticated. Vérifications réussies : isolation RLS entre clients,
lecture des compteurs publics sans identités, refus des écritures directes,
absence de ticket en double, ordre FIFO, estimation d’attente, gestion réservée au
propriétaire, annulation réservée au client et reprise d’un nouveau ticket.
Cela ne remplace pas le test sur le projet Supabase avec envoi réel des liens
de connexion et deux navigateurs. La syntaxe JavaScript de `online.html` est vérifiée.

## Documentation de référence

- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/database/functions
- https://supabase.com/docs/guides/auth/auth-email-passwordless
