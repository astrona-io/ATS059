---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Inspect BGP Control Plane Readiness

Record source addressing and the enabled control-plane baseline.

The task and solution use a separate pinned kind cluster. Run `testing/smoke.sh` with its private kubeconfig to verify initial rejection and reference success. Static validation is not live evidence. Runtime verification remains pending.
