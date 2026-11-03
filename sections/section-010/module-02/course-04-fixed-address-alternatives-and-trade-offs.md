---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Fixed Address Alternatives And Trade-offs

The egress gateway is one way to give a workload a stable source address. It is not the only way, and it is not always the best one. This part compares the options, so you can choose for a given partner, and explains what the gateway policy needs from the rest of the platform.

## The options

A partner that keeps an allowlist needs addresses that stay the same. These designs provide them.

- A dedicated node pool. You label and taint a group of nodes, and the pods of the workload run only there, with a node selector and a toleration. Every pod leaves with the address of one of those nodes. The pods are tied to those nodes by scheduling, not by networking.
- A NAT gateway of the network or the cloud. The subnet of the nodes routes outbound traffic to a NAT (network address translation) device that has a fixed public address. All pods in that subnet share the address, and Cilium is not involved.
- A proxy or an API gateway that you operate. The pod sends its request to the proxy inside the cluster, and the proxy has the fixed address. This works well for HTTP and gives you logging, but the application must use the proxy.
- The Cilium egress gateway. A `CiliumEgressGatewayPolicy` selects pods and destinations, and the traffic leaves through a chosen node with a chosen source address.

## What the gateway adds

The gateway works per pod selector and per destination range. Two pods on the same node can leave with different source addresses, and the same pod can leave with the node address for most destinations and with the egress address for the partner only. A dedicated node pool cannot do this, because the address depends on where the pod runs. A cloud NAT gateway cannot do it either, because it sees only the subnet.

The gateway also needs no change in the application and no change in the pod specification. The selection is a policy on labels, so a team can add or remove a workload by changing a label.

## What the gateway costs

All selected traffic passes through the gateway node. Its network bandwidth and its connection tracking table limit the throughput of every selected pod. In the open source version of Cilium, a policy uses one gateway node. The policy has no automatic failover to a second node, so a failed gateway node stops the selected traffic until you change the policy or move the address. A plan for that failure belongs in the design, for example a standby node with the same role label and a procedure to move the address.

The feature has requirements on the cluster. It needs kube-proxy replacement and eBPF masquerading, which the Helm values `kubeProxyReplacement=true` and `bpf.masquerade=true` set, and the value `egressGateway.enabled=true` turns the feature on. A cluster that runs with kube-proxy and iptables masquerading cannot use it without a change of the whole data path.

## Choosing

<!-- astrona:playground:renew -->

Use these questions in order. Does the partner need an address per team or per workload, and not per cluster? Then use the gateway or a dedicated node pool. Does the cluster already have a NAT gateway with a fixed address, and does one address for all workloads satisfy the partner? Then the NAT gateway is the simplest choice. Is the protocol HTTP, and is a proxy already part of the design? Then the proxy is enough.

You can ask the cluster which gateway policies exist and which node they select. These commands read the policy and the node labels:

```sh
kubectl get ciliumegressgatewaypolicies
kubectl get nodes --show-labels
```

The first command lists the policies. The second shows which labels a `nodeSelector` can match. A selector that uses a label that no node has leaves the traffic without a gateway.

## Where the address comes from

The `egressIP` is an address that must exist on the gateway node. In a cloud, it is a secondary IP address of the network interface, which the cloud provider must allow. On a physical network, it is an address that the router sends to that node. If the address is not owned by the node, the partner never sees it, and replies do not return.

When the cluster peers with a router over BGP, the same node can also announce the egress address as a route. That is one way to make the replies find the gateway node. A later module in this section returns to this operational side.

## What you can now do

You can compare a dedicated node pool, a NAT gateway, a proxy and the Cilium egress gateway for a fixed source address, and say what each one costs. You can name the cluster requirements of the gateway and the single-node limit of one policy. The open question is how to operate a gateway node: choose it, move it and check it.

## Common pitfalls

> [!WARNING]
> The gateway does not give high availability by itself. Do not choose it when one address for the whole cluster is enough, because the NAT gateway is simpler. Do not forget that the egress address must be a real address of the node, or the replies never arrive.
