# Operating The Egress Gateway: Playground

Ungraded environment (`ats-059-playground-010-04`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with eBPF masquerading and the egress gateway, an external partner container, and a policy `shuttle-to-partner` that sends `shuttle` through the first worker. The second worker has a second egress address.

```sh
astrona run -c .
astrona destroy ats-059-playground-010-04
docker rm -f ats-059-playground-010-04-partner
```
