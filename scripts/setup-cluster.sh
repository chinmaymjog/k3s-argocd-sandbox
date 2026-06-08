#!/bin/bash
set -Eeuo pipefail

K3S_KUBECONFIG="${K3S_KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
SUDO=""

if [[ "${EUID}" -ne 0 ]]; then
    SUDO="sudo"
fi

if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is not installed. Please install it first."
    exit 1
fi

if ! command -v systemctl &> /dev/null; then
    echo "❌ Error: systemctl is required to manage the k3s service."
    exit 1
fi

if command -v k3s &> /dev/null; then
    echo "⚠️ k3s is already installed. Skipping installation."
else
    echo "🚀 Installing k3s..."
    install_args=(server --write-kubeconfig-mode 644)
    if [[ -n "${K3S_TLS_SAN:-}" ]]; then
        install_args+=(--tls-san "${K3S_TLS_SAN}")
    fi

    curl -sfL https://get.k3s.io | ${SUDO} sh -s - "${install_args[@]}"
    echo "✅ k3s installed."
fi

if [[ -f "${K3S_KUBECONFIG}" && -z "${KUBECONFIG:-}" ]]; then
    export KUBECONFIG="${K3S_KUBECONFIG}"
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ Error: kubectl is not available after k3s installation."
    exit 1
fi

echo "⏳ Ensuring k3s is running..."
${SUDO} systemctl enable --now k3s

echo "⏳ Waiting for built-in Traefik to initialize..."
for _ in $(seq 1 60); do
    if kubectl -n kube-system get deployment traefik >/dev/null 2>&1; then
        kubectl -n kube-system rollout status deployment traefik --timeout=300s
        break
    fi
    sleep 2
done

echo "🔒 Installing Cert-Manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

echo "⏳ Waiting for Cert-Manager webhook to be ready..."
kubectl rollout status deployment cert-manager-webhook -n cert-manager --timeout=300s
