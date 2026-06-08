#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$BASE_DIR/.env"

if [[ -z "${KUBECONFIG:-}" && -f /etc/rancher/k3s/k3s.yaml ]]; then
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Missing .env file at $ENV_FILE"
  echo "   Run: cp .env.example .env"
  echo "   Then edit .env and run: make secrets"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

required_vars=(
  POSTGRES_PASSWORD
  MYSQL_ROOT_PASSWORD
  KEYCLOAK_DB_PASSWORD
  N8N_DB_PASSWORD
  GRAFANA_DB_PASSWORD
  KEYCLOAK_ADMIN_PASSWORD
  N8N_ENCRYPTION_KEY
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required variable '$var' is missing or empty in .env"
    exit 1
  fi
done

kubectl -n default create secret generic sandbox-secrets \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  --from-literal=KEYCLOAK_DB_PASSWORD="$KEYCLOAK_DB_PASSWORD" \
  --from-literal=N8N_DB_PASSWORD="$N8N_DB_PASSWORD" \
  --from-literal=GRAFANA_DB_PASSWORD="$GRAFANA_DB_PASSWORD" \
  --from-literal=KEYCLOAK_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" \
  --from-literal=N8N_ENCRYPTION_KEY="$N8N_ENCRYPTION_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ sandbox-secrets applied from local .env"
