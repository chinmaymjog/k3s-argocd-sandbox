#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_FILE="$BASE_DIR/config/runtime.env"
APPS_RUNTIME_FILE="$BASE_DIR/apps/runtime.env"
ARGOCD_RUNTIME_FILE="$BASE_DIR/argocd/runtime.env"

if [[ ! -f "$RUNTIME_FILE" ]]; then
  echo "❌ Missing runtime config at $RUNTIME_FILE"
  echo "   Run: make configure APP_DOMAIN=<domain> REPO_URL=<repo-url>"
  exit 1
fi

for mirror in "$APPS_RUNTIME_FILE" "$ARGOCD_RUNTIME_FILE"; do
  if [[ ! -f "$mirror" ]]; then
    echo "❌ Missing Kustomize runtime config at $mirror"
    echo "   Run: make configure APP_DOMAIN=<domain> REPO_URL=<repo-url>"
    exit 1
  fi
done

set -a
# shellcheck disable=SC1090
source "$RUNTIME_FILE"
set +a

required_vars=(
  APP_DOMAIN
  REPO_URL
  TARGET_REVISION
  ARGOCD_HOST
  ADMINER_HOST
  GRAFANA_HOST
  KEYCLOAK_HOST
  N8N_HOST
  N8N_WEBHOOK_URL
  PHPMYADMIN_HOST
  PROMETHEUS_HOST
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required runtime variable '$var' is missing or empty in $RUNTIME_FILE"
    exit 1
  fi
done

echo "✅ Runtime config is valid"
