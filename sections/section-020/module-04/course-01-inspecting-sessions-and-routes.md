---
draft: true
exam_objectives:
- BGP Control Plane
---
# Inspecting Sessions And Routes

When BGP does not do what you expect, the first job is to see what each side believes. A session has two ends and a route has two tables on the way, so you need to know four views: the session state, the routes available on a node, the routes advertised to a peer and the routes learned by the router.

## The status of the node configuration

The operator writes one `CiliumBGPNodeConfig` for each selected node. Its status lists every peer with the peering state, the timers and the number of routes. This view needs only `kubectl`:

```sh
kubectl get ciliumbgpnodeconfigs
kubectl get ciliumbgpnodeconfigs <NODE> -o yaml
```

Read the `status` part of the second command. It has one entry for each BGP instance and, inside it, one for each peer. A healthy peer has the state `established`.

## The Cilium client

The Cilium command-line client reads the same data from the agents and prints it in tables. Run these on a machine that has the client and a kubeconfig for the cluster:

```sh
cilium bgp peers
cilium bgp routes available ipv4 unicast
cilium bgp routes advertised ipv4 unicast
```

The first command lists the sessions of all nodes with local AS, peer AS, peer address, session state and uptime. The second lists the routes that each node holds in its BGP table: these are the candidates. The third lists the routes that each node sends to its peers. A route can be available and not advertised. That happens when the peer configuration does not select the advertisement that would send it.

Without the client, the agent has the same commands. Run them inside an agent pod:

```sh
kubectl -n kube-system exec ds/cilium -- cilium-dbg bgp peers
kubectl -n kube-system exec ds/cilium -- cilium-dbg bgp routes available ipv4 unicast
```

`ds/cilium` picks one agent, so the answer is about one node. Pick the agent of the node you are debugging with `kubectl -n kube-system get pods -l k8s-app=cilium -o wide`, and run the command in that pod.

## The router side

The router is the second witness. In the FRR container of the playground, use `vtysh`:

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show bgp summary'
docker exec $ROUTER_CONTAINER vtysh -c 'show bgp ipv4 unicast'
docker exec $ROUTER_CONTAINER vtysh -c 'show ip route bgp'
```

The first command shows the neighbors and, for each one, the state or the number of received prefixes. The second shows the BGP table with all paths. The third shows the routes that the router installed in its forwarding table. A prefix can be in the BGP table and not in the forwarding table, for example when a better route to the same prefix exists from another source.

To see all attributes of one prefix, ask for it by name:

```sh
docker exec $ROUTER_CONTAINER vtysh -c 'show bgp ipv4 unicast <ADDRESS>/32'
```

The output lists each path to the prefix with the next hop, the origin, the local preference and the communities.

## Reading the views together

The four views answer different questions.

| View | Question it answers |
| --- | --- |
| Node status or `cilium bgp peers` | Is the session up? |
| `cilium bgp routes available` | Does the node know the route? |
| `cilium bgp routes advertised` | Does the node send the route? |
| Router `show bgp ipv4 unicast` | Did the router receive the route? |

Move along that list until the answer changes from yes to no. The step where it changes is the place of the fault. A node that knows the route and does not advertise it points at the advertisement selection. A node that advertises it and a router that does not have it points at the session or at a policy on the router.

<!-- astrona:playground:renew -->

Run the four views in the playground. The sessions are up and no advertisement exists, so `cilium bgp routes advertised` and the router table are empty. Create a `CiliumBGPAdvertisement` named `service-addresses` of type `Service` with the address type `LoadBalancerIP` and a selector on the label `bgp=advertise`, label it `advertise: bgp` and label the Service `probe-public` with `bgp=advertise`. Then run the views again and note at which view the route first appears.

## Try it: find the break

Remove the label from the Service and run `cilium bgp routes available ipv4 unicast` and the router view. State which of the four views changed first, and which one tells you most about the cause.
