---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Summary

A partner outside the cluster usually accepts requests from known source addresses. By default the node masquerades the packets of a pod, so the partner sees the address of whichever node runs the pod. That address changes when the pod moves or the cluster grows, which makes an allowlist at the partner hard to keep correct.

The egress gateway solves this. A `CiliumEgressGatewayPolicy` selects pods by labels, lists the external destinations it applies to, and names one gateway node and one source address. The agents compile the policy into eBPF maps. The node of the pod forwards matching connections to the gateway node, and the gateway node masquerades them with the egress address. The partner sees one stable address for all selected pods.

The egress address must already exist on the gateway node, because Cilium does not create it. The feature needs eBPF masquerading and kube-proxy replacement. Pods outside the selectors, and traffic to destinations outside the listed ranges, keep the normal path.

A gateway policy chooses the path and the source address. It never allows traffic. A `CiliumNetworkPolicy` still decides which destinations a pod may reach, and it matches the real destination address. Both resources are needed for a pod that must reach only its partner and must be seen with a fixed address.

All selected traffic depends on one node. Capacity, failures and maintenance of that node affect every selected pod. A role label on the gateway node and a movable address make a replacement possible.

To diagnose a failure, test in order: network policy, pod selection, destination match, gateway node, owned address, and return path. A request that succeeds with the wrong source address points to a selector or destination mismatch. A request that hangs points to the node, the address, a policy drop or the return path.

<!-- astrona:playground:destroy -->
