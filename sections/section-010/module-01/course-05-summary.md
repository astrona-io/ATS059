---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Summary

An outbound request from a pod crosses four mechanisms. The route takes the packet out of the node. Masquerading rewrites the source address from the pod address to the address of the node, so that an external server has an address it can answer. Network policy decides which destinations the pod may reach. The return path brings the reply back to the node, where the stored connection entry sends it to the right pod.

Cilium does the translation with eBPF when `bpf.masquerade` is on. It translates traffic to destinations outside `ipv4-native-routing-cidr`. Destinations inside that range, and other cluster nodes in eBPF mode, keep the pod address. The `ip-masq-agent` ConfigMap with `nonMasqueradeCIDRs` is a second way to list ranges that must not be translated.

A `CiliumNetworkPolicy` with an `egress` section switches the selected pods to default deny. Rules only add permissions. DNS needs its own rule, which sends port 53 traffic through the Cilium DNS proxy. `toCIDR` rules allow external prefixes by address, and `toFQDNs` rules allow names by the addresses that the DNS proxy saw in answers. A `toFQDNs` rule without the DNS rule allows nothing.

The external service sees the node address, not the pod, so its allowlist must name nodes, and the address can change when a pod moves. A reply needs a route back to the address in the request. When an outbound connection fails, test name resolution, policy, drops, the source address and the return path one at a time.

Key facts:

- Masquerading is source NAT on the node and uses a connection table to translate the reply.
- A pod that no policy selects accepts all egress.
- A policy rule matches the real destination address, before masquerading.
- `toFQDNs` depends on the DNS proxy and works only for addresses learned from answers.

<!-- astrona:playground:destroy -->
