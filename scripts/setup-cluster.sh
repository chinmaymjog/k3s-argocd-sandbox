#!/bin/bash
set -e

CLUSTER_NAME="sandbox"

# Check if k3d is installed
if ! command -v k3d &> /dev/null; then
    echo "❌ Error: k3d is not installed. Please install it first (e.g., 'brew install k3d')."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not installed. Please install it first (e.g., 'brew install kubectl')."
    exit 1
fi

# Check if cluster already exists
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
    echo "⚠️ Cluster '$CLUSTER_NAME' already exists. Skipping creation."
else
    echo "🚀 Creating k3d cluster '$CLUSTER_NAME'..."
    # Map ports 80 and 443 to the host load balancer for ingress
    k3d cluster create "$CLUSTER_NAME" \
        --port "80:80@loadbalancer" \
        --port "443:443@loadbalancer"
    
    echo "✅ Cluster '$CLUSTER_NAME' created and ready!"
fi

# Wait for Traefik to be ready (k3s built-in)
echo "⏳ Waiting for built-in Traefik to initialize..."
kubectl -n kube-system rollout status deployment traefik || true

echo "🔒 Installing Cert-Manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

echo "⏳ Waiting for Cert-Manager webhook to be ready..."
kubectl rollout status deployment cert-manager-webhook -n cert-manager
