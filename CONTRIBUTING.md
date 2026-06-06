# Contributing

Use this repository to evolve the GitOps sandbox while keeping local secrets, bootstrap flow, and app manifests predictable.

## Workflow

1. Create a short-lived branch from `main` using `feature/*`, `bugfix/*`, or `hotfix/*`.
2. Keep the branch focused on one cluster, app, or documentation change.
3. Use Conventional Commits such as `feat: add local secrets workflow` or `docs: update onboarding flow`.
4. Validate the affected bootstrap, app, or documentation flow before opening a Pull Request.
5. Open a Pull Request with summary, validation, and any manual cluster test notes.

## Repo-Specific Guidance

- Keep app manifests under `apps/` small and focused.
- Keep `argocd/bootstrap.yaml` and README setup steps aligned.
- Use the local `.env` plus `make secrets` flow for sandbox secret values.
- If database-backed apps are added, follow the documented init-script pattern for PostgreSQL or MySQL.

## Guardrails

- Do not commit directly to `main`.
- Do not commit real secret values.
- Keep local `.env` values out of Git-tracked manifests.
- Update README and docs when setup or GitOps behavior changes.
- Avoid mixing unrelated cluster behavior changes in one PR.

## Validation

Before opening a Pull Request:

- review the diff for scope
- confirm secrets are not committed
- validate the affected setup or app flow locally when practical

## Documentation Updates

- Update README when bootstrap, fork setup, secrets flow, or onboarding steps change.
- Update docs/tasks.md when tracked work starts or finishes.
- Update docs/architecture.md when cluster control flow or secret strategy changes.