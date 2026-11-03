---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Leases, Failover And Limits

Only one node answers for each Service address. This part explains how the nodes choose it, how long a failover takes, and what the design cannot do. These facts decide whether Layer 2 announcements fit a workload.

## The lease

For every announced Service, the agents compete for a Kubernetes lease. A lease is an object in the API group `coordination.k8s.io` that holds the name of one node (the holder) and a time. The holder renews the lease before it expires. If the holder stops renewing, another node takes the lease. The node that holds the lease answers ARP requests for the address.

Cilium creates the leases in the `kube-system` namespace. The name is `cilium-l2announce-` followed by the namespace and the name of the Service. List them and read the holder:

<!-- astrona:playground:renew -->

```sh
kubectl -n kube-system get leases | grep l2announce
kubectl -n kube-system get lease cilium-l2announce-starfleet-probe-public -o jsonpath='{.spec.holderIdentity}'
```

The first command lists one lease for each announced Service. The second prints the name of the node that holds the lease for `probe-public`. That node answers ARP for the address.

## Failover

When the holder node fails, its lease expires after the lease duration. Then another eligible node takes the lease and sends gratuitous ARP replies, which update the neighbor tables of the clients. Traffic then flows to the new node.

Three Helm values set the timing: `l2announcements.leaseDuration`, `l2announcements.leaseRenewDeadline` and `l2announcements.leaseRetryPeriod`. The defaults are 15 seconds, 5 seconds and 2 seconds. A shorter duration speeds up failover and increases the number of calls to the API server. Raise the client rate limits when you shorten the values for many Services.

During a failover, new connections fail until the clients learn the new MAC address, and connections that went through the failed node break.

## Prove a failover

In the playground the nodes are Docker containers, so you can stop the holder to simulate a node failure. Find the holder, stop its container, and read the lease again:

```sh
HOLDER=$(kubectl -n kube-system get lease cilium-l2announce-starfleet-probe-public -o jsonpath='{.spec.holderIdentity}')
docker stop $HOLDER
kubectl -n kube-system get lease cilium-l2announce-starfleet-probe-public -o jsonpath='{.spec.holderIdentity}'
```

Run the last command several times. After about the lease duration, it prints the other worker node, because the policy allows only worker nodes. Start the stopped node again with `docker start $HOLDER` when you are done. The container name of a node equals its Kubernetes node name in `kind`.

## The limits

- One node carries all traffic for one address. The bandwidth of that node limits the Service. There is no load balancing across nodes at the network level. Different Services can use different nodes.
- The clients must be on the same Layer 2 segment as the nodes. A router in between does not forward ARP.
- The failover time is the lease duration plus the time that clients take to learn the new address.
- Many Services create many leases and many calls to the API server.

These limits are the price of needing no router configuration. For a Service with high traffic or a network with routers, BGP is the better choice.

## What you can now do

You can find the node that holds the lease of a Service, describe the failover steps, name the Helm values that set the timing, and list the limits that make Layer 2 announcements unsuitable for high-traffic Services. The open question is how Node IPAM differs, and how to choose between all the options.

## Common pitfalls

> [!WARNING]
> A failover is not instant: it takes at least the lease duration. Very short lease values with many Services overload the API server. All traffic for one address enters through one node. Do not use Layer 2 announcements across routed networks.
