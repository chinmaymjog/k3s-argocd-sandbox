# Architecture

## What This Is

A local-cloud style Kubernetes environment for validating GitOps
delivery patterns, modular app deployment, and baseline platform
tooling. It's the direct Kubernetes/GitOps progression of
`cloudops-sandbox` - same operator model, runtime moved from Docker
Compose to K3s + ArgoCD. See the diagram in `README.md`.

## How It Works

1. `make configure` writes `.env` values into the generated Kustomize
   runtime/image mirrors (`config/`, `apps/`, `argocd/`, and each
   `apps/optional/<group>/`).
2. `make up` installs or reuses K3s on the host and installs ArgoCD.
3. `make bootstrap` applies secrets and the ArgoCD bootstrap
   Application.
4. ArgoCD syncs the `apps/` Kustomize tree (core apps) using the
   committed runtime config.
5. Apps are reached through host-based Traefik ingress
   (`<service>.$APP_DOMAIN`).
6. Optional groups (`identity`, `db-admin`) are separate ArgoCD
   Applications under `argocd/optional/`, applied manually when wanted.

App state persists via Kubernetes PVCs; desired state lives in Git
manifests, reconciled by ArgoCD.

## Key Decisions

- **Decision:** ArgoCD is the single deployment mechanism - no
  imperative `kubectl apply` per app.
  **Why:** Consistent, declarative rollout for every sandbox app.
  **Revisit if:** Sync failures become persistent across core apps.

- **Decision:** Each app keeps its own Kubernetes manifests under
  `apps/<name>/` (core) or `apps/optional/<group>/` (optional).
  **Why:** Scalable onboarding pattern as more tools get added.
  **Revisit if:** App count causes real manifest sprawl.

- **Decision:** `.env` is the single source of truth for runtime
  config and image pins; `config/runtime.env`, `apps/runtime.env`,
  `argocd/runtime.env`, and the `images.env` files are all generated
  mirrors (`make configure`), never hand-edited.
  **Why:** One file to edit instead of five kept manually in sync.
  **Revisit if:** The generated-mirror approach stops scaling to more
  Kustomize bases.

- **Decision:** Split apps into a core set (always synced) plus opt-in
  groups - `identity` (Keycloak) and `db-admin` (MySQL, Adminer,
  phpMyAdmin) - each its own Kustomize base with its own ArgoCD
  Application under `argocd/optional/`, applied manually
  (`kubectl apply -f argocd/optional/<group>.yaml`).
  **Why:** `make bootstrap` used to deploy all 9 apps unconditionally -
  more workloads, secrets, and exposed surface than most first-time
  users need.
  **Revisit if:** A third or fourth optional group makes the manual
  per-group apply flow unwieldy enough to justify an ApplicationSet.

## Known Risks / Rough Edges

- Kustomize's load restrictor blocks resource/configMapGenerator file
  references that climb outside a kustomization's own directory tree -
  each optional group's manifests have to live fully inside that
  group's folder, they can't reference core manifests by relative path.
- ArgoCD syncs `apps/runtime.env`/`apps/images.env` (and the same files
  under each `apps/optional/<group>/`) from Git at `TARGET_REVISION`,
  not the local filesystem. Confirmed live: running
  `make configure APP_DOMAIN=<custom>` regenerates these files locally,
  but ArgoCD keeps applying the previously-committed values (Ingress
  hosts, image pins) until the regenerated files are committed and
  pushed - `make configure` reports success either way, so this fails
  silently unless you know to check. `check-runtime-config.sh` now
  warns when these files have uncommitted local changes.
- Runtime domain drift between what was used to bootstrap and what's
  currently checked in will break ArgoCD sync - re-run `make configure`
  **and commit + push the result** after changing `APP_DOMAIN`/`REPO_URL`.
- Secrets in this repo are sandbox-only convenience; there's no
  production-grade secret manager integration (Sealed Secrets, External
  Secrets, etc.) in scope.
