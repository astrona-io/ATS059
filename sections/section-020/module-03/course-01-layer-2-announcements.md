---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Layer 2 Announcements

On a local network, a host that wants to send a packet to an address on the same network first asks who owns that address. This part explains that question, how a Cilium node can answer it for a Service address, and what the cluster needs for the feature.

## The question that a local network asks

A client on an Ethernet network sends frames to hardware addresses (MAC addresses), not to IP addresses. To send a packet to the IPv4 address `192.0.2.50`, the client broadcasts an ARP (Address Resolution Protocol) request: "who has 192.0.2.50?" The host that owns the address answers with its MAC address, and the client stores the pair in its neighbor table. IPv6 does the same with NDP (Neighbor Discovery Protocol).

A Service address from a pool does not belong to any interface. No host would answer the question, and the client could not send the packet. A Layer 2 announcement solves this: a Cilium node answers the ARP request for the Service address with its own MAC address. The client then sends the traffic to that node, and the eBPF programs of Cilium forward it to a backend pod, as for any Service.

## One node answers at a time

Only one node answers for a given Service address. If two nodes answered, the client would store whichever answer arrived last, and the traffic would move between nodes. The nodes therefore elect the node for each Service. The mechanism is a Kubernetes lease, which the third part of this module covers. The consequence is that the traffic for one address enters the cluster through one node. This differs from BGP, where a router can spread traffic across several nodes.

## What the feature needs

Layer 2 announcements depend on these settings of the Cilium Helm chart.

- `l2announcements.enabled=true` turns the feature on.
- `kubeProxyReplacement=true` makes Cilium handle Services in eBPF. The feature requires it.
- `k8sClientRateLimit.qps` and `k8sClientRateLimit.burst` raise the limit of calls that the agent makes to the Kubernetes API server. Every Service needs a lease that its node renews, so a cluster with many Services needs higher limits than the default.
- `externalIPs.enabled=true` is needed only when you also announce the `externalIPs` of Services, not the load balancer addresses.

The network devices that the agent watches must include the interface used for the announcements. By default, Cilium detects them. A cluster with unusual interface names may need the Helm value `devices`.

<!-- astrona:playground:renew -->

Confirm the feature in the playground. The ConfigMap `cilium-config` holds the setting:

```sh
kubectl -n kube-system get configmap cilium-config -o jsonpath='{.data.enable-l2-announcements}'
kubectl get crd ciliuml2announcementpolicies.cilium.io
```

The first command prints `true`. The second prints the custom resource definition that carries the announcement policy.

## A Service with an address

Create a Service of type `LoadBalancer` for the `probe` pods. Save this as `service-probe-public.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: probe-public
  namespace: starfleet
  labels:
    announce: l2
spec:
  type: LoadBalancer
  selector:
    app: probe
  ports:
  - port: 80
    targetPort: 8080
```

Apply it and read the address:

```sh
kubectl apply -f service-probe-public.yaml
kubectl -n starfleet get service probe-public
```

The column `EXTERNAL-IP` shows an address from the pool. The pool assigned it, but nothing announces it yet. A client on the Docker network cannot reach it. The nodes are Docker containers on the same network, so a request from inside a worker container acts as a client on the local network. The ConfigMap `lab-env` holds the name of one worker container:

```sh
WORKER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')
LB_IP=$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
docker exec $WORKER curl -s --max-time 5 http://$LB_IP/ip
```

The request ends without an answer after five seconds, because no host answers the ARP question for `$LB_IP`.

## What you can now do

You can explain what an ARP request asks, how a Cilium node answers it for a Service address, why only one node answers, and which Helm values the feature needs. The open question is how to tell Cilium which Services, nodes and interfaces to use.

## Common pitfalls

> [!WARNING]
> A pool address is not reachable until it is announced. The feature needs kube-proxy replacement. Clients must be on the same Layer 2 segment as the nodes: a router in between does not forward ARP requests. A cluster with many Services needs higher API client rate limits.
