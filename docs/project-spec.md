# Problem

## Document Control

- Project: K3s-ArgoCD Sandbox
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## How To Use This File

- Keep each section short and concrete.
- Prefer measurable statements over vague goals.
- Add requirement IDs you can trace into architecture and tasks.

# Goals

- Provide a repeatable local and remote VM GitOps lab based on K3s and ArgoCD.
- Keep environment setup to one-command lifecycle actions through Make targets after minimal config input.
- Standardize modular app onboarding through Kubernetes manifests under apps/.
- Ensure core stacks are reachable through a consistent domain strategy.

# Non Goals

- No production-grade SLA guarantees for workloads in this repository.
- No managed Kubernetes cloud deployment automation in this phase.
- No multi-cluster federation or cross-region topology in this phase.

# Success Criteria

- A new contributor can bring up the baseline environment in under 30 minutes.
- ArgoCD can sync baseline apps from the repository with no manual manifest rewriting or per-app deploy steps.
- Core endpoints are reachable using configured domain strategy after initial bootstrap.

# Stakeholders

- Product/Platform: Internal Platform Engineering
- Engineering: CloudOps / DevOps maintainers
- Consumers: Engineers testing GitOps workflows on Kubernetes

# Assumptions

- curl, kubectl, make, systemd, and sudo are available on the target host.
- User has forked repository when using ArgoCD bootstrap against personal repo URL.
- Domain strategy is available through nip.io or public DNS.
- Non-secret runtime settings are committed in-repo so ArgoCD and local bootstrap use the same values.

# Risks

- Risk: Bootstrap drift between local repo URL and ArgoCD source target.
- Mitigation: Centralize non-secret runtime values in config/runtime.env and apply via Kustomize replacements.
- Risk: Secret handling in committed manifests for local convenience.
- Mitigation: Keep sandbox-only credentials and document production alternatives.
- Risk: Cluster startup instability on resource-constrained machines.
- Mitigation: Keep app set modular and document minimum host requirements.

# Scope Summary

- In scope: k3s host setup, ArgoCD install, modular app manifests, ingress/domain strategy, local validation workflow.
- Out of scope: production hardening, enterprise secret manager integration, multi-cloud platform rollout.

# Functional Requirements

- FR-001: Repository shall provide make targets for configure/up/bootstrap/sync/down/status/password operations.
- FR-002: ArgoCD bootstrap shall sync app manifests from repository path apps/.
- FR-003: App access shall follow host-based ingress strategy under configured domain.
- FR-004: App onboarding shall be standardized under apps/<name>/ manifests.
- FR-005: Documentation shall cover local laptop and remote VM setup flow.

# Non-Functional Requirements

- NFR-001: Setup path should be executable on macOS and Linux.
- NFR-002: Core lifecycle commands should complete without per-app imperative deploy steps.
- NFR-003: Repo should keep tracked templates/manifests but avoid production secret patterns.
- NFR-004: Stateful services should use Kubernetes persistent volumes for data retention.

# References

- README.md
- Makefile
- scripts/setup-cluster.sh
- scripts/install-argocd.sh
- argocd/bootstrap.yaml
