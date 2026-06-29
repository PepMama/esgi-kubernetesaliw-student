# TP DevOps — `SalleEnFrance`

> **Public** : Étudiants M2 ingénierie web / architecture logicielle
> **Prérequis** : Docker, Docker Compose, microservices, React, Next.js, SQL

## Vue d'ensemble

Migrer la plateforme fictive `SalleEnFrance` (réservation de salles multi-sites en France) depuis une stack `docker-compose` vers un **cluster Kubernetes 2 nœuds**. Mettre en place le **mTLS inter-services**, **Terraform** pour provisionner l'infra, et **GitHub Actions** pour la CI/CD. Tout tourne en local sauf la CI/CD.

## Documents fournis

| Fichier | Rôle |
|---|---|
| `POLYCOPIE.pdf` | Polycopié principal — objectifs, étapes, mTLS, CI/CD, cheatsheet kubectl, panorama K8s |
| `FREELENS.pdf` | Guide d'installation et de prise en main de Freelens |
| `README.md` | ce fichier — démarrage rapide |
| `Makefile` | Cibles utilitaires (`compose-up`, `kind-up`, `images`, `kind-load`, `deploy`, `test-e2e`, `pdf`) |
| `docker-compose.yml` | Architecture de **départ** à étudier puis migrer |

## Structure du dépôt

```
.
├── POLYCOPIE.pdf / .md        ← énoncé principal (à lire en premier)
├── FREELENS.pdf / .md         ← guide Freelens
├── README.md / Makefile
├── docker-compose.yml         ← état initial
├── apps/                      ← code des 5 services (à NE PAS modifier)
│   ├── frontend/              ← React + Vite (port 8080 dans le conteneur)
│   ├── auth-service/          ← Next.js (port 3001)
│   ├── sites-service/         ← Next.js (port 3002)
│   ├── rooms-service/         ← Next.js (port 3003)
│   └── bookings-service/      ← Next.js (port 3004)
├── docker/                    ← Dockerfiles (à compléter en étape 5)
├── k8s/
│   ├── base/                  ← manifests SCAFFOLDÉS avec # TODO à compléter
│   └── overlays/dev/          ← surcouche Kustomize (template)
├── terraform/                 ← scaffold Terraform (kind 2 nœuds, helm)
├── .github/workflows/         ← CI/CD GitHub Actions (à compléter)
├── seed/                      ← init.sql Postgres
└── scripts/                   ← config kind
```

## Démarrage rapide

```bash
# 1) Vivre l'application existante
make compose-up
make seed
# → http://localhost:5173

# 2) Construire le cluster cible
make kind-up               # Terraform : 2 nœuds + ingress + cert-manager
make images && make kind-load

# 3) Déployer (après avoir complété les YAML de k8s/base/)
make deploy

# 4) Vérifier
echo "127.0.0.1 salleenfrance.local" | sudo tee -a /etc/hosts
curl -H "Host: salleenfrance.local" http://localhost/api/sites
make test-e2e
```

## Critères de réussite

La liste complète est dans le polycopié (annexe B). Les axes principaux : cluster Terraform opérationnel, containerisation propre, manifests K8s cohérents, Postgres stateful + PVC, Ingress fonctionnel, mTLS inter-services avec cert-manager, CI/CD GitHub Actions, observabilité.

## Outillage requis

`docker`, `kubectl ≥ 1.30`, `kind ≥ 0.22`, `terraform ≥ 1.7`, `helm ≥ 3.14`, `freelens`, `cosign`, `trivy`, `stern`. Détails et liens d'installation dans `POLYCOPIE.pdf` § Étape 0.

## Aide

Le polycopié fixe les objectifs, les contraintes et les critères de validation — il ne donne pas la solution. Les YAML de `k8s/base/` ont des `# TODO` ciblés sur les points d'apprentissage.
