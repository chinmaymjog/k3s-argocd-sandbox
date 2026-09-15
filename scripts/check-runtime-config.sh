#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUNTIME_FILE="$BASE_DIR/config/runtime.env"
APPS_RUNTIME_FILE="$BASE_DIR/apps/runtime.env"
ARGOCD_RUNTIME_FILE="$BASE_DIR/argocd/runtime.env"
IMAGES_FILE="$BASE_DIR/config/images.env"
APPS_IMAGES_FILE="$BASE_DIR/apps/images.env"

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

if [[ ! -f "$IMAGES_FILE" ]]; then
  echo "❌ Missing image config at $IMAGES_FILE"
  exit 1
fi

if [[ ! -f "$APPS_IMAGES_FILE" ]]; then
  echo "❌ Missing Kustomize image config at $APPS_IMAGES_FILE"
  echo "   Run: make configure APP_DOMAIN=<domain> REPO_URL=<repo-url>"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$RUNTIME_FILE"
set +a

required_vars=(
  APP_DOMAIN
  REPO_URL
  TARGET_REVISION
  ARGOCD_HOST
  GRAFANA_HOST
  N8N_HOST
  N8N_WEBHOOK_URL
  PROMETHEUS_HOST
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required runtime variable '$var' is missing or empty in $RUNTIME_FILE"
    exit 1
  fi
done

set -a
# shellcheck disable=SC1090
source "$IMAGES_FILE"
set +a

required_images=(
  GRAFANA_IMAGE
  N8N_IMAGE
  PGSQL_IMAGE
  PROMETHEUS_IMAGE
)

for var in "${required_images[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required image variable '$var' is missing or empty in $IMAGES_FILE"
    exit 1
  fi
done

GENERATED_FILES=("$RUNTIME_FILE" "$APPS_RUNTIME_FILE" "$ARGOCD_RUNTIME_FILE" "$IMAGES_FILE" "$APPS_IMAGES_FILE")
if command -v git >/dev/null 2>&1 && git -C "$BASE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  UNCOMMITTED=$(git -C "$BASE_DIR" status --porcelain -- "${GENERATED_FILES[@]}" 2>/dev/null)
  if [[ -n "$UNCOMMITTED" ]]; then
    echo "⚠️  Generated runtime/image files differ from what's committed:"
    echo "$UNCOMMITTED" | sed 's/^/     /'
    echo "   ArgoCD syncs from Git, not your local filesystem - it will keep"
    echo "   using the committed values (not what 'make configure' just wrote"
    echo "   locally) until you commit and push these files. This is the"
    echo "   #1 cause of 'ArgoCD says Synced but the Ingress host/image is"
    echo "   wrong' - commit and push before running 'make bootstrap' or"
    echo "   'make sync' with a non-default APP_DOMAIN, REPO_URL, or image pin."
  fi
fi

echo "✅ Runtime and image config are valid"
