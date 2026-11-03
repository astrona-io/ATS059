# BGP Advertisements And LB IPAM: Playground

Ungraded environment (`ats-059-playground-020-02`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with the BGP Control Plane, an FRR router container with established sessions on both workers, and a pool `starfleet-pool` (`198.51.100.0/28`). No advertisement at the start.

```sh
astrona run -c .
astrona destroy ats-059-playground-020-02
docker rm -f ats-059-playground-020-02-router
```
