.PHONY: help configure check-config setup up bootstrap sync down status secrets password

ifneq (,$(wildcard .env))
include .env
export
endif

KUBECONFIG ?= /etc/rancher/k3s/k3s.yaml
APP_DOMAIN ?= 127.0.0.1.nip.io
REPO_URL ?= https://github.com/chinmaymjog/k3s-argocd-sandbox.git
TARGET_REVISION ?= main
K3S_VERSION ?= v1.36.1+k3s1
ADMINER_IMAGE ?= adminer:5.4.2
GRAFANA_IMAGE ?= grafana/grafana-oss:13.0.1
KEYCLOAK_IMAGE ?= quay.io/keycloak/keycloak:24.0.0
MYSQL_IMAGE ?= mysql:8.0
N8N_IMAGE ?= docker.n8n.io/n8nio/n8n:2.18.7
PGSQL_IMAGE ?= postgres:15
PHPMYADMIN_IMAGE ?= phpmyadmin:5.2.3
PROMETHEUS_IMAGE ?= prom/prometheus:v3.11.3
ROLLOUT_TIMEOUT ?= 900s
SKIP_REPO_ACCESS_CHECK ?= false
export KUBECONFIG
export APP_DOMAIN
export REPO_URL
export TARGET_REVISION
export K3S_VERSION
export ADMINER_IMAGE
export GRAFANA_IMAGE
export KEYCLOAK_IMAGE
export MYSQL_IMAGE
export N8N_IMAGE
export PGSQL_IMAGE
export PHPMYADMIN_IMAGE
export PROMETHEUS_IMAGE
export ROLLOUT_TIMEOUT
export SKIP_REPO_ACCESS_CHECK

help:
	@echo "K3s ArgoCD Sandbox - Management Commands"
	@echo "================================================"
	@echo "configure - Write canonical config files and regenerate Kustomize mirrors"
	@echo "check-config - Validate canonical runtime/image config plus derived mirrors"
	@echo "up       - Install or reuse k3s and install ArgoCD"
	@echo "bootstrap - Configure cluster, secrets, and ArgoCD app-of-apps"
	@echo "sync     - Apply the ArgoCD bootstrap application"
	@echo "secrets  - Apply sandbox-secrets from local .env"
	@echo "down     - Uninstall k3s from this host (set CONFIRM_K3S_UNINSTALL=true)"
	@echo "status   - Show status of the cluster and ArgoCD pods"
	@echo "password - Retrieve the initial ArgoCD admin password"
	@echo "Variables: K3S_VERSION=$(K3S_VERSION) APP_DOMAIN=$(APP_DOMAIN) TARGET_REVISION=$(TARGET_REVISION) ROLLOUT_TIMEOUT=$(ROLLOUT_TIMEOUT)"

configure:
	@bash scripts/configure-runtime.sh

check-config:
	@bash scripts/check-runtime-config.sh

up: check-config
	@bash scripts/setup-cluster.sh
	@bash scripts/install-argocd.sh
	@echo "================================================"
	@echo "🚀 Sandbox is up!"
	@bash -lc 'source .env && echo "🌐 ArgoCD UI: http://$$ARGOCD_HOST"'
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
