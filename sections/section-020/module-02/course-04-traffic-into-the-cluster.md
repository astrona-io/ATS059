---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Traffic Into The Cluster

The router now has a route to the Service address, and nodes announce it. This part follows a request from an external client through that route to a pod. It covers how the router spreads traffic across nodes, how `externalTrafficPolicy` changes the source address that the pod sees, and how Cilium forwards the packet to a backend.

## Equal-cost paths

When several nodes announce the same address, the router has several routes to it with the same cost. A router with ECMP (equal-cost multipath) enabled spreads connections across all of them. It usually picks the path with a hash of the source and destination addresses and ports, so all packets of one connection take the same path.

On FRR, the number of paths that the router may use for BGP routes comes from the setting `maximum-paths` in the address family of the BGP instance. Without it, the router installs one path only, and one node gets all the traffic. When you test a Service with many clients, look at the router table to see how many next hops the route has:

<!-- astrona:playground:renew -->

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show ip route bgp'
```

A route with two next hops lists two lines under the prefix. A route with one next hop uses one node, even when two nodes announce the address.

## Cluster policy and the source address

With `externalTrafficPolicy: Cluster`, any node can receive the request and forward it to any backend pod, also on another node. To do that, the node replaces the source address with its own address (source NAT), so the reply returns through the same node. The pod sees the node address, not the address of the client.

With `externalTrafficPolicy: Local`, only nodes with a local backend announce the address, and the node forwards the request to a local pod only. Cilium does not replace the source address, so the pod sees the real client address. The cost is uneven load: a node with two pods gets the same share of connections as a node with one pod.

| Policy | Nodes that announce | Source address in the pod | Extra hop |
| --- | --- | --- | --- |
| `Cluster` | All speaker nodes | Node address | Possible |
| `Local` | Nodes with a local backend | Client address | No |

## Direct server return and Maglev

Two Cilium load balancing options change the path further. They are Helm values of the chart.

- `loadBalancer.mode=dsr` selects direct server return (DSR). The node that receives the request forwards it to the backend node, and the backend replies directly to the client, without going back through the first node. This removes one hop on the return path. It needs a network in which the node may send a packet with the Service address as source.
- `loadBalancer.algorithm=maglev` selects consistent hashing for backend selection. When the set of backends changes, few connections move to a different backend.

Both options need kube-proxy replacement. For the exam, remember what they change: DSR changes the reply path, and Maglev changes how a backend is chosen.

## When a node fails

When a node fails, its session closes after the hold time, and the router removes its routes. The router then sends new connections to the remaining nodes. A connection that was in progress through the failed node breaks, because its state lived on that node. A client retries and arrives at another node.

With `externalTrafficPolicy: Local`, the router has fewer next hops, so a failure of the only node with a backend removes the address from the table. That is correct, because the address leads to no backend. The client gets no route instead of a connection that hangs.

## A request, end to end

A client on the external network sends a request to the Service address. The router looks up the address and finds one or more next hops. It forwards the packet to a node. The eBPF program on the node translates the Service address to a pod address and forwards the packet to the pod, on the same node or on another. The reply returns the same way, or directly to the client with DSR.

## What you can now do

You can explain how a router spreads traffic over several nodes, what `externalTrafficPolicy` changes for the source address, what DSR and Maglev do, and what happens to the routes when a node fails. You can read the next hops of a route on the router.

## Common pitfalls

> [!WARNING]
> A router without `maximum-paths` uses one node only. The client address is visible in the pod only with `externalTrafficPolicy: Local`. DSR needs a network that accepts the Service address as source. A connection that runs through a node that fails does not move to another node.
