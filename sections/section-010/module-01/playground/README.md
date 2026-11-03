# Trace Outbound Traffic From Pods To External Services: Playground

Ungraded environment (`ats-059-playground-010-01`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with eBPF masquerading, and one external HTTP partner container on the `kind` Docker network.

```sh
astrona run -c .
astrona destroy ats-059-playground-010-01
docker rm -f ats-059-playground-010-01-partner
```
