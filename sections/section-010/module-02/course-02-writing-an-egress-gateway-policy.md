---
draft: true
exam_objectives:
- Egress Connectivity Requirements
---
# Writing An Egress Gateway Policy

The previous idea is simple: pods leave the cluster through one node, and that node uses one address. This part turns it into a working `CiliumEgressGatewayPolicy`. You first measure the source address that the partner sees today, then apply the policy, then measure again. The comparison is the proof that the policy works.

## Measure the source address first

Always record the starting state. Without it you cannot tell a working policy from a request that was never affected. The partner is an HTTP service outside the cluster. Its `/ip` path returns the source address of the caller in the field `origin`.

Read the facts about the environment and send one request from `shuttle`:

<!-- astrona:playground:renew -->

```sh
PARTNER_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')
GATEWAY_IP=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')
GATEWAY_NODE=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_NODE}')
kubectl -n starfleet exec shuttle -- curl -s http://$PARTNER_IP:8080/ip
```

The answer is a JSON document. The `origin` value is the address of the node that runs `shuttle`. It is not `$GATEWAY_IP`. Print `echo $GATEWAY_IP` to see the address that the policy will use.

## The policy resource

A gateway policy has one job: for traffic from these pods to these destinations, leave through that node with that address. Save this as `egress-gateway-shuttle.yaml`. Replace `<PARTNER>` with the value of `$PARTNER_IP`, `<GATEWAY>` with `$GATEWAY_IP` and `<GATEWAY_NODE>` with `$GATEWAY_NODE` before you save:

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
        kubernetes.io/hostname: <GATEWAY_NODE>
    egressIP: <GATEWAY>
```

Read the fields one by one.

- `metadata.name` names the policy. The resource has no namespace, because it applies to the whole cluster.
- `selectors` is a list. Each entry has a `podSelector` and may also have a `namespaceSelector`. The label `io.kubernetes.pod.namespace` is a label that Cilium adds to every pod, so the example restricts the match to the `starfleet` namespace without a second selector.
- `destinationCIDRs` lists the external destinations. Use the smallest range that covers the partner. Traffic to any other address leaves the normal way.
- `egressGateway.nodeSelector` chooses the gateway node by node labels. The label `kubernetes.io/hostname` holds the node name, so the selector matches exactly one node.
- `egressGateway.egressIP` is the source address. It must be an address that the gateway node owns.

## Apply and check

Apply the policy:

```sh
kubectl apply -f egress-gateway-shuttle.yaml
```

Then check the result. Send the same request as before:

```sh
kubectl -n starfleet exec shuttle -- curl -s http://$PARTNER_IP:8080/ip
```

The `origin` value is now `$GATEWAY_IP`. The partner sees the same address for every request from `shuttle`, even if the pod runs on another node. Send a request from `drifter` in `outpost` to compare:

```sh
kubectl -n outpost exec drifter -- curl -s http://$PARTNER_IP:8080/ip
```

The `origin` for `drifter` is still the address of its own node, because the selector matches only the `starfleet` namespace and only the label `app: shuttle`.

You can also ask the cluster what it knows about the policy. The agent keeps a table of the policies that it compiled:

```sh
kubectl get ciliumegressgatewaypolicies
kubectl -n kube-system exec ds/cilium -- cilium-dbg bpf egress list
```

The first command lists the policy resource. The second command prints the entries in the eBPF map of the agent that `ds/cilium` selects: source pod addresses, destination prefixes and the gateway address. The exact columns depend on the version, so read the table on your screen.

## Selecting pods

The `selectors` list accepts several entries, and a pod is selected when any entry matches. Use these tools:

- `podSelector` matches pod labels in all namespaces. Always add the namespace label, as in the example, unless you want all namespaces.
- `namespaceSelector` matches namespace labels. Use it to select all pods of a set of namespaces.
- An entry may use both. Then a pod must match both selectors.

A pod that is created after the policy is applied is selected at once. The agent watches pods, so no restart is needed. Test with a new connection after you apply or change a policy, because a connection that was open before may not show the new behavior.

## Excluding some destinations

Sometimes one range inside `destinationCIDRs` must keep the normal path. The field `excludedCIDRs` lists such ranges. For example, a policy that sends all traffic to `0.0.0.0/0` through the gateway can exclude the range of the cluster nodes with `excludedCIDRs`, so that node-to-node traffic is not redirected. Use a broad destination range only with the exclusion list. The safe default is a list of exact partner prefixes.

## Choosing the egress address

You have two ways to pick the source address.

- Set `egressIP` to a dedicated address that you added to the node. The address is stable and can be moved to another node by changing the policy and the address together.
- Omit `egressIP`. Then Cilium takes the address of the interface of the node that faces the destination. The address is a normal node address, so you gain the gateway path but not a dedicated address.

For an allowlist at a partner, the dedicated address is the better choice. The partner lists one address, and the cluster team owns the node and the address.

## What you can now do

You can write a `CiliumEgressGatewayPolicy` with pod selectors, destination ranges, a gateway node and an egress address, apply it, and prove with `/ip` that the partner sees the fixed address. You can also leave one pod out of the policy by selecting with labels. The open question is what happens to the traffic when the gateway node fails, and how a network policy interacts with the gateway.

## Common pitfalls

> [!WARNING]
> The gateway policy resource has no namespace. A `nodeSelector` that matches no node leaves the traffic without a gateway, and the connection fails. An `egressIP` that the node does not own leads to hanging connections. Test with a new connection after every change. Do not put `0.0.0.0/0` in `destinationCIDRs` without an exclusion for node and pod ranges.
