# Tasks

Keep this short and current. Delete finished work you don't need a
record of - this is a working list, not an audit log.

## Now

- [ ] ...

## Next

- [ ] Define a secure secret management upgrade path for non-sandbox
      use (Sealed Secrets or External Secrets).
- [ ] Add a troubleshooting runbook for common cluster/app startup
      failures.

## Done

- [x] Fixed REPO_URL typo and a conflicting ArgoCD sync mode
      (`directory.recurse` vs. Kustomize) (2026-09-15)
- [x] Trimmed the default app set to core only - Keycloak/MySQL/Adminer/
      phpMyAdmin moved to the `advanced` branch (2026-09-15)
- [x] Clean cluster bootstrap and app sync path validated end-to-end
      (2026-06-06)
