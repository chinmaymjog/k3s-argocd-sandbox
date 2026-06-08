#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_FILE="$BASE_DIR/config/runtime.env"
APPS_RUNTIME_FILE="$BASE_DIR/apps/runtime.env"
ARGOCD_RUNTIME_FILE="$BASE_DIR/argocd/runtime.env"

current_value() {
  local key="$1"
  if [[ -f "$RUNTIME_FILE" ]]; then
    awk -F= -v key="$key" '$1 == key {print substr($0, index($0, "=") + 1)}' "$RUNTIME_FILE" | tail -n 1
  fi
}

APP_DOMAIN="${APP_DOMAIN:-$(current_value APP_DOMAIN)}"
REPO_URL="${REPO_URL:-$(current_value REPO_URL)}"
TARGET_REVISION="${TARGET_REVISION:-$(current_value TARGET_REVISION)}"

APP_DOMAIN="${APP_DOMAIN:-127.0.0.1.nip.io}"
REPO_URL="${REPO_URL:-https://github.com/chinmaymjog/k3s-argocd-sandbox.git}"
TARGET_REVISION="${TARGET_REVISION:-main}"

write_runtime_file() {
  local target="$1"
  cat > "$target" <<EOF
APP_DOMAIN=$APP_DOMAIN
REPO_URL=$REPO_URL
TARGET_REVISION=$TARGET_REVISION
ARGOCD_HOST=argocd.$APP_DOMAIN
ADMINER_HOST=adminer.$APP_DOMAIN
GRAFANA_HOST=grafana.$APP_DOMAIN
KEYCLOAK_HOST=keycloak.$APP_DOMAIN
N8N_HOST=n8n.$APP_DOMAIN
N8N_WEBHOOK_URL=https://n8n.$APP_DOMAIN/
PHPMYADMIN_HOST=phpmyadmin.$APP_DOMAIN
PROMETHEUS_HOST=prometheus.$APP_DOMAIN
EOF
}

write_runtime_file "$RUNTIME_FILE"
write_runtime_file "$APPS_RUNTIME_FILE"
write_runtime_file "$ARGOCD_RUNTIME_FILE"

echo "✅ Wrote runtime config to $RUNTIME_FILE"
echo "✅ Synced Kustomize runtime config to $APPS_RUNTIME_FILE and $ARGOCD_RUNTIME_FILE"
