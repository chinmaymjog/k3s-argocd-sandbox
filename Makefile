.PHONY: help setup up down status secrets password

CLUSTER_NAME ?= sandbox

help:
	@echo "K3s ArgoCD Sandbox - Management Commands"
	@echo "================================================"
	@echo "up       - Create k3d cluster and install ArgoCD"
	@echo "secrets  - Apply sandbox-secrets from local .env"
	@echo "down     - Stop and delete the k3d cluster"
	@echo "status   - Show status of the cluster and ArgoCD pods"
	@echo "password - Retrieve the initial ArgoCD admin password"

up:
	@bash scripts/setup-cluster.sh
	@bash scripts/install-argocd.sh
	@echo "================================================"
	@echo "🚀 Sandbox is up!"
	@echo "🌐 ArgoCD UI: http://argocd.127.0.0.1.nip.io"
	@echo "🔑 Run 'make password' to get your login credentials."
	@echo "🔐 Run 'make secrets' to apply secrets from local .env before bootstrap."

secrets:
	@bash scripts/apply-secrets.sh

down:
	@echo "🛑 Deleting k3d cluster '$(CLUSTER_NAME)'..."
	@k3d cluster delete $(CLUSTER_NAME)
	@echo "✅ Cluster deleted."

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
