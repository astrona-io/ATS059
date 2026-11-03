# Overview: Operate And Troubleshoot BGP (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Apply resources, change them and run `astrona destroy` to start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 has the BGP Control Plane on. The nodes use ASN 64513.
- An FRR router in a Docker container with ASN 64512. The two workers have established sessions with it.
- A `CiliumBGPPeerConfig` that selects advertisements with the label `advertise: bgp`, and a `CiliumBGPClusterConfig` that selects nodes with the label `bgp=enabled`.
- A `CiliumLoadBalancerIPPool` named `starfleet-pool` with the range `POOL_START` to `POOL_STOP` from the Docker network.
- A Service `probe-public` of type `LoadBalancer` in `starfleet` without labels.
- No advertisement.

## Helpers

```sh
env_value() {
  kubectl -n starfleet get configmap lab-env -o jsonpath="{.data.$1}"
}
router() {
  docker exec "$(env_value ROUTER_CONTAINER)" vtysh -c "$1"
}
```

## Ideas to try

- Run `router 'show bgp summary'` and `kubectl get ciliumbgpnodeconfigs`.
- Create an advertisement with a community and read it with `router 'show bgp ipv4 unicast <ADDRESS>/32'`.
- Break the label of the advertisement and find the view where the route disappears.
- Change `peerASN` and read the session state on both sides.
