# Contributing

## Workflow

1. Create a short-lived branch from `main` using `feature/*`, `bugfix/*`, or `hotfix/*`.
2. Keep the branch focused on one cluster, app, or documentation change.
3. Use Conventional Commits such as `feat: add local secrets workflow` or `docs: update onboarding flow`.
4. Open a Pull Request with summary, validation, and any manual cluster test notes.

## Guardrails

- Do not commit directly to `main`.
- Do not commit real secret values.
- Keep local `.env` values out of Git-tracked manifests.
- Update README and docs when setup or GitOps behavior changes.

## Validation

Before opening a Pull Request:

- review the diff for scope
- confirm secrets are not committed
- validate the affected setup or app flow locally when practical