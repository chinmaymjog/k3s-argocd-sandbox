# Architecture and Decisions

## Document Control

- Project: K3s-ArgoCD Sandbox
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## How To Use This File

- Explain design choices so a new engineer can understand trade-offs quickly.
- Keep each section tied to requirement IDs from docs/project-spec.md.
- Add one ADR entry whenever a non-trivial decision is made.

## System Context

### Business and Technical Context

K3s-ArgoCD Sandbox provides a local-cloud style Kubernetes environment for validating GitOps delivery patterns, modular app deployment, and baseline platform tooling.

### Architecture Goals

- Keep cluster lifecycle simple and repeatable via Make and scripts.
- Keep app delivery declarative and repository-driven through ArgoCD sync.
- Keep bootstrap and GitOps runtime inputs aligned through a tracked runtime config file.

## High-Level Design

### Component Overview

| Component | Responsibility | Owner |
| --------- | -------------- | ----- |
| K3s Cluster | Host Kubernetes runtime for sandbox apps | Platform Team |
| ArgoCD | GitOps sync engine for manifests in apps/ | Platform Team |
| config/runtime.env | Shared non-secret runtime inputs for bootstrap and ArgoCD | Platform Team |
| apps/ Manifests | Modular app deployment definitions | Platform Team |
| Ingress (Traefik) | Host-based routing for app endpoints | Platform Team |

### Interaction Diagram

See high-level architecture diagram in README.md.

## Data and Control Flow

### Request/Response Flow

1. User starts environment via make up.
2. User writes config/runtime.env through make configure.
3. k3s is installed or reused on the host and ArgoCD is installed.
4. User runs make bootstrap, which applies secrets and the ArgoCD bootstrap application.
5. ArgoCD syncs the apps/ Kustomize tree using the same runtime config files committed in Git.
6. User accesses apps through host-based ingress endpoints.

### State and Data Model Notes

- App state persists through Kubernetes PVC-backed storage.
- Cluster state and app desired state are represented in Git manifests.

### Failure Paths

- Bootstrap source repo mismatch prevents app sync.
- Runtime domain drift between bootstrap and checked-in manifests prevents healthy sync.
- Ingress/domain mismatch causes endpoint unreachability.
- Storage class or PVC issues block stateful workload startup.

## Deployment Architecture

### Environments

- Local laptop
- Remote VM

### Runtime Topology

- Single-host K3s cluster.
- ArgoCD controller in argocd namespace.
- App workloads in default and app-specific namespaces.

### Release and Rollback Strategy

- Changes are delivered via branch + PR merge.
- Rollback by reverting manifest changes and letting ArgoCD resync.

## Security and Compliance

- AuthN/AuthZ model: ArgoCD admin credential with optional app-native auth.
- Secret management: sandbox-only secrets in manifests; production alternatives documented.
- Input validation boundaries: Kubernetes API validation + app-level validation.
- Audit/logging requirements: kubectl logs/events and ArgoCD sync history.

## Observability Strategy

- Logs: Kubernetes pod logs and ArgoCD controller logs.
- Metrics: Prometheus/Grafana stack from apps/ manifests.
- Traces: not standardized in current scope.
- Alerts/SLOs: manual/experimental for sandbox scope.

## External Dependencies

| Dependency | Purpose | SLA/Risk | Backup Plan |
| ---------- | ------- | -------- | ----------- |
| k3s install script + pinned K3S_VERSION | Cluster bootstrap | Installer or release asset failure | Re-run install, inspect `systemctl status k3s`, or override `K3S_VERSION` |
| nip.io/public DNS | Hostname routing | DNS and certificate setup mismatch | Use local host mapping fallback for testing |

## Architecture Decision Records (ADR-lite)

### Decisions

- ID: ADR-001
- Title: Use ArgoCD as the single deployment mechanism
- Status: Accepted
- Date: 2026-06-06
- Context: Need consistent, declarative deployment for all sandbox apps.
- Decision: All app rollout is driven by ArgoCD sync from repository manifests.
- Requirement links: FR-002, NFR-002
- Alternatives considered: Imperative kubectl apply per app.
- Consequences: Better consistency, requires bootstrap correctness.
- Review trigger: Sync failures become persistent across core apps.

- ID: ADR-002
- Title: Keep modular app structure under apps/<name>
- Status: Accepted
- Date: 2026-06-06
- Context: Need scalable onboarding pattern for additional tools.
- Decision: Each app keeps its own Kubernetes manifests under apps/<name>/.
- Requirement links: FR-004, NFR-002
- Alternatives considered: Monolithic manifest bundle.
- Consequences: Better modularity, more files to maintain.
- Review trigger: App count causes manifest sprawl and onboarding friction.

## Lightweight Traceability

- FR-001 -> Makefile lifecycle and scripts/ automation -> ADR-001
- FR-002 -> argocd/bootstrap.yaml, argocd/kustomization.yaml, and apps/ sync model -> ADR-001
- FR-003 -> Traefik ingress host rules in app manifests -> ADR-002
- FR-004 -> apps/<name>/ modular manifest pattern -> ADR-002
- FR-005 -> README setup flows for local and remote usage -> ADR-001

## Pending Decisions

- Decision needed: Standard production-grade secret management path for future hardening.
- Owner: Platform Team
- Due date: 2026-07-15
