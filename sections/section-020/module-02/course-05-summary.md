---
draft: true
exam_objectives:
- BGP Control Plane
---
# Summary

A BGP session carries a prefix only when an advertisement selects it. The `CiliumBGPAdvertisement` resource has a type: `PodCIDR` announces the pod prefix of each node that runs a speaker, and `Service` announces Service addresses. The peer configuration finds an advertisement by label in each of its address families, so an advertisement without that label sends nothing. The router shows what arrived, and its routes point to the nodes as next hops.

A Service of type `LoadBalancer` needs an address first. Cilium load balancer IP address management assigns it from a `CiliumLoadBalancerIPPool`: the operator takes the address from a block of a pool whose selector matches the Service, and writes it into the Service status. A pool assigns an address and does not make it reachable. The advertisement announces the address, and the router then sends traffic to a node, which forwards it to a pod.

The Service field `externalTrafficPolicy` controls which nodes announce the address. With `Cluster`, every speaker node announces it. With `Local`, only nodes with a local backend announce it. A missing route on one node can therefore be correct.

The peer configuration also decides how a session behaves under failure. The hold timer decides how long a dead node keeps its routes at the router, and shorter timers speed detection at the cost of stability. Graceful restart keeps routes at the router while an agent restarts. Multihop raises the TTL for peers that are not directly connected. An authentication secret sets a password for the session. A node override changes the router identifier, the port or the local address of one node.

After a change, the order of checks is fixed: conditions in the resource status, the session state in the node status, the routes on the router, and then a request through the address.

<!-- astrona:playground:destroy -->
