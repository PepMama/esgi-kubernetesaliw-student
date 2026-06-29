# Historique — TP SalleEnFrance

## Etape 1 — Verification de l'outillage

Date: 2026-05-25

Objectif:
- Verifier que tous les outils requis par le TP sont installes et accessibles en CLI.

Actions realisees:
- Verification des versions de Docker, kubectl, kind, Terraform, Helm, Trivy, Cosign et Stern.
- Mise a jour du tableau des versions dans RAPPORT.md.

Resultat:
- Etape validee.
- Versions confirmees:
  - Docker: 29.4.1
  - kubectl: v1.34.1 (Kustomize v5.7.1)
  - kind: 0.22.0
  - Terraform: 1.15.4
  - Helm: 3.20.2
  - Trivy: 0.52.2
  - Cosign: 2.2.4
  - Stern: 1.33.1

Explication pedagogique:
- Cette etape garantit que l'environnement local est coherent avant toute manipulation Kubernetes/Terraform.
- Sans validation initiale, les erreurs suivantes peuvent venir de versions incompatibles et faire perdre du temps.

## Etape 2 — Analyse de la stack Docker Compose

Date: 2026-05-25

Objectif:
- Demarrer la stack existante, verifier son bon fonctionnement et produire la cartographie technique complete avant migration Kubernetes.

Actions realisees:
- Demarrage et verification d'etat via docker compose ps.
- Verification de la sante frontend et des 4 APIs via curl /healthz.
- Verification metier via curl /api/sites, /api/rooms, /api/bookings.
- Extraction de la configuration effective via docker compose config.
- Construction de la cartographie: images/build, ports, volumes, variables sensibles, dependances, flux reseau.

Resultat:
- Etape validee.
- 7 services demarres et healthy.
- Endpoints frontend et APIs operationnels.
- Flux applicatifs identifies.
- Cartographie ajoutee dans RAPPORT.md.

Explication pedagogique:
- Cette etape sert de baseline: on comprend exactement ce qui tourne avant de migrer vers Kubernetes.
- Le mapping compose -> Kubernetes sera plus fiable car fonde sur des preuves d'execution reelle et non uniquement sur la lecture des fichiers.
