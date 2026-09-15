#!/bin/bash
set -Eeuo pipefail

K3S_KUBECONFIG="${K3S_KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
K3S_VERSION="${K3S_VERSION:-v1.36.1+k3s1}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-900s}"
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

rollout_or_die() {
    local namespace="$1"
    local resource="$2"

    if ! kubectl -n "$namespace" rollout status "$resource" --timeout="$ROLLOUT_TIMEOUT"; then
        echo "❌ Timed out waiting for $resource in namespace $namespace after $ROLLOUT_TIMEOUT."
        kubectl -n "$namespace" get pods -o wide || true
        kubectl -n "$namespace" get events --sort-by=.lastTimestamp | tail -n 40 || true
        exit 1
    fi
}

if command -v k3s &> /dev/null; then
    echo "⚠️ k3s is already installed. Skipping installation."
else
    echo "🚀 Installing k3s ${K3S_VERSION}..."
    install_args=(server --write-kubeconfig-mode 644)
    if [[ -n "${K3S_TLS_SAN:-}" ]]; then
        install_args+=(--tls-san "${K3S_TLS_SAN}")
    fi

    curl -sfL https://get.k3s.io | ${SUDO} INSTALL_K3S_VERSION="${K3S_VERSION}" sh -s - "${install_args[@]}"
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
traefik_ready="false"
for _ in $(seq 1 300); do
    if kubectl -n kube-system get deployment traefik >/dev/null 2>&1; then
        rollout_or_die kube-system deployment/traefik
        traefik_ready="true"
        break
    fi
    sleep 2
done

if [[ "$traefik_ready" != "true" ]]; then
    echo "❌ Timed out waiting for the Traefik deployment to appear."
    kubectl -n kube-system get deployments,jobs,pods -o wide || true
    kubectl -n kube-system get events --sort-by=.lastTimestamp | tail -n 40 || true
    exit 1
fi

echo "🔒 Installing Cert-Manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml

echo "⏳ Waiting for Cert-Manager webhook to be ready..."
rollout_or_die cert-manager deployment/cert-manager-webhook
