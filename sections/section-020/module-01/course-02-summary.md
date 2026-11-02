---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Summary

BGP exchanges route reachability information with configured peers. Cilium's BGP control plane can advertise supported prefixes, while the forwarding path remains a separate responsibility.

Session establishment, advertisement selection and accepted routes provide different evidence. Address allocation and Layer 2 announcement solve other problems; useful external service needs coherent next hops, both traffic directions, policy and healthy backends.
