---
draft: true
exam_objectives:
- BGP Control Plane
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Make The Router Receive The probe-public Address

The network team expects the router to receive the address of the Service `probe-public`, tagged with the standard community `64513:100`. The sessions are up, but the router has no path to the address. Find the faults and fix them without touching the peer configuration or the cluster configuration.

## Starting state

A three-node `kind` cluster runs Cilium with the BGP Control Plane. The two workers have established sessions with an FRR router. A pool `starfleet-pool` exists. The Service `probe-public` in `starfleet` is of type `LoadBalancer` and has an address. A `CiliumBGPAdvertisement` named `service-addresses` exists. The ConfigMap `lab-env` in `starfleet` holds `ROUTER_CONTAINER`.

Read the router with:

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
docker exec $ROUTER_CONTAINER vtysh -c 'show bgp ipv4 unicast'
```

## Required result

- Both worker nodes keep an established session with the router.
- The `CiliumBGPPeerConfig` selects an advertisement that exists.
- The Service `probe-public` carries the label that the selector of the Service advertisement expects.
- The Service entry of the advertisement sets the standard community `64513:100`.
- The router has a path to the address of `probe-public`, and shows the community `64513:100` on it.

Submit when you are done:

```sh
astrona submit -c .
```
