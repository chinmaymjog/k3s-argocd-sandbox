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
- If database-backed apps are added, follow the documented init-script pattern for PostgreSQL.

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

## AI-Assisted Contributions

AI tools are welcome, with these rules:

- **You are accountable** for every line you submit. Read and understand the code; unreviewed AI output will be closed.
- **Disclose** substantial AI assistance in the PR description.
- Never paste credentials, kubeconfigs or cluster details into AI tools, issues or PRs.
- Low-effort, bulk or off-topic AI-generated PRs and issues may be closed without review.

## Maintainer Automation

The Claude agent GitHub workflow is restricted to the repository owner and has no cluster access. Agent-authored PRs get the same review as any other PR and are never auto-merged. Because ArgoCD syncs `main`, merging a PR deploys it.

## Security Issues

See [SECURITY.md](SECURITY.md); do not file them as public issues.
