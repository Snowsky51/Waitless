# WaitLess — comptes et files partagées

## État

Le site public comporte un lien vers la version bêta des files partagées. `online.html` est une version en préparation,
en français et en anglais ; l’interface mondiale existante conserve ses six langues.
Les tables et fonctions SQL ont été appliquées au projet Supabase le 20 octobre 2026.
Les contrôles confirment RLS actif sur les deux tables, les signalements existants conservés
et l’entrée dans une file réservée aux comptes connectés.
Le Site URL et la redirection exacte vers online.html sont enregistrés.
SMTP personnalisé absent : les inscriptions publiques restent bloquées. Aucun abonnement, encaissement ou droit payant n’est activé.

## Activation dans Supabase

1. Vérifier le projet `ropvmaqgtfjsrnipyvth` et sauvegarder son schéma.
2. Migration `20261020_online_queues.sql` déjà appliquée : ne pas la réexécuter.
   La migration est transactionnelle et ne modifie pas `wait_report`.
3. Activer la connexion par e-mail avec liens de connexion, avec un SMTP de production.
4. Configurer le Site URL sur `https://voluble-pie-7e8eda.netlify.app` et autoriser
   la redirection exacte `https://voluble-pie-7e8eda.netlify.app/online.html`.
5. Tester avec deux comptes distincts : établissement et client. Vérifier qu’un
   troisième compte ne peut ni lire les tickets privés des autres ni gérer leur file.
6. Tester connexion, déconnexion, ticket en double, annulation, appel FIFO,
   fin du service et mises à jour sur deux appareils. Les mises à jour utilisent
   une actualisation toutes les 10 secondes, sans dépendre d’une publication Realtime.
7. Le lien vers `online.html` est ajouté. Après configuration SMTP et validation,
   mettre à jour l’avis bêta pour refléter la disponibilité réelle.

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


## Mise à jour — fonctions 1 à 4

Les fichiers `online.html`, `shared-queues.js` et `qrcode.js` préparent :
- une entrée directe sur la file via `online.html?venue=<uuid>` ;
- un QR code généré localement, sans service externe, et exportable en SVG ;
- le numéro du client, les personnes devant lui, l'attente estimative et l'annulation ;
- les commandes propriétaire ouvrir/fermer, appeler le suivant et terminer le service.

La migration additionnelle `20261020_queue_controls.sql` a été appliquée et vérifiée le 20 octobre 2026.
Elle est enregistrée dans Supabase sous `waitless_queue_controls_and_private_helpers`.
Les fonctions publiques exécutent avec les droits de l’appelant et délèguent aux fonctions internes
du schéma non exposé `waitless_private`. Les contrôles de sécurité Supabase ne signalent plus d’avis.
La migration initiale a déjà été appliquée : ne pas la rejouer sur le projet existant.
Les opérations de fermeture et d'entrée prennent le même verrou de ligne côté PostgreSQL.
La fermeture bloque les nouvelles entrées mais conserve les tickets actifs et leur traitement.
La vue publique n'expose pas les comptes ou codes de tickets. La synchronisation utilise un
rafraîchissement toutes les 10 secondes ; les actions sont suspendues en cas d'échec de synchronisation.
Le lien e-mail conserve une redirection exacte vers `online.html`. Le choix d'établissement est
mémorisé localement pendant 30 minutes et n'est pas garanti sur un autre navigateur ou appareil.

### Essai sans publication

`python3 build_private_queues.py` produit `../outputs/WaitLess_Files_Test_Prive.html`.
Ce fichier autonome embarque uniquement un adaptateur de démonstration : rôles établissement,
client 1 et client 2 simulés sur le même appareil. Aucune connexion Supabase, aucun e-mail,
aucun paiement et aucune communication entre téléphones. Le QR code y encode une URL
`example.invalid` clairement signalée comme exemple, pour éviter de partager une file inactive.
L'adaptateur privé n'est jamais chargé par `online.html`.

### Vérifications

Après `npm install`, `npm test` reconstruit la démo et vérifie :
- les migrations dans PostgreSQL via PGlite, l'isolation RLS, les restrictions propriétaire,
  les doubles tickets, la fermeture, la réouverture, l'ordre FIFO et les temps estimatifs ;
- les écrans via JSDOM : changement de rôles, ticket privé, passage de position, appel,
  fin du service, annulation, aperçu QR et traduction français/anglais.
Ces contrôles ne remplacent pas un essai visuel sur Android ni un essai réel sur deux téléphones.

Le propriétaire a autorisé la publication des nouveaux ajouts. Le site conserve la démonstration
mondiale et la carte existantes. `demo.html` permet de simuler les nouveaux parcours sans compte ;
`online.html` utilise les comptes et files Supabase. L’envoi d’e-mails aux utilisateurs externes
et les paiements restent à configurer ; aucune connexion de test ne prouve à elle seule l’ouverture générale.

## Publication Netlify

`npm ci` installe les dépendances de vérification verrouillées. `npm run build` copie uniquement
les ressources publiques dans `dist/`. Netlify utilise Node 24 et cette commande via `netlify.toml`.
Les migrations, tests et adaptateurs de développement ne sont pas exposés comme fichiers du site.
Le client Supabase du nouvel écran est référencé à la version exacte 2.118.0.
