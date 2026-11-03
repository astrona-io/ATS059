---
draft: true
exam_objectives:
- BGP Control Plane
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Summary

Running BGP means seeing both ends. The status of the node configuration and `cilium bgp peers` show the sessions. `cilium bgp routes available` shows what a node knows, and `cilium bgp routes advertised` shows what it sends to a peer. On the router, `show bgp summary`, `show bgp ipv4 unicast` and `show ip route bgp` show what arrived and what was installed. The first view where the answer changes from yes to no marks the fault.

Communities and local preference are attributes in an entry of a `CiliumBGPAdvertisement`. A community is a tag that the router can match in its policy, and it has no effect without such a policy. Local preference decides between routes inside one autonomous system. Each entry in an advertisement can carry its own attributes.

For a session that does not establish, the order is: the feature flag, the node label and node configuration, the referenced names, the ASNs, TCP port 179 and the neighbor entry on the router. For a route that does not arrive, the order is: the Service address, the selector of the advertisement, the labels that the peer configuration selects, the available routes, the advertised routes and the router policy. A label typo in an advertisement is valid and silent.

The older `CiliumBGPPeeringPolicy` is deprecated. It maps to a cluster configuration, a peer configuration and one or more advertisements. A migration moves one group of nodes at a time and does not run both models for the same node. Clusters with multi-pool address management advertise their pod prefixes with the advertisement type `CiliumPodIPPool`.

<!-- astrona:playground:destroy -->
