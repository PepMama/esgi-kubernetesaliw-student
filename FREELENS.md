---
title: "Freelens — Guide d'installation et de prise en main"
subtitle: "TP `SalleEnFrance` — Cluster Kubernetes 2 nœuds"
author: "Cours d'architecture logicielle & déploiement — M2 Ingénierie Web"
date: "2025--2026"
toc: true
toc-depth: 2
numbersections: true
papersize: a4
geometry: margin=2.2cm
mainfont: "Helvetica"
monofont: "Menlo"
fontsize: 10pt
lang: fr
header-includes: |
  ```{=typst}
  #show raw: set text(size: 8.5pt)
  #show raw.where(block: true): block.with(
    width: 100%,
    fill: rgb(248, 248, 248),
    inset: (x: 0.8em, y: 0.6em),
    radius: 3pt,
    stroke: rgb(225, 225, 225)
  )
  #show table.cell: set text(size: 8pt)
  #show table: set table(stroke: 0.4pt + rgb(220, 220, 220))
  ```
---


# Pourquoi Freelens dans ce TP

Vous allez opérer un cluster Kubernetes : créer des ressources, observer leur état, lire des logs, débugger des erreurs de configuration. La CLI `kubectl` est nécessaire — vous l'utiliserez tous les jours — mais elle n'est pas suffisante pour comprendre rapidement la topologie d'un cluster, repérer un pod en `CrashLoopBackOff` parmi cinquante, ou lire un événement enterré 200 lignes plus bas.

Freelens est un IDE de bureau (Mac / Linux / Windows) qui rend cette information immédiatement lisible. C'est un fork open-source de Lens, repris par la communauté quand Mirantis a basculé Lens en source-disponible. Freelens reste gratuit, sans compte, sans télémétrie.

> Dans ce TP, Freelens est obligatoire : chaque étape du polycopié comporte une checklist de validation visuelle dans Freelens.


# Installation

## macOS (Apple Silicon ou Intel)

Option 1 — Homebrew (recommandée) :

```bash
brew install --cask freelens
```

Option 2 — Téléchargement direct :

1. Aller sur [https://freelens.app](https://freelens.app).
2. Télécharger le `.dmg` correspondant à votre architecture (`-arm64.dmg` pour Apple Silicon, `-x64.dmg` pour Intel).
3. Ouvrir le `.dmg`, glisser Freelens.app dans `/Applications`.
4. Au premier lancement, autoriser via *Préférences Système → Sécurité* (Apple Gatekeeper).

## Windows 10 / 11

Option 1 — Winget :

```powershell
winget install Freelens.Freelens
```

Option 2 — Installeur :

1. Télécharger l'installeur `.exe` depuis [https://freelens.app](https://freelens.app).
2. Exécuter en double-clic. Pas de droits admin requis.

## Linux (Ubuntu / Debian / Fedora)

Option 1 — Paquet : télécharger le `.deb` (Debian/Ubuntu) ou `.rpm` (Fedora) depuis [https://freelens.app](https://freelens.app).

```bash
# Debian / Ubuntu
sudo apt install ./Freelens-*.deb

# Fedora
sudo dnf install ./Freelens-*.rpm
```

Option 2 — AppImage :

```bash
chmod +x Freelens-*.AppImage
./Freelens-*.AppImage
```


# Première connexion au cluster

## Récupérer un kubeconfig valide

Vérifiez que votre `kubectl` peut joindre le cluster :

```bash
kubectl cluster-info
kubectl get nodes
```

Si la commande répond, votre fichier `~/.kube/config` est correct. Sur macOS et Linux il est en `~/.kube/config` ; sur Windows il est en `%USERPROFILE%\.kube\config`.

## Ajouter le cluster dans Freelens

1. Ouvrir Freelens.
2. Au premier lancement, l'écran Welcome propose `Add a cluster`. Cliquer.
3. Choisir Sync local kubeconfig.
4. Pointer sur le fichier `~/.kube/config`.
5. Le cluster `kind-salleenfrance` (ou le nom que vous lui avez donné) apparaît dans la liste de gauche.

> Si vous gérez plusieurs clusters, Freelens affichera tous les contextes du fichier kubeconfig. Vous pourrez basculer entre eux via la catalog view (`⌘ ;` sur macOS, `Ctrl ;` sur Linux/Windows).

## Vérification

Cliquer sur le cluster. Vous devez voir :

- en haut à gauche, le nom du cluster et la version K8s ;
- à gauche, le menu de navigation (Nodes, Workloads, Network, Storage, Config…) ;
- au centre, un *dashboard* avec utilisation CPU/RAM par nœud.

> Validation. la vue *Nodes* affiche 2 nœuds `Ready`, un `control-plane` et un `worker`.


# Tour du propriétaire

## Vue *Workloads → Pods*

C'est l'écran que vous utiliserez le plus.

- En haut : barre de recherche, filtres par namespace, par status.
- Tableau central : liste des pods (Name, Namespace, Containers, Status, Restarts, Age).
- Sélectionner un pod → panneau latéral à droite avec :
  - Overview : labels, annotations, IP, nœud d'exécution ;
  - Logs (icône terminal) : tail en temps réel ;
  - Pod shell (icône `>_`) : ouvre un shell interactif (équivalent `kubectl exec -it`) ;
  - Events : timeline des événements cluster liés au pod ;
  - Edit : modifier le YAML directement.

## Vue *Workloads → Deployments*

Lecture rapide du nombre de répliques `Ready / Desired`. Cliquer pour voir l'historique des `ReplicaSets` : utile pour comprendre un rollout.

## Vue *Network → Services* et *Network → Ingresses*

- Services : type, IP virtuelle, sélecteur, ports.
- Ingresses : hosts, paths, backends. La résolution des backends est indiquée par une icône verte (✓ résolu) ou rouge (✗ pas de pod backend).

## Vue *Storage → Persistent Volume Claims*

Le statut `Bound` doit être votre référence. `Pending` = problème (StorageClass absente, taille demandée trop grande, etc.).

## Vue *Config → ConfigMaps* et *Config → Secrets*

- ConfigMaps : valeurs en clair.
- Secrets : valeurs masquées par défaut (œil pour révéler). Attention à qui regarde par-dessus votre épaule.

## Vue *Custom Resources*

C'est ici que vous trouverez les `Certificate`, `Issuer`, `ClusterIssuer` posés par cert-manager (étape 11 du TP), ainsi que toute autre CRD installée.


# Astuces utiles

## Raccourcis clavier (macOS, équivalent Ctrl sur Linux/Windows)

| Raccourci | Action |
|---|---|
| `⌘ K` | Recherche universelle (objets, vues) |
| `⌘ ;` | Catalogue (changer de cluster) |
| `⌘ R` | Forcer le refresh |
| `⌘ ⇧ T` | Ouvrir un terminal global (kubectl) |
| `⌘ ⇧ L` | Logs du pod sélectionné |

## Filtrer par label

Dans la barre de recherche d'une vue, taper :

```
app.kubernetes.io/name=auth-service
```

→ ne montre que les ressources matchant.

## Prendre une capture d'écran propre

- Sur macOS : `⌘ ⇧ 4` puis espace pour capturer une fenêtre proprement.
- Toujours masquer les valeurs sensibles dans les Secrets avant de partager une capture.

## Détecter les pods en erreur en un coup d'œil

La vue *Workloads → Pods* trie automatiquement par status. Les pods en `Error`, `CrashLoopBackOff` ou `Pending` apparaissent en haut, en rouge.

## Lire un événement
Vue *Events* (menu de gauche). Filtrer par `Type: Warning` pour voir uniquement ce qui ne va pas. Utiliser `--sort-by=.lastTimestamp` mentalement : Freelens trie déjà chronologiquement.


# Dépannage

## *Le cluster apparaît grisé / non joignable*

- Vérifier dans un terminal que `kubectl get nodes` répond.
- Si oui, dans Freelens cliquer-droit sur le cluster → Disconnect puis re-cliquer pour reconnecter.
- Si le kubeconfig a été régénéré (par exemple après un `terraform destroy && terraform apply`), il peut être nécessaire de ré-importer le fichier (Welcome → Add a cluster).

## *Erreur « unable to connect to the server: x509 »*

Le certificat du cluster a tourné. Refaire :

```bash
kubectl config view --raw > ~/.kube/config_new
```

et ré-importer dans Freelens.

## *Les logs ne s'affichent pas*

- Vérifier que le pod n'est pas terminé depuis longtemps (`Status: Completed` → pas de logs en *follow*).
- Tester `kubectl logs <pod>` depuis un terminal pour confirmer.
- Forcer le refresh (`⌘ R`).

## *Le shell du pod ne s'ouvre pas*

- Le conteneur doit avoir un shell installé. `distroless` n'en a pas — vous ne pourrez pas ouvrir de shell.
- Lancer un pod éphémère avec un shell :

```bash
kubectl run debug --rm -it --image=nicolaka/netshoot -n salleenfrance -- bash
```


# À éviter

- Ne pas appliquer de YAML depuis Freelens en TP. C'est tentant — il y a un bouton *Edit* et un bouton *Apply*. Restez sur `kubectl apply -f` ou la CI : c'est ce qui sera audité par l'enseignant et c'est ce qui se fait en production. Freelens reste un outil de lecture et de debug.
- Ne pas supprimer un pod en production d'un clic dans Freelens. Sur un cluster partagé, on s'engage par PR + revue, pas par geste impulsif. Pour le TP, vous le ferez de toute façon via `kubectl delete pod` (étape 13) — restez cohérent.
- Ne pas committer vos captures d'écran de Secrets dans le rapport. Floutez ou supprimez les valeurs.
- Ne pas confondre Lens et Freelens. Si l'enseignant vous demande Freelens, n'arrivez pas avec Lens (qui partage des données et requiert un compte).

\vspace{2cm}

\begin{center}
\textit{Bon debug. — L'équipe enseignante.}
\end{center}
