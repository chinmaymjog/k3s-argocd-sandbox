# Architecture

## What This Is

A local-cloud style Kubernetes environment for validating GitOps
delivery patterns, modular app deployment, and baseline platform
tooling. It's the direct Kubernetes/GitOps progression of
`cloudops-sandbox` - same operator model, runtime moved from Docker
Compose to K3s + ArgoCD. See the diagram in `README.md`.

## How It Works

1. `make configure` writes `config/runtime.env` and `config/images.env`
   (and their Kustomize mirrors under `apps/` and `argocd/`) from
   `APP_DOMAIN`/`REPO_URL`/`TARGET_REVISION`.
2. `make up` installs or reuses K3s on the host and installs ArgoCD.
3. `make bootstrap` applies secrets and the ArgoCD bootstrap
   Application.
4. ArgoCD syncs the `apps/` Kustomize tree using the committed runtime
   config.
5. Apps are reached through host-based Traefik ingress
   (`<service>.$APP_DOMAIN`).

App state persists via Kubernetes PVCs; desired state lives in Git
manifests, reconciled by ArgoCD.

## Key Decisions

- **Decision:** ArgoCD is the single deployment mechanism - no
  imperative `kubectl apply` per app.
  **Why:** Consistent, declarative rollout for every sandbox app.
  **Revisit if:** Sync failures become persistent across core apps.

- **Decision:** Each app keeps its own Kubernetes manifests under
  `apps/<name>/`.
  **Why:** Scalable onboarding pattern as more tools get added.
  **Revisit if:** App count causes real manifest sprawl.

- **Decision:** Keep the default app set to what's good to get
  started - ArgoCD, Traefik, Cert-Manager, Postgres, Grafana,
  Prometheus, n8n. Keycloak and a second DB engine (MySQL, Adminer,
  phpMyAdmin) live on the `advanced` branch instead.
  **Why:** A smaller default means fewer workloads, fewer secrets to
  set, and a shorter path from clone to running cluster.
  **Revisit if:** A genuinely common use case needs one of those apps
  by default.

## Known Risks / Rough Edges

- Runtime domain drift between what was used to bootstrap and what's
  currently checked in will break ArgoCD sync - re-run `make configure`
  after changing `APP_DOMAIN`/`REPO_URL`.
- Secrets in this repo are sandbox-only convenience; there's no
  production-grade secret manager integration (Sealed Secrets, External
  Secrets, etc.) in scope.
