# Task Tracker

## Document Control

- Project: K3s-ArgoCD Sandbox
- Owner: Chinmay Jog
- Last updated: 2026-06-06
- Version: 0.1.0

## How To Use This File

- Keep this file lightweight and current.
- Track only work items that are actively planned or in progress.
- Every task must include at least one requirement ID.
- Every completed task must include one validation evidence link or note.

## Current Focus

- Theme: Align K3s-ArgoCD Sandbox with engineering-system workflow
- Current objective: Keep baseline stable and move on to security/troubleshooting hardening
- This week target: Bootstrap flow verified and next operational hardening item selected

## Now (Do First)

Keep this section to a maximum of 3 tasks.

| ID | Task | Requirement IDs | Owner | Verification | Status |
| -- | ---- | --------------- | ----- | ------------ | ------ |
| T-001 | Create project specification baseline for K3s-ArgoCD Sandbox | FR-005,NFR-002 | Human+AI | docs/project-spec.md created and reviewed | Done |
| T-002 | Create architecture baseline with ADRs and traceability | FR-002,FR-003,NFR-002 | Human+AI | docs/architecture.md created and reviewed | Done |
| T-003 | Create lightweight task tracker aligned to engineering system | FR-005,NFR-002 | Human+AI | docs/tasks.md created and linked | Done |

## Next (Queue)

Use this for tasks planned after Now.

| ID | Task | Requirement IDs | Verification | Notes |
| -- | ---- | --------------- | ------------ | ----- |


## Later (Backlog)

Use this for ideas or deferred work.

| ID | Task | Requirement IDs | Notes |
| -- | ---- | --------------- | ----- |
| T-006 | Define secure secret management upgrade path for non-sandbox use | NFR-003 | Evaluate Sealed Secrets or External Secrets |
| T-007 | Add troubleshooting runbook for common cluster/app startup failures | NFR-001,NFR-002 | Keep lightweight and operator-focused |

## Done

| ID | Completed On | Requirement IDs | Validation Evidence | Notes |
| -- | ------------ | --------------- | ------------------- | ----- |
| T-001 | 2026-06-06 | FR-005,NFR-002 | docs/project-spec.md created | Added requirement baseline |
| T-002 | 2026-06-06 | FR-002,FR-003,NFR-002 | docs/architecture.md created | Added ADR baseline and traceability |
| T-003 | 2026-06-06 | FR-005,NFR-002 | docs/tasks.md created | Added lightweight execution tracker |
| T-004 | 2026-06-06 | FR-005,NFR-001 | README aligned to cloudops flow; architecture diagram, stack catalog, and setup modes verified | End-user-first flow restored for local/remote Kubernetes setup |
| T-005 | 2026-06-06 | FR-001,FR-002,NFR-002 | `make up` succeeded, `kubectl apply -f argocd/bootstrap.yaml`, `kubectl wait --for=condition=Available deployment --all -n default --timeout=600s`, final `kubectl get application sandbox-apps -n argocd` = Synced/Healthy | Clean cluster bootstrap and app sync path validated |

## Blocked

| ID | Blocker | Owner | Mitigation | Next Check |
| -- | ------- | ----- | ---------- | ---------- |
|    |         |       |            |            |

## Quick Coverage Check

- [x] Every task in Now has requirement IDs.
- [x] Every task in Done has validation evidence.
- [x] docs/project-spec.md reflects current scope.
- [x] docs/architecture.md reflects major decisions.

## Definition of Done

- [x] Code implemented
- [ ] Tests pass
- [ ] Review completed
- [x] Documentation updated
- [ ] CI passes
- [ ] Ready for deploy
