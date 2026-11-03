---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Summary

The egress gateway is a feature of the Cilium agent. It needs three Helm values: `egressGateway.enabled=true`, `bpf.masquerade=true` and `kubeProxyReplacement=true`. A policy resource is accepted by the API server even when the feature is off, so the ConfigMap `cilium-config` and the eBPF table of the agent are the way to confirm that the policy has an effect. The table is kept per agent, so a check has to run on the agent of the node of the pod.

A gateway policy names a gateway node and a source address. A role label on the node makes the selector independent of the node name, so replacing the node means moving the label and the address. In the open source version, a policy uses one gateway node and has no automatic failover. The `egressIP` must be an address that the node owns, because Cilium does not create it. The `interface` field uses the primary address of a named interface instead. Setting neither uses the node address toward the destination.

A good policy selects pods with namespace and pod labels, lists the smallest destination ranges, and uses `excludedCIDRs` for ranges that must stay on the normal path. Overlapping policies are avoided by giving each partner its own destination and its own label. The gateway policy chooses the path and the address. It never allows traffic, so a pod under default deny still needs a network policy rule for the partner.

A move of the gateway has a safe order: add and announce the new address, label the new node, change the policy, then remove the old label and address. Connections that were open before the change do not continue on the new path, so applications must reconnect. After the change, the policy, the table of the agent, the address seen at the partner and the behavior of unselected pods are checked in that order.

<!-- astrona:playground:destroy -->
