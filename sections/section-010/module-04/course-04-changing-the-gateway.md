---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Changing The Gateway

Sooner or later the gateway node needs maintenance or replacement. The partner has the old address on its allowlist, so a change has two parts: the node and the address. This part gives a safe order for moving a gateway to another node, explains what happens to open connections, and lists what to check afterward.

## Plan the move

A move has four steps. The order matters, because each step prepares the next one.

1. Add the new address to the new gateway node, and ask the partner to allow it next to the old one. Both addresses are valid during the change.
2. Label the new node with the role label.
3. Change the policy to use the new address. The selector is the role label, so the policy also needs the label to be on the new node only.
4. Remove the label and the address from the old node, and ask the partner to remove the old address.

If the partner cannot allow two addresses at once, plan a short window. Connections fail between the change of the policy and the update at the partner.

## Do it in the playground

<!-- astrona:playground:renew -->

The playground has a second address on the second worker. First look at the starting state:

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
GATEWAY2_NODE=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')
GATEWAY2_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')
kubectl -n starfleet exec shuttle -- curl -s http://$PARTNER_IP:8080/ip
```

The `origin` is the address of the first gateway. Now label the second worker and change the policy. Save this as `egress-gateway-move.yaml`, with `<PARTNER>` and `<GATEWAY2>` replaced by the values of `$PARTNER_IP` and `$GATEWAY2_IP`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: shuttle-to-partner
spec:
  selectors:
  - podSelector:
      matchLabels:
        io.kubernetes.pod.namespace: starfleet
        app: shuttle
  destinationCIDRs:
  - <PARTNER>/32
  egressGateway:
    nodeSelector:
      matchLabels:
        role: egress-gateway
    egressIP: <GATEWAY2>
```

Apply the label and the policy, then test with a new connection:

```sh
kubectl label node $GATEWAY2_NODE role=egress-gateway
kubectl apply -f egress-gateway-move.yaml
kubectl -n starfleet exec shuttle -- curl -s http://$PARTNER_IP:8080/ip
```

The `origin` is now `$GATEWAY2_IP`. The policy kept its name, so the apply replaced the old one.

## Open connections

The agents change their eBPF maps when the policy changes. A connection that was open before the change belongs to the old path. Its packets can fail after the change, because the new gateway node has no state for it. Long connections, such as a database session, break and the application must reconnect. New connections use the new path at once. Test with a new connection, as above, and expect clients to reconnect.

## Maintenance of the gateway node

To drain a gateway node for maintenance, do the same steps in the other direction: move the label and the policy to another node first, then drain. A node that goes down with the policy still pointing at it leaves every selected pod without access to the partner until the policy changes. Keep a standby node with a prepared address, so that the change is one edit.

## After the change

Check these in order:

1. The policy lists the new address: `kubectl get ciliumegressgatewaypolicies -o yaml`.
2. The agent on the node of the pod has the table entry: `cilium-dbg bpf egress list`.
3. The partner sees the new address: the `/ip` request.
4. Pods outside the selectors still show their node address.

## What you can now do

You can plan and run a move of the gateway in a safe order, explain why a role label simplifies it, explain what happens to open connections, and check the result in four steps. This closes the operational side of the egress gateway.

## Common pitfalls

> [!WARNING]
> Do not remove the old address before the partner allows the new one. A policy that still points at a stopped node leaves the pods without access. Open connections do not move to the new path, so applications must reconnect. Test with new connections only.
