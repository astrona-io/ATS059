---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Node IPAM And Choosing An Option

A cluster has more than one way to give clients a reachable address. This part covers Node IPAM, the simplest one, and then compares all the options in this course so that you can choose for a given network.

## Node IPAM

Node IPAM gives a Service of type `LoadBalancer` the addresses of the nodes themselves. It needs no pool and no announcement. It suits small clusters where clients can already reach the nodes, for example a single-node or edge cluster with a firewall that forwards ports to the node.

Turn it on with the Helm value `nodeIPAM.enabled=true`. A Service selects it with the field `loadBalancerClass`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: probe-node
  namespace: starfleet
spec:
  type: LoadBalancer
  loadBalancerClass: io.cilium/node
  selector:
    app: probe
  ports:
  - port: 80
    targetPort: 8080
```

Cilium writes the addresses of the eligible nodes into the status of the Service. With `externalTrafficPolicy: Local`, only nodes that run a backend pod are listed. The annotation `io.cilium.nodeipam/match-node-labels` limits the nodes to those with the given labels. The clients then connect to a node address on the Service port.

Node IPAM does not announce anything and does not move addresses. If a node fails, clients that use its address fail until they use another one. A DNS name with the addresses of all nodes, or a firewall in front, hides this.

## Compare the options

| Option | Needs from the network | Spread across nodes | Failover | Best for |
| --- | --- | --- | --- | --- |
| BGP Control Plane | A router that speaks BGP | Yes, by the router with ECMP | Hold timer, or graceful restart | Data centers with routers |
| Layer 2 announcements | Nodes and clients on one Layer 2 segment | No, one node per address | Lease duration | Labs, offices, small clusters |
| Node IPAM | Clients that reach the node addresses | By the clients or DNS | By the clients | Small and edge clusters |
| Cloud load balancer | A cloud provider | By the provider | By the provider | Cloud clusters |

The cloud load balancer is not a Cilium feature. It appears here because the cloud controller manager, not Cilium, assigns the address in that case.

## Routing mode is a separate choice

The options above are about Service addresses. A second question is how pod addresses are reachable from outside. In tunnel mode (VXLAN or Geneve), pod traffic between nodes is encapsulated, and the external network sees only node addresses. In native routing mode, the network must know how to reach the pod prefixes, so the cluster announces them with BGP or the network has static routes. BGP therefore serves both questions: Service addresses and pod prefixes.

## A decision path

<!-- astrona:playground:renew -->

Use these questions in order:

1. Does the network have routers that you can peer with? Then use BGP. It spreads traffic and handles node failures by routing.
2. Are the clients on the same Layer 2 segment, and is one node per address enough? Then use Layer 2 announcements with a pool.
3. Do the clients already reach the nodes, and does the cluster need no extra addresses? Then use Node IPAM.
4. Is the cluster in a cloud? Then the cloud load balancer is the usual choice.

You can read what a cluster currently uses. These commands list the pools, the announcement policies and the BGP resources:

```sh
kubectl get ciliumloadbalancerippools
kubectl get ciliuml2announcementpolicies
kubectl get ciliumbgpclusterconfigs
```

A resource type that returns an empty list is not in use. A Service of type `LoadBalancer` with `<pending>` in `EXTERNAL-IP` has no address source for its class or its pool.

## What you can now do

You can enable Node IPAM, select it with `loadBalancerClass`, and say what it does and does not do. You can compare BGP, Layer 2 announcements, Node IPAM and a cloud load balancer by what they need from the network and how they fail over, and you can choose one for a given network.

## Common pitfalls

> [!WARNING]
> Node IPAM does not announce addresses or fail over by itself. A `loadBalancerClass` that no controller handles leaves the Service in the `pending` state. Do not mix a pool address and Node IPAM on the same Service. Do not choose Layer 2 announcements for a network with routers between clients and nodes.
