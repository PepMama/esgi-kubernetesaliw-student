# RAPPORT — TP SalleEnFrance

### Versions des outils

| Outil | Version installée |
|---|---|
| Docker | Docker version 29.4.1, build 055a478 |
| kubectl | Client Version: v1.34.1 / Kustomize Version: v5.7.1 |
| kind | kind version 0.22.0 |
| Terraform | Terraform v1.15.4 |
| Helm | v3.20.2 |
| Trivy | 0.52.2 |
| Cosign | v2.2.4 |
| Stern | 1.33.1 |

## Etape 1 — Outillage

### Reponse attendue

L'environnement local est valide pour demarrer le TP.

### Explication

Toutes les versions requises sont installees et accessibles en ligne de commande. Cela garantit que les etapes suivantes (Terraform, kind, kubectl, scans) sont executables sans blocage de compatibilite.

### Ou trouver le resultat

- Commandes executees: docker version, kubectl version --client, kind --version, terraform -version, helm version, trivy --version, cosign version, stern --version.
- Preuve: tableau des versions ci-dessus.

## Etape 2 — Comprendre l'existant Docker Compose

### 2.1 Etat de la stack

### Reponse attendue

La stack Docker Compose demarre correctement et tous les conteneurs sont healthy.

### Explication

La commande docker compose ps montre 7 services actifs (postgres, redis, auth-service, sites-service, rooms-service, bookings-service, frontend) avec un statut Up (healthy).

### Ou trouver le resultat

- Commande: docker compose ps
- Preuve: statut Up (healthy) sur tous les services.

### 2.2 Validation fonctionnelle des endpoints

### Reponse attendue

Les endpoints de sante et metier repondent correctement.

### Explication

- Frontend: /healthz repond ok.
- APIs backend: /api/healthz repondent avec status ok.
- Endpoints metier verifies:
	- /api/sites retourne une liste de sites (source postgres).
	- /api/rooms?site_id=1 retourne des salles (source postgres).
	- /api/bookings retourne la liste des reservations (vide ici, source postgres).

### Ou trouver le resultat

- Commandes executees:
	- curl -s http://localhost:5173/healthz
	- curl -s http://localhost:3001/api/healthz
	- curl -s http://localhost:3002/api/healthz
	- curl -s http://localhost:3003/api/healthz
	- curl -s http://localhost:3004/api/healthz
	- curl -s http://localhost:3002/api/sites
	- curl -s "http://localhost:3003/api/rooms?site_id=1"
	- curl -s http://localhost:3004/api/bookings

## 2.3 Cartographie technique Docker Compose

| Conteneur | Image / Build | Ports publies | Ports internes | Volumes | Variables d'environnement | Variables sensibles | Dependances |
|---|---|---|---|---|---|---|---|
| postgres | postgres:16-alpine | Aucun | 5432 | volume nomme pgdata -> /var/lib/postgresql/data, bind mount ./seed/init.sql -> /docker-entrypoint-initdb.d/init.sql:ro | POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB | POSTGRES_PASSWORD | Aucune |
| redis | redis:7-alpine | Aucun | 6379 | Aucun | Aucune (configuration via command redis-server --maxmemory 128mb --maxmemory-policy allkeys-lru) | Aucune | Aucune |
| auth-service | Build apps/auth-service via docker/Dockerfile.next (SERVICE=auth-service) | 3001:3001 | 3001 | Aucun | NODE_ENV, PORT, DATABASE_URL, JWT_SECRET | DATABASE_URL, JWT_SECRET | postgres (service_healthy) |
| sites-service | Build apps/sites-service via docker/Dockerfile.next (SERVICE=sites-service) | 3002:3002 | 3002 | Aucun | NODE_ENV, PORT, DATABASE_URL | DATABASE_URL | postgres (service_healthy) |
| rooms-service | Build apps/rooms-service via docker/Dockerfile.next (SERVICE=rooms-service) | 3003:3003 | 3003 | Aucun | NODE_ENV, PORT, DATABASE_URL | DATABASE_URL | postgres (service_healthy) |
| bookings-service | Build apps/bookings-service via docker/Dockerfile.next (SERVICE=bookings-service) | 3004:3004 | 3004 | Aucun | NODE_ENV, PORT, DATABASE_URL, REDIS_URL | DATABASE_URL | postgres (service_healthy), redis (service_healthy) |
| frontend | Build apps/frontend via docker/Dockerfile.frontend | 5173:8080 | 8080 | Aucun | Aucune | Aucune | auth-service, sites-service, rooms-service, bookings-service (service_started) |

### 2.4 Flux reseau entre services

### Reponse attendue

Les flux applicatifs sont identifies et coherents avec l'architecture microservices.

### Explication

- frontend -> auth-service (authentification)
- frontend -> sites-service (liste des sites)
- frontend -> rooms-service (liste des salles)
- frontend -> bookings-service (reservations)
- auth-service -> postgres
- sites-service -> postgres
- rooms-service -> postgres
- bookings-service -> postgres
- bookings-service -> redis

### Ou trouver le resultat

- Source principale: docker compose config (variables, depends_on, ports)
- Source complementaire: tests curl metier realises.

### 2.5 Points d'attention (races au demarrage)

### Reponse attendue

Les risques de race sont identifies.

### Explication

- Le backend (auth/sites/rooms/bookings) depend de postgres en service_healthy: bon point.
- bookings-service depend aussi de redis en service_healthy: bon point.
- frontend depend des services backend en service_started et non service_healthy: un risque de race reste possible au tout premier demarrage (frontend en ligne avant disponibilite complete des APIs).

### Ou trouver le resultat

- Source: docker compose config, bloc depends_on.

