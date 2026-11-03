# Overview: BGP Peering (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Apply BGP resources, change them and run `astrona destroy` to start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 has the BGP Control Plane enabled. The nodes use ASN 64513.
- An FRR router in a Docker container on the same Docker network, with ASN 64512. It accepts sessions from the node network.
- The ConfigMap `lab-env` in `starfleet` with `ROUTER_IP`, `ROUTER_CONTAINER`, `BGP_ROUTER_ASN` and `BGP_LOCAL_ASN`.
- The pods `shuttle` and `probe` in `starfleet` and `drifter` in `outpost`.
- No BGP resource.

## Helpers

```sh
env_value() {
  kubectl -n starfleet get configmap lab-env -o jsonpath="{.data.$1}"
}
router_summary() {
  docker exec "$(env_value ROUTER_CONTAINER)" vtysh -c 'show bgp summary'
}
```

## Ideas to try

- Run `router_summary` before you apply anything and see that there are no neighbors.
- Label the workers, apply a peer configuration and a cluster configuration, and run `router_summary` again.
- Change `peerASN` to a wrong value and watch the session fail. Read `kubectl describe ciliumbgpclusterconfigs`.
- Remove the node label from one worker and see its node configuration disappear.
- Add a `CiliumBGPNodeConfigOverride` with a `routerID` for one worker.
