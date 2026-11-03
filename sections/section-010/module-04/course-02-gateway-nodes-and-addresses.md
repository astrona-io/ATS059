---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Gateway Nodes And Addresses

A gateway policy names a node and an address. If the node does not match, or if the node does not own the address, the traffic fails in a way that looks like a network problem. This part covers how to mark and select gateway nodes, how the `egressIP` and `interface` fields differ, and how to check the address on the node.

## Select the node with a role label

The simplest `nodeSelector` uses the label `kubernetes.io/hostname`, which holds the node name. It matches one node, and the policy then names a machine. A role label is better. You label the nodes that serve as gateways and select the label:

```sh
kubectl label node <NODE> role=egress-gateway
kubectl get nodes -l role=egress-gateway
```

The second command lists the nodes that the selector would match. The policy then says:

```yaml
  egressGateway:
    nodeSelector:
      matchLabels:
        role: egress-gateway
    egressIP: <ADDRESS>
```

When the platform team replaces the gateway node, it moves the label and the address. The policies stay unchanged. In the open source version of Cilium, a policy uses one gateway node. If the label is on more than one node, do not rely on a particular node being chosen. Keep the label on one node at a time.

## egressIP

`egressIP` sets the source address. The address must be configured on a network interface of the gateway node. Cilium does not add it. In a cloud, the address is usually a secondary private IP address of the node interface, and the cloud network must accept packets with that source. On a bare metal network, it is an address that the router sends to that node.

Check on the node that it owns the address. In the playground, the nodes are Docker containers:

<!-- astrona:playground:renew -->

```sh
GATEWAY_NODE=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')
GATEWAY_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')
docker exec $GATEWAY_NODE ip -4 addr show dev eth0
```

The output lists the primary address of the node and the extra address `GATEWAY_IP` with the prefix length 32. If the address is not in the list, the partner never sees it. Connections hang, because the gateway node does not own a source address that the network accepts.

## interface

The field `egressGateway.interface` selects an interface by name, for example `eth1`. Cilium then uses the primary address of that interface as the source address. Use it when the gateway node has a second network interface that is attached to the network that the partner allows. Set either `egressIP` or `interface`, not both. If neither is set, Cilium uses the address of the interface that faces the destination, which is a normal node address.

## Compare the three choices

| Setting | Source address | Use it when |
| --- | --- | --- |
| `egressIP` | The address that you name | The partner allowlists a dedicated address |
| `interface` | The primary address of that interface | The gateway node has a dedicated interface |
| neither | The node address toward the destination | You only need the traffic to leave through one node |

## What you can now do

You can mark a node as a gateway with a role label, select it in a policy, choose between `egressIP`, `interface` and neither, and check on the node that the address exists. The open question is how to design the policy itself: pods, destinations and exceptions.

## Common pitfalls

> [!WARNING]
> Do not select a gateway by node name if you plan to replace the node. Do not set both `egressIP` and `interface`. Cilium does not create the address on the node. A role label on two nodes does not give failover in the open source version.
