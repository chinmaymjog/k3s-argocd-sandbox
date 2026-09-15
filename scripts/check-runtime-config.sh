#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$BASE_DIR/.env"
RUNTIME_FILE="$BASE_DIR/config/runtime.env"
APPS_RUNTIME_FILE="$BASE_DIR/apps/runtime.env"
ARGOCD_RUNTIME_FILE="$BASE_DIR/argocd/runtime.env"
IMAGES_FILE="$BASE_DIR/config/images.env"
APPS_IMAGES_FILE="$BASE_DIR/apps/images.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Missing .env at $ENV_FILE"
  echo "   Run: cp .env.example .env"
  echo "   Then edit .env and run: make configure"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

required_vars=(
  APP_DOMAIN
  REPO_URL
  TARGET_REVISION
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required runtime variable '$var' is missing or empty in $ENV_FILE"
    exit 1
  fi
done

echo "ℹ️  Canonical user-editable file: $ENV_FILE"

if [[ "${SKIP_REPO_ACCESS_CHECK:-false}" != "true" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ git is required to validate REPO_URL access."
    echo "   Install git or rerun with SKIP_REPO_ACCESS_CHECK=true if you are managing ArgoCD repo credentials separately."
    exit 1
  fi

  if ! git ls-remote --exit-code "$REPO_URL" "$TARGET_REVISION" >/dev/null 2>&1; then
    echo "❌ REPO_URL/TARGET_REVISION is not reachable with the current git credentials."
    echo "   REPO_URL=$REPO_URL"
    echo "   TARGET_REVISION=$TARGET_REVISION"
    echo "   ArgoCD must also be able to fetch the same repo."
    echo "   Use a public fork, configure repo credentials, or rerun with SKIP_REPO_ACCESS_CHECK=true if this preflight is intentionally bypassed."
    exit 1
  fi
fi

required_images=(
  ADMINER_IMAGE
  GRAFANA_IMAGE
  KEYCLOAK_IMAGE
  MYSQL_IMAGE
  N8N_IMAGE
  PGSQL_IMAGE
  PHPMYADMIN_IMAGE
  PROMETHEUS_IMAGE
)

for var in "${required_images[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ Required image variable '$var' is missing or empty in $ENV_FILE"
    exit 1
  fi
done

GENERATED_FILES=("$RUNTIME_FILE" "$APPS_RUNTIME_FILE" "$ARGOCD_RUNTIME_FILE" "$IMAGES_FILE" "$APPS_IMAGES_FILE")

for mirror in "${GENERATED_FILES[@]}"; do
  if [[ ! -f "$mirror" ]]; then
    echo "❌ Missing generated config at $mirror"
    echo "   Run: make configure"
    exit 1
  fi
done

# ARGOCD_HOST and friends are derived from APP_DOMAIN and only ever written
# into the generated runtime mirror by configure-runtime.sh - they are not
# meant to be set in .env directly, so validate them there instead.
required_derived_vars=(
  ARGOCD_HOST
  ADMINER_HOST
  GRAFANA_HOST
  KEYCLOAK_HOST
  N8N_HOST
  N8N_WEBHOOK_URL
  PHPMYADMIN_HOST
  PROMETHEUS_HOST
)

(
  set -a
  # shellcheck disable=SC1090
  source "$RUNTIME_FILE"
  set +a
  for var in "${required_derived_vars[@]}"; do
    if [[ -z "${!var:-}" ]]; then
      echo "❌ Required derived variable '$var' is missing or empty in $RUNTIME_FILE"
      echo "   Run: make configure"
      exit 1
    fi
  done
)

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
