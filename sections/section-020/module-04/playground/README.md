# Operate And Troubleshoot BGP: Playground

Ungraded environment (`ats-059-playground-020-04`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2 with the BGP Control Plane, an FRR router container (ASN 64512) and established sessions from both workers (ASN 64513). A pool `starfleet-pool` and a `LoadBalancer` Service `probe-public` exist. No advertisement exists, so the router learns no prefix.

```sh
astrona run -c .
astrona destroy ats-059-playground-020-04
```
