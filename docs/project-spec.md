# Problem

## What are you building, and why?

A repeatable local and remote VM GitOps lab based on K3s and ArgoCD -
the Kubernetes/GitOps evolution of `cloudops-sandbox`, moving the same
modular lab concept from Docker Compose to Kubernetes manifests synced
by ArgoCD.

## Goals

- One-command lifecycle through Make targets after minimal config input.
- Standardized modular app onboarding through Kubernetes manifests
  under `apps/`.
- A lean, good-to-get-started default app set (see the README's Stack
  Catalog) - Keycloak, MySQL, and DB admin UIs live on the `advanced`
  branch instead of being on by default.

## Non-Goals

- No production-grade SLA guarantees for workloads in this repo.
- No managed Kubernetes cloud deployment automation.
- No multi-cluster federation or cross-region topology.

## Success Criteria

- A new user can bring up the core environment in under 30 minutes.
- ArgoCD syncs baseline apps from the repository with no manual
  manifest rewriting or per-app deploy steps.

## Risks

- Bootstrap drift between the local repo URL and ArgoCD's source
  target - mitigated by centralizing non-secret runtime values in
  `config/runtime.env` and applying them via Kustomize replacements.
- Cluster startup instability on resource-constrained machines -
  mitigated by keeping the default app set small.

## Notes

- `curl`, `kubectl`, `make`, `git`, `systemd`, and `sudo` are expected
  on the target host.
- Domain strategy is provided by the user (`nip.io` for local/remote-IP
  use, or a real domain).
- The repo pins a tested K3s release by default and allows explicit
  version override (`K3S_VERSION=`).
