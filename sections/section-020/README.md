---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Understand Options to Connect Cilium-managed Clusters with External Networks

This section covers how a cluster and an external network exchange routes. BGP (Border Gateway Protocol) is the routing protocol that two routers use to announce which address prefixes they can reach. The Cilium BGP Control Plane lets the Cilium agent on each node open BGP sessions with external routers and announce pod prefixes and Service addresses.

The section has four modules and a capstone lab. The first module explains BGP for Kubernetes engineers, the Cilium BGP resources, and how to bring up a peering session with an external router. The second module covers what the nodes announce (pod prefixes and Service addresses), how load balancer IP address management (LB IPAM) assigns external Service addresses from a pool, and the connection options and failure modes. The third module covers the options for a network without BGP routers: Layer 2 announcements and Node IPAM. The fourth module covers inspecting and troubleshooting BGP, route attributes and the older BGP resources. The capstone peers the nodes and publishes one Service. A knowledge check closes the section, and a final quiz covers the whole domain.

## Learning Outcomes

- Explain autonomous system numbers, peers, sessions and advertised prefixes.
- Name the role of each Cilium BGP resource and write a cluster config and a peer config.
- Read the state of a peering session from the node config status.
- Advertise pod prefixes and Service addresses, and explain which addresses are not announced by default.
- Assign load balancer addresses from a `CiliumLoadBalancerIPPool` and announce them.
- Choose timers and graceful restart options, and diagnose a session that does not establish.
- Announce a Service address with a `CiliumL2AnnouncementPolicy`, read its lease and choose between BGP, Layer 2 announcements and Node IPAM.
- Inspect sessions and routes, set communities and follow a fixed order of checks for a route that does not arrive.
