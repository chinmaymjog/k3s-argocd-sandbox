# ☁️ K3s-ArgoCD Sandbox
## A Production-Grade Local Cloud Architecture on Kubernetes

A modular, automated infrastructure sandbox for testing cloud-native stacks, observability, and automation tools on your laptop or a remote VM using K3s and ArgoCD.

> [!TIP]
> This lab mimics a production cloud environment with modular stacks and unified ingress.

## 🏗️ Architecture: The "GitOps Cloud" Design

Like cloudops-sandbox, this project keeps ingress, control-plane logic, and modular application stacks. The runtime model shifts from Docker Compose to Kubernetes manifests synced by ArgoCD.

```mermaid
graph TD
	User([User]) -->|HTTPS / *.nip.io| Traefik[K3s Traefik Ingress Gateway]

	subgraph "Control Plane Network"
		Traefik
		ArgoCD[ArgoCD GitOps Engine]
		DNS[nip.io / optional DNS]
	end

	subgraph "Modular Stacks"
		App1[Keycloak Stack]
		App2[n8n Stack]
		App3[Monitoring Stack]
	end

	subgraph "Persistence Layer"
		DB[(PostgreSQL / MySQL)]
		Vol[(Kubernetes PVCs)]
	end

	ArgoCD --> App1
	ArgoCD --> App2
	ArgoCD --> App3

	Traefik --> App1
	Traefik --> App2
	Traefik --> App3

	App1 --> DB
	App2 --> DB

	DB --> Vol
```

## 🚀 Overview

This lab provides a "Sandboxed" environment that mimics a production cloud setup. It allows rapid deployment of stateful tools and management stacks using K3s, Traefik, and ArgoCD as the GitOps control plane.

## System Docs (Engineering Workflow)

- Project specification: docs/project-spec.md
- Architecture decisions: docs/architecture.md
- Execution tracker: docs/tasks.md

---

## 📋 Prerequisites

### System Requirements
*   **Operating System**: Linux host or Linux VM with `systemd` and `sudo`.
*   **Tools**: `curl`, `kubectl`, `make`.
*   **Ports**: `80` and `443` available on the host for Traefik ingress.
*   **Tested K3s version**: `v1.36.1+k3s1`

Install example (Debian/Ubuntu):

```bash
sudo apt-get update
sudo apt-get install -y curl make
```

---

## 🏗️ Stack Catalog

The lab is organized into modular stacks:

| Category | Tools | Description |
| :--- | :--- | :--- |
| **GitOps Engine** | ArgoCD | Continuous delivery and sync agent |
| **Edge & Proxy** | Traefik | Built-in K3s ingress controller |
| **SSL/TLS** | Cert-Manager | Automated certificate provisioning |
| **Observability** | Prometheus, Grafana | Metrics and Dashboards |
| **Automation** | n8n | Low-code workflow automation |
| **Databases** | PostgreSQL, MySQL | Stateful data persistence via PVCs |
| **Identity** | Keycloak | Identity and Access Management (OIDC/SAML) |
| **Management** | Adminer, phpMyAdmin | Database management UIs |

---

## 🛠️ Quick Start

### 1. Fork & Clone
ArgoCD should sync from your fork:

```bash
git clone https://github.com/YOUR_USERNAME/k3s-argocd-sandbox.git
cd k3s-argocd-sandbox
```

Initialize local secret file:

```bash
cp .env.example .env
```

Edit `.env` with your own secret values.

### 2. Write Runtime Config

Generate the tracked runtime config once for your environment:

```bash
make configure APP_DOMAIN=127.0.0.1.nip.io REPO_URL=https://github.com/YOUR_USERNAME/k3s-argocd-sandbox.git
```

This writes `config/runtime.env`, then syncs the Kustomize runtime files under `apps/` and `argocd/`.
Commit all three runtime files so ArgoCD reconciles the same domain and repo settings you bootstrapped with.

Image versions are managed separately in `config/images.env`.
`make configure` also syncs that file into `apps/images.env`, which Kustomize uses to inject pinned image references into every deployment.

### 3. Choose Setup Mode

#### Mode A (Recommended): Local Laptop with nip.io
Recommended configure command:

```bash
make configure APP_DOMAIN=127.0.0.1.nip.io REPO_URL=https://github.com/YOUR_USERNAME/k3s-argocd-sandbox.git
```

Expected access examples:
- `http://argocd.127.0.0.1.nip.io`
- `https://grafana.127.0.0.1.nip.io`
- `https://keycloak.127.0.0.1.nip.io`
- `https://n8n.127.0.0.1.nip.io`

Note: nip.io mode uses sandbox certificates, so browser certificate warnings are expected.

#### Mode B: Remote VM with nip.io
Recommended configure command:

```bash
make configure APP_DOMAIN=<VM_PUBLIC_IP>.nip.io REPO_URL=https://github.com/YOUR_USERNAME/k3s-argocd-sandbox.git
```

VM preflight:
1. Open inbound ports `80` and `443` on the VM firewall/security group.
2. Ensure ports `80` and `443` are available on the VM host.

Expected access examples:
- `http://argocd.<VM_PUBLIC_IP>.nip.io`
- `https://grafana.<VM_PUBLIC_IP>.nip.io`
- `https://keycloak.<VM_PUBLIC_IP>.nip.io`
- `https://n8n.<VM_PUBLIC_IP>.nip.io`

#### Mode C (Optional Advanced): Public Domain
Use this mode only if you want a custom DNS domain.

Recommended configure command:

```bash
make configure APP_DOMAIN=lab.yourdomain.com REPO_URL=https://github.com/YOUR_USERNAME/k3s-argocd-sandbox.git
```

### 4. Setup Infrastructure
Install or reuse K3s on the host, apply local secrets, and bootstrap ArgoCD:

```bash
make bootstrap
```

To override the pinned K3s release for a test run:

```bash
make bootstrap K3S_VERSION=v1.35.5+k3s1
```

This performs:
- `make up`
- `make secrets`
- `make sync`

Before upgrades, update the pinned image references in `config/images.env`, run `make configure`, and commit both `config/images.env` and `apps/images.env`.

### 5. Retrieve Credentials
Get the default ArgoCD admin password:

```bash
make password
```

Login username is `admin`.

### 6. Verify Health

```bash
make status
kubectl get ingress -A
kubectl get application sandbox-apps -n argocd
```

### 7. First Login (Recommended)
Start with ArgoCD dashboard:
- `http://argocd.<your-domain>`

Then verify core apps:
- `https://grafana.<your-domain>`
- `https://keycloak.<your-domain>`
- `https://n8n.<your-domain>`

### 8. Onboard a New App

Use this flow for any new app manifest under `apps/<app-name>/`.

#### 8.1 Create app manifest

ArgoCD bootstraps `apps/` recursively, so any new manifest in that tree is synced automatically.

Template (`apps/<app-name>/<app-name>.yaml`):

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: <app-name>
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: <app-name>
  template:
    metadata:
      labels:
        app: <app-name>
    spec:
      containers:
        - name: <app-name>
          image: <image-repo>:<tag>
          ports:
            - containerPort: 80
          env:
            - name: APP_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: sandbox-secrets
                  key: APP_DB_PASSWORD
---
apiVersion: v1
kind: Service
metadata:
  name: <app-name>
  namespace: default
spec:
  selector:
    app: <app-name>
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: <app-name>
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - <app-name>.<your-domain>
      secretName: <app-name>-tls
  rules:
    - host: <app-name>.<your-domain>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: <app-name>
                port:
                  number: 80
```

If the app exposes a host, add a matching replacement entry in `apps/kustomization.yaml` and a corresponding host value in `config/runtime.env`.

If the app needs a pinned image managed centrally, add a new `*_IMAGE` entry to `config/images.env`, run `make configure`, and add the corresponding replacement rule in `apps/kustomization.yaml`.

#### 8.2 Add/update local secret values

Add required keys to local `.env`, then apply:

```bash
make secrets
```

If the app needs a new key (example `APP_DB_PASSWORD`), add it to:

- `.env.example`
- `scripts/apply-secrets.sh` required keys list
- your local `.env`

#### 8.3 Commit and sync

Commit and push the manifest changes together with any runtime or image file changes in `config/`, `apps/`, and `argocd/`. ArgoCD then reconciles the cluster from Git.

#### 8.4 Verify app rollout

```bash
kubectl rollout status deployment/<app-name> -n default --timeout=300s
kubectl get pods -n default -l app=<app-name>
kubectl get ingress <app-name> -n default
```

#### 8.5 DB-backed app extension (PostgreSQL/MySQL)

When the app needs a dedicated DB/user:

1. Add password key in local `.env` (example: `DEMO_DB_PASSWORD=...`).
2. Add the same key in `.env.example` and `scripts/apply-secrets.sh`, then run `make secrets`.
3. In `apps/pgsql/pgsql.yaml` or `apps/mysql/mysql.yaml`, add DB container env wiring from `sandbox-secrets`.
4. Add provisioning line in DB init script ConfigMap:
	 - PostgreSQL: `create_user_and_database "demo" "demo" "${DEMO_DB_PASSWORD}"`
	 - MySQL: `create_user_and_database "demo" "demo" "${DEMO_DB_PASSWORD}"`
5. Re-apply changed DB manifest and rollout restart DB deployment.
6. Run init script in the running DB pod to provision new DB/user without resetting data.

PostgreSQL validation:

```bash
kubectl exec -n default deployment/pgsql -- sh -lc 'export PGPASSWORD="$POSTGRES_PASSWORD"; psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '\''demo'\'';"; psql -U postgres -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname = '\''demo'\'';"'
```

MySQL validation:

```bash
kubectl exec -n default deployment/mysql -- sh -lc 'mysql -N -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME=\"demo\"; SELECT User FROM mysql.user WHERE User=\"demo\";"'
```

---

## 🔌 Optional Integrations

- Optional: replace plain Kubernetes Secrets with a secret manager flow (for example External Secrets or Sealed Secrets) when moving beyond local sandbox usage.
- Optional: configure cert-manager with your preferred issuer for trusted public certificates.

### Secure Remote Git Usage

For shared or public Git repositories:

1. Do not commit real values to Git.
2. Keep sensitive values only in local `.env` and apply via `make secrets`.
3. For team/remote environments, use encrypted GitOps secrets:
	- Sealed Secrets (recommended for this stack), or
	- External Secrets Operator with a cloud secret manager.

Current baseline in this repo keeps secret values out of tracked manifests and in user-controlled local env files.

---

## 🧰 Helpful Commands

```bash
make up        # install or reuse k3s and install ArgoCD
make bootstrap # install k3s, apply secrets, and bootstrap ArgoCD apps
make sync      # re-apply the ArgoCD bootstrap application
make down CONFIRM_K3S_UNINSTALL=true  # uninstall k3s from the host
make status    # cluster and pod status snapshot
make password  # print ArgoCD admin password
```

---
*Maintained by [Chinmay Jog](https://github.com/chinmaymjog) | 📖 [Read my articles on Medium](https://medium.com/@chinmaymjog)*
