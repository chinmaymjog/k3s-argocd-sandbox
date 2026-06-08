.PHONY: help configure check-config setup up bootstrap sync down status secrets password

KUBECONFIG ?= /etc/rancher/k3s/k3s.yaml
APP_DOMAIN ?= 127.0.0.1.nip.io
REPO_URL ?= https://github.com/chinmayjog/k3s-argocd-sandbox.git
TARGET_REVISION ?= main
export KUBECONFIG
export APP_DOMAIN
export REPO_URL
export TARGET_REVISION

help:
	@echo "K3s ArgoCD Sandbox - Management Commands"
	@echo "================================================"
	@echo "configure - Write config/runtime.env from APP_DOMAIN/REPO_URL/TARGET_REVISION"
	@echo "check-config - Validate config/runtime.env"
	@echo "up       - Install or reuse k3s and install ArgoCD"
	@echo "bootstrap - Configure cluster, secrets, and ArgoCD app-of-apps"
	@echo "sync     - Apply the ArgoCD bootstrap application"
	@echo "secrets  - Apply sandbox-secrets from local .env"
	@echo "down     - Uninstall k3s from this host (set CONFIRM_K3S_UNINSTALL=true)"
	@echo "status   - Show status of the cluster and ArgoCD pods"
	@echo "password - Retrieve the initial ArgoCD admin password"

configure:
	@bash scripts/configure-runtime.sh

check-config:
	@bash scripts/check-runtime-config.sh

up: check-config
	@bash scripts/setup-cluster.sh
	@bash scripts/install-argocd.sh
	@echo "================================================"
	@echo "🚀 Sandbox is up!"
	@bash -lc 'source config/runtime.env && echo "🌐 ArgoCD UI: http://$$ARGOCD_HOST"'
	@echo "🔑 Run 'make password' to get your login credentials."
	@echo "🔐 Run 'make bootstrap' after editing .env to complete app sync."

bootstrap: check-config up secrets sync
	@echo "✅ Bootstrap applied. Use 'make status' to watch workloads converge."

sync: check-config
	@kubectl apply -k argocd

secrets:
	@bash scripts/apply-secrets.sh

down:
	@if [ "$(CONFIRM_K3S_UNINSTALL)" != "true" ]; then \
		echo "❌ Refusing to uninstall k3s without CONFIRM_K3S_UNINSTALL=true"; \
		exit 1; \
	fi
	@echo "🛑 Uninstalling k3s..."
	@sudo /usr/local/bin/k3s-uninstall.sh
	@echo "✅ k3s removed."

status:
	@echo "📦 Cluster Nodes:"
	@kubectl get nodes
	@echo "\n🚢 ArgoCD Pods:"
	@kubectl get pods -n argocd
	@echo "\n🚀 App Pods (Default Namespace):"
	@kubectl get pods -n default

password:
	@echo "🔑 ArgoCD Admin Password (Username: admin):"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""
