---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Summary

A Service address from a pool is only a number until something makes the network reach it. On a local network, clients ask who owns an address with ARP for IPv4 and NDP for IPv6. A Layer 2 announcement lets one Cilium node answer for the Service address with its own MAC address, and the eBPF programs of that node forward the traffic to a backend pod.

The feature needs `l2announcements.enabled=true` and kube-proxy replacement. A cluster with many Services also needs higher API client rate limits, because each announced Service has a lease. A `CiliumL2AnnouncementPolicy` selects the Services by label, the nodes that may answer and the interfaces by regular expression, and says whether it announces load balancer addresses, external IP addresses or both. A Service that the policy does not select, or a node that it does not select, takes no part.

The nodes elect the answering node with a Kubernetes lease named after the Service in the `kube-system` namespace. Only the holder answers. When the holder fails, the lease expires, another node takes it and sends gratuitous ARP replies. The failover time depends on the lease timing. One node carries all traffic for one address, and clients must be on the same Layer 2 segment.

Node IPAM is simpler. A Service with `loadBalancerClass: io.cilium/node` gets the addresses of eligible nodes in its status. It does not announce or move anything, so the network or the clients must reach the nodes.

The choice between the options follows the network. BGP fits a network with routers and spreads traffic with equal-cost paths. Layer 2 announcements fit a flat network and a Service that one node can carry. Node IPAM fits clusters where the clients already reach the nodes. The routing mode of the cluster is a separate choice: native routing needs the network to know the pod prefixes, which BGP can announce.

<!-- astrona:playground:destroy -->
