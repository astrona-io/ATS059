# Overview: Egress Gateway (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Apply policies, change them and run `astrona destroy` to start again.

## What is in the environment

- A three-node `kind` cluster running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 replaces kube-proxy, masquerades with eBPF and has the egress gateway feature on.
- The pod `shuttle` and the Deployment and Service `probe` in `starfleet`, and the pod `drifter` in `outpost`. `shuttle` and `drifter` run `curl`.
- An external HTTP partner on the Docker network of the cluster. Its `/ip` path returns the source address of the caller.
- A secondary IPv4 address on the first worker node. It is the egress address.
- The ConfigMap `lab-env` in `starfleet` with the keys `PARTNER_IP`, `GATEWAY_IP` and `GATEWAY_NODE`.
- No policy.

## Helpers

```sh
env_value() {
  kubectl -n starfleet get configmap lab-env -o jsonpath="{.data.$1}"
}
ask_partner() {
  kubectl -n "$1" exec "$2" -- curl -s --max-time 6 "http://$(env_value PARTNER_IP):8080/ip"
}
```

## Ideas to try

- Run `ask_partner starfleet shuttle` and compare `origin` with `env_value GATEWAY_IP`.
- Apply a `CiliumEgressGatewayPolicy` for `app: shuttle` and run the request again.
- Change `egressIP` to an address that the node does not own and watch the request hang.
- Select `drifter` too with a second selector entry, then remove it.
- Add a `CiliumNetworkPolicy` with an empty egress rule for `shuttle` and see that the gateway policy does not allow traffic.
