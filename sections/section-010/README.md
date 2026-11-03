---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Egress Connectivity Requirements

This section covers how traffic leaves a Cilium-managed cluster and reaches an external service. Egress is outbound traffic from a pod. Four mechanisms decide whether an outbound connection works: the route out of the node, the source address translation (masquerading), the network policy that allows the destination, and the return path of the reply.

The section has two modules and a capstone lab. The first module follows one request from a pod to a partner service, controls the allowed destinations with a `CiliumNetworkPolicy`, and explains why the partner sees a node address. The second module shows how a `CiliumEgressGatewayPolicy` gives selected pods a fixed source address, and why that policy does not replace network policy. The capstone combines both for one partner connection. A knowledge check closes the section.

## Learning Outcomes

- Trace the path of an outbound packet and name the component that decides each step.
- Explain masquerading and the settings `bpf.masquerade` and `ipv4NativeRoutingCIDR`.
- Write a default deny egress policy with a DNS rule and a `toCIDR` or `toFQDNs` rule.
- Predict the source address an external service sees, and diagnose a failed outbound connection stage by stage.
- Write a `CiliumEgressGatewayPolicy` and explain what it does and does not authorize.
