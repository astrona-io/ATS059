---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# BGP Route Advertisement And External Connectivity

Border Gateway Protocol exchanges route reachability information between peers. In a Cilium deployment, the BGP control plane can advertise supported Pod or Service-related prefixes to external routers under its configuration. It should be distinguished from the mechanisms that actually forward application packets.

## Sessions Establish A Control Relationship

BGP peers exchange information under configured local and remote autonomous-system relationships and transport settings. The peer address must be reachable, and infrastructure policy must allow the session. Session establishment confirms that the control relationship is operating, not that every intended prefix has been advertised or accepted.

Advertisement configuration determines which supported addresses or ranges are announced. A Service can have an allocated external address but not match the relevant advertisement selection. A peer can also reject a received route because of its own policy. Review the prefix, peer and selected advertisement rather than assume all allocated addresses become externally reachable.

## Route Learning And Forwarding Differ

A router learning a route must select and install a usable path under its routing policy. The next hop must be reachable and the receiving node must have the supported behavior to deliver traffic to the intended backend. Cilium's BGP control plane supplies advertisements; it does not universally replace the Linux or infrastructure forwarding tables and paths.

A route visible in one control-plane display is therefore partial evidence. Traffic can still fail because the route was not selected, the next hop is wrong, filtering blocks packets or the Service has no usable endpoints. A useful investigation follows the route from advertisement through actual forwarding.

## Address Allocation Is Another Stage

LoadBalancer IP allocation chooses an address from a supported pool. BGP can advertise reachability to that address, but it does not necessarily allocate the address itself. Layer 2 announcement uses a different local-network mechanism to make supported addresses reachable. Select the appropriate approach for the infrastructure rather than treat allocation, BGP and Layer 2 as synonyms.

Different environments can combine allocation with one supported advertisement model. Their topology, router capabilities and broadcast-domain assumptions differ. An address that fits one network may be inappropriate for another, even when its textual range is valid.

## Preserve Both Directions And Policy

Incoming traffic must reach a node and backend under the selected Service behavior. Replies need a coherent return path, including any source preservation or translation. Infrastructure filters and endpoint policy can apply at different points and observe different peer identities.

A service listening locally can therefore remain unavailable externally despite a healthy BGP session. Compare backend readiness, Service selection and the actual external request. Application TLS and authorization remain separate from route reachability.

## Evaluate Convergence And Failure

Node loss, peer interruption and configuration changes can alter available routes. Timers and infrastructure policy affect convergence, while equal-cost paths can distribute traffic under supported routing behavior. Do not promise instantaneous or universal failover without the actual deployment contract.

For external connectivity, establish allocation, advertisement selection, peer state, accepted routes, next-hop reachability and useful application response in order. This separates the owner of each failure and avoids changing the wrong mechanism. The objective is a coherent path with supported evidence, not merely a green BGP session indicator.

## Common pitfalls

> [!WARNING]
> BGP advertises routes rather than forwarding every application packet. Address allocation, accepted prefixes, next hops, return paths and healthy Service backends need separate confirmation.
