#!/usr/bin/env bash
# =============================================================================
# Tests de validation end-to-end du déploiement.
# Lance une suite de vérifications et compte les succès / échecs.
#
# Usage : bash scripts/test-e2e.sh
# =============================================================================
set -uo pipefail

NS=${NS:-salleenfrance}
HOST=${HOST:-salleenfrance.local}
BASE_URL=${BASE_URL:-http://localhost}

PASS=0
FAIL=0

ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; PASS=$((PASS+1)); }
ko()   { printf "  \033[31m✗\033[0m %s\n" "$1"; FAIL=$((FAIL+1)); }
title(){ printf "\n\033[1m▼ %s\033[0m\n" "$1"; }

trap 'echo; printf "\033[1mRésultat : %d réussis, %d échoués\033[0m\n" "$PASS" "$FAIL"; exit $FAIL' EXIT

# 1) Cluster
title "Cluster"
nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
[[ "$nodes" -ge 2 ]] && ok "$nodes nœuds dans le cluster" || ko "moins de 2 nœuds"

ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c ' Ready ')
[[ "$ready" -ge 2 ]] && ok "$ready nœuds Ready" || ko "des nœuds NotReady"

# 2) Namespace + ressources
title "Namespace $NS"
kubectl get ns "$NS" >/dev/null 2>&1 && ok "namespace $NS existe" || { ko "namespace absent"; exit 1; }

# 3) Pods
title "Pods Running et Ready"
for label in postgres redis auth-service sites-service rooms-service bookings-service frontend; do
  count=$(kubectl get pods -n "$NS" -l app.kubernetes.io/name="$label" -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}' 2>/dev/null | grep -c Running)
  if [[ "$count" -gt 0 ]]; then
    ok "$label : $count pod(s) Running"
  else
    ko "$label : aucun pod Running"
  fi
done

# 4) Services
title "Services et endpoints"
for svc in postgres redis auth-service sites-service rooms-service bookings-service frontend; do
  ep=$(kubectl get endpoints "$svc" -n "$NS" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null | wc -w | tr -d ' ')
  [[ "$ep" -gt 0 ]] && ok "$svc : $ep endpoint(s)" || ko "$svc : aucun endpoint"
done

# 5) PVC
title "Stockage Postgres"
status=$(kubectl get pvc -n "$NS" -l app.kubernetes.io/name=postgres -o jsonpath='{.items[0].status.phase}' 2>/dev/null \
  || kubectl get pvc -n "$NS" data-postgres-0 -o jsonpath='{.status.phase}' 2>/dev/null)
[[ "$status" == "Bound" ]] && ok "PVC Postgres Bound" || ko "PVC Postgres non Bound (status=$status)"

# 6) Connectivité Postgres / Redis
title "Connectivité interne"
kubectl exec -n "$NS" postgres-0 -- pg_isready -U salleenfrance >/dev/null 2>&1 \
  && ok "Postgres pg_isready" || ko "Postgres pg_isready"

kubectl exec -n "$NS" deploy/redis -- redis-cli PING 2>/dev/null | grep -q PONG \
  && ok "Redis PING/PONG" || ko "Redis PING"

# 7) Routes Ingress
title "Routes Ingress (host: $HOST)"
for path in / /api/sites /api/rooms /api/bookings; do
  code=$(curl -sS -o /dev/null -H "Host: $HOST" -w "%{http_code}" "${BASE_URL}${path}" 2>/dev/null)
  [[ "$code" =~ ^2|3 ]] && ok "GET $path → $code" || ko "GET $path → $code"
done

# 8) POST auth/login
code=$(curl -sS -o /dev/null -w "%{http_code}" -H "Host: $HOST" -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}' "${BASE_URL}/api/auth/login" 2>/dev/null)
[[ "$code" == "200" ]] && ok "POST /api/auth/login → 200" || ko "POST /api/auth/login → $code"

# 9) Cache Redis (2 appels)
title "Cache Redis"
curl -sS -H "Host: $HOST" -o /dev/null "${BASE_URL}/api/bookings" 2>/dev/null
src=$(curl -sS -H "Host: $HOST" "${BASE_URL}/api/bookings" 2>/dev/null | grep -oE '"source":"[^"]+"' | head -1)
[[ "$src" == '"source":"redis"' ]] && ok "/api/bookings sert depuis Redis au 2ème appel" \
  || ko "/api/bookings ne semble pas mis en cache (source=$src)"

# 10) cert-manager (étape 11)
title "PKI mTLS (étape 11)"
if kubectl get crd certificates.cert-manager.io >/dev/null 2>&1; then
  count=$(kubectl get certificates -n "$NS" --no-headers 2>/dev/null | grep -c " True ")
  [[ "$count" -ge 5 ]] && ok "$count Certificates Ready" || ko "Certificates Ready : $count (attendu ≥ 5)"
else
  ko "cert-manager non installé (CRD certificates.cert-manager.io absente)"
fi
