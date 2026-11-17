# k3s-argocd-sandbox

GitOps sandbox: K3s + ArgoCD syncing Kubernetes manifests (Kustomize) for modular stacks (n8n, Grafana, Prometheus, Postgres, cert-manager). Layout: `apps/` (stack manifests), `argocd/` (bootstrap app-of-apps), `config/` (runtime and image config), `scripts/` (operator scripts), `Makefile`. See `CONTRIBUTING.md` for conventions.

## Hard rules
- **`main` is what ArgoCD deploys.** Anything merged is applied to the cluster by the owner's ArgoCD, so keep changes small, reviewable and safe to roll back.
- You have no cluster access. Never run `kubectl apply/delete`, `make up/bootstrap/sync/down/secrets`, `argocd`, or the `scripts/` against a real system.
- Never commit real secret values, `.env`, kubeconfigs, tokens or passwords. Secrets come from the local `.env` via `make secrets`; manifests must not contain them or accept placeholder defaults like `admin/admin`.
- Don't change `.github/workflows/` or `argocd/bootstrap.yaml` unless the issue asks for it.
- Pin image tags/versions; never use `latest`.

## Working on issues
- Verify by rendering: `kubectl kustomize apps` and `kubectl kustomize argocd` must succeed; for shell changes run `bash -n <script>` and `shellcheck <script>`.
- Add resource requests/limits and probes when touching workloads; keep manifests under `apps/` small and focused.
- Update README and `docs/` when bootstrap, secrets flow or GitOps behavior changes.
- Conventional Commits; keep changes minimal and scoped; one issue per PR.
- Open a PR against `main` that references the issue (`Fixes #N`). Never push to `main` directly.
