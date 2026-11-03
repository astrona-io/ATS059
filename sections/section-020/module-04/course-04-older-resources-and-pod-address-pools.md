---
draft: true
exam_objectives:
- BGP Control Plane
---
# Older Resources And Pod Address Pools

Two topics remain for an operator of a BGP setup: the older resource model that you will meet in existing clusters, and the advertisement of pod address pools for clusters that do not use the default pod address management.

## The older model: CiliumBGPPeeringPolicy

The first version of the BGP Control Plane used one resource, `CiliumBGPPeeringPolicy`, with the API version `cilium.io/v2alpha1`. It held the node selector, the virtual routers, the neighbors and the list of announced prefixes in one object. The current model, which this course uses, splits the same content into several resources so that peer settings and advertisements can be reused and selected with labels. The older model is deprecated in the current releases. Check the release notes of the version that you run before you rely on it for new work.

A rough mapping helps when you migrate:

| In the peering policy | In the current model |
| --- | --- |
| `nodeSelector` | `nodeSelector` of the `CiliumBGPClusterConfig` |
| `virtualRouters[].localASN` | `bgpInstances[].localASN` |
| `virtualRouters[].neighbors[]` | `bgpInstances[].peers[]` with a `peerConfigRef` |
| neighbor timers and graceful restart | fields of the `CiliumBGPPeerConfig` |
| `exportPodCIDR` | an advertisement with the type `PodCIDR` |
| `serviceSelector` and `serviceAdvertisements` | an advertisement with the type `Service` and a `selector` |

Two details change behavior. In the older model, the label on the node chose the policy, and the policy held everything. In the current model, the label on the node chooses the cluster configuration, the peer configuration is reached by name, and the peer configuration reaches advertisements by label. A migration must move all three links.

Do not run both models for the same nodes. The result is two sets of settings for one speaker, and the behavior is not defined by this course. Remove the old policy as soon as the new resources show an established session.

## Migration steps

1. Write the new `CiliumBGPPeerConfig`, `CiliumBGPAdvertisement` and `CiliumBGPClusterConfig` from the old policy. Use the mapping above.
2. Apply them with a node selector that matches one node only, and keep the old policy for the other nodes. Check the session on that node.
3. Check the routes: `cilium bgp routes advertised ipv4 unicast` must list the same prefixes that the old policy announced.
4. Widen the selector, one group of nodes at a time, and delete the old policy for those nodes.

Plan graceful restart before you start. During the switch the speaker of a node is replaced, and a router without graceful restart removes the routes for the time of the switch.

## Pod address pools

With the default pod address management, each node has a pod CIDR, and the advertisement type `PodCIDR` announces it. A cluster that uses multi-pool IPAM gives pods addresses from `CiliumPodIPPool` resources, and the node has no single pod CIDR. For that mode, the advertisement type is `CiliumPodIPPool`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: pod-pools
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: CiliumPodIPPool
    selector:
      matchLabels:
        pool: team-a
```

The selector picks the pools by their labels, so only the pools that carry `pool: team-a` are announced. A pool that no advertisement selects stays unknown to the router. Each node announces the prefixes from the pools that it allocated to its pods.

<!-- astrona:playground:renew -->

The playground uses the default pod address management, so it has no pod pools. Read the field list of the advertisement types from the cluster instead:

```sh
kubectl explain ciliumbgpadvertisement.spec.advertisements.advertisementType
kubectl explain ciliumbgpadvertisement.spec.advertisements.selector
```

The first command names the allowed types. Check that `CiliumPodIPPool` is among them in the version that you run.

## Try it: map a policy

Write the new resources for this old policy: nodes with `bgp=enabled`, local ASN 64513, one neighbor at the router address with ASN 64512, export of the pod CIDR. Apply them and compare `cilium bgp routes advertised ipv4 unicast` with the pod CIDRs from `kubectl get nodes -o jsonpath='{.items[*].spec.podCIDR}'`.

## Pitfalls

Do not edit the CRDs of the old model to keep them alive. Plan the move to the current model.

A selector on a pool label that no pool carries is valid. It announces nothing and gives no error.
