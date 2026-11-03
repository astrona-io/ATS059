---
draft: true
exam_objectives:
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# The Announcement Policy

Turning the feature on announces nothing. A `CiliumL2AnnouncementPolicy` says which Services to announce, from which nodes and on which network interfaces. This part reads the fields of the policy, applies one and checks the result from a client on the network.

## The resource

The policy is a cluster-scoped resource of the API group `cilium.io`. Its API version depends on the release, so read it from the cluster before you write it:

```sh
kubectl api-resources | grep -i l2announcement
```

The output shows the resource `ciliuml2announcementpolicies` and its version, for example `cilium.io/v2alpha1`. Use the version that your cluster prints.

<!-- astrona:playground:renew -->

Save this as `l2-policy.yaml`. Replace `cilium.io/v2alpha1` if the previous command printed another version:

```yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumL2AnnouncementPolicy
metadata:
  name: starfleet-l2
spec:
  serviceSelector:
    matchLabels:
      announce: l2
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: DoesNotExist
  interfaces:
  - ^eth[0-9]+
  loadBalancerIPs: true
```

Read the fields one by one.

- `serviceSelector` selects Services by label. A policy without a `serviceSelector` selects every Service. Use a label so that only intended Services are announced.
- `nodeSelector` selects the nodes that may answer. The example excludes control plane nodes, so only worker nodes answer ARP requests.
- `interfaces` is a list of regular expressions. A node announces on every interface whose name matches. Without the field, the node announces on all interfaces.
- `loadBalancerIPs: true` announces the addresses in the status of Services of type `LoadBalancer`.
- `externalIPs: true` announces the addresses in `spec.externalIPs`. It needs the Helm value `externalIPs.enabled=true`.

Apply the policy:

```sh
kubectl apply -f l2-policy.yaml
kubectl get ciliuml2announcementpolicies
```

## Test from a client on the network

Repeat the request from the worker container, now that the policy exists:

```sh
WORKER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')
LB_IP=$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
docker exec $WORKER curl -s --max-time 5 http://$LB_IP/ip
docker exec $WORKER ip neigh show $LB_IP
```

The first command now prints a JSON document. The second command shows the neighbor table entry for the address. Its `lladdr` value is the MAC address of the node that answered. Compare it with the MAC addresses of the nodes to see which node holds the address.

## Selectors that exclude

A Service that does not match `serviceSelector` is not announced, even if it has an address. A node that does not match `nodeSelector` never answers, even if it runs a backend pod. These two selectors are the usual reason for "my address does not answer". List the labels and compare:

```sh
kubectl -n starfleet get services --show-labels
kubectl get nodes --show-labels
```

## Interface names

On a node with several interfaces, the regular expression decides where the address is announced. An announcement on the wrong interface reaches the wrong network. Use a pattern that matches the interface that faces the clients, for example `^eth0$`, when the node has more than one interface.

## What you can now do

You can write a `CiliumL2AnnouncementPolicy` with a Service selector, a node selector and an interface list, apply it, and prove from a client on the same network that the address answers. The open question is which node answers, and what happens when it fails.

## Common pitfalls

> [!WARNING]
> A policy without a `serviceSelector` announces every Service. A `nodeSelector` that matches no node leaves the address unannounced. The interface list uses regular expressions, so `eth0` also matches `eth01`: anchor patterns with `^` and `$`. A router between the client and the nodes does not forward ARP.
