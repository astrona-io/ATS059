# Overview: BGP Advertisements And LB IPAM (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Apply resources, change them and run `astrona destroy` to start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 has the BGP Control Plane on. The nodes use ASN 64513.
- An FRR router in a Docker container with ASN 64512. The two workers have established sessions with it.
- A `CiliumBGPPeerConfig` that selects advertisements with the label `advertise: bgp`, and a `CiliumBGPClusterConfig` that selects nodes with the label `bgp=enabled`.
- A `CiliumLoadBalancerIPPool` named `starfleet-pool` with the block `198.51.100.0/28`.
- The Deployment and ClusterIP Service `probe` and the pod `shuttle` in `starfleet`, the pod `drifter` in `outpost`.
- No advertisement.

## Helpers

```sh
env_value() {
  kubectl -n starfleet get configmap lab-env -o jsonpath="{.data.$1}"
}
router_routes() {
  docker exec "$(env_value ROUTER_CONTAINER)" vtysh -c 'show ip route bgp'
}
```

## Ideas to try

- Run `router_routes` before any advertisement and see the empty result.
- Apply a `PodCIDR` advertisement and run `router_routes` again.
- Create a `LoadBalancer` Service and read its address with `kubectl -n starfleet get service`.
- Set `externalTrafficPolicy: Local` on the Service and scale the Deployment to one replica. See which worker still announces the address.
- Enable graceful restart in the peer configuration and delete one agent pod while you watch `router_routes`.
