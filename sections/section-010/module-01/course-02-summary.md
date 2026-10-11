---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Summary

External egress depends on destination discovery, a routable path, permitted traffic and application trust. Source translation can make an external service see a node or gateway address rather than the original Pod.

An egress gateway can provide a supported controlled source path, but its prerequisites and failure behavior remain separate from policy permission. DNS, return routing and credential scope must agree before outbound connectivity is considered useful and protected.
