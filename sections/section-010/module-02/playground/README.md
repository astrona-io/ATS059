# Egress Gateway: Playground

Ungraded environment (`ats-059-playground-010-02`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with eBPF masquerading and the egress gateway enabled, an external HTTP partner container, and a secondary address on the first worker node.

```sh
astrona run -c .
astrona destroy ats-059-playground-010-02
docker rm -f ats-059-playground-010-02-partner
```
