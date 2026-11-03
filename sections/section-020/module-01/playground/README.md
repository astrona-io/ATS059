# BGP Peering: Playground

Ungraded environment (`ats-059-playground-020-01`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with the BGP Control Plane, and an FRR router container (ASN 64512) on the `kind` Docker network. No BGP resource at the start.

```sh
astrona run -c .
astrona destroy ats-059-playground-020-01
docker rm -f ats-059-playground-020-01-router
```
