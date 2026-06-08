#!/bin/bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -z "${KUBECONFIG:-}" && -f /etc/rancher/k3s/k3s.yaml ]]; then
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
fi

if [[ -f "$BASE_DIR/config/runtime.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$BASE_DIR/config/runtime.env"
  set +a
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed. Please install it first."
    exit 1
fi

APP_DOMAIN=${APP_DOMAIN:-"127.0.0.1.nip.io"}
ARGOCD_HOST="argocd.${APP_DOMAIN}"
ARGOCD_VERSION=${ARGOCD_VERSION:-"v3.4.3"}

echo "🚀 Installing ArgoCD..."

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD standard manifests (using --server-side to avoid CRD size limit errors)
kubectl apply -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml" --server-side --force-conflicts

echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment argocd-server -n argocd --timeout=300s

echo "🔧 Patching ArgoCD server for insecure local ingress..."
# We configure argocd-server in insecure mode because Traefik will handle the SSL termination locally
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd --timeout=300s

echo "🌐 Creating ArgoCD Ingress (Traefik -> ${ARGOCD_HOST})..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "sandbox-issuer"
spec:
  tls:
  - hosts:
    - ${ARGOCD_HOST}
    secretName: argocd-server-tls
  rules:
  - host: ${ARGOCD_HOST}
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF

echo "✅ ArgoCD installation complete!"
