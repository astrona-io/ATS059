# Overview: Trace Outbound Traffic From Pods (Playground)

This is a playground, not a lab. It starts a cluster and waits. There is no task and no `astrona submit`. Write policies, break them, run `astrona destroy` and start again.

## What is in the environment

- A three-node `kind` cluster (one control plane node, two workers) running Kubernetes 1.35 without kube-proxy. Cilium 1.20.2 replaces kube-proxy and masquerades with eBPF.
- The pod `shuttle` and the Deployment and Service `probe` in `starfleet`, and the pod `drifter` in `outpost`. `shuttle` and `drifter` run `curl`.
- An external HTTP partner on the Docker network of the cluster. Its `/ip` path returns the source address of the caller. Its address is in the ConfigMap `lab-env`.
- No network policy.

## Helpers

```sh
partner_ip() {
  kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}'
}
ask_partner() {
  kubectl -n "$1" exec "$2" -- curl -s --max-time 6 "http://$(partner_ip):8080/ip"
}
```

## Ideas to try

- Run `ask_partner starfleet shuttle` and `ask_partner outpost drifter`, then compare the `origin` field with `kubectl get nodes -o wide`.
- Apply a policy with an empty egress rule for `app: shuttle` and watch the request fail.
- Add the DNS rule and a `toCIDR` rule for the partner one at a time.
- Read `kubectl -n kube-system get configmap cilium-config -o yaml` and find the masquerade settings.
