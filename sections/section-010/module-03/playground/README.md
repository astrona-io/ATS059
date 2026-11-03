# Name And Entity Egress Rules: Playground

Ungraded environment (`ats-059-playground-010-03`). **UNTESTED:** never booted. Three-node `kind` cluster, Cilium 1.20.2, two external HTTP containers (the partner and a decoy) and a CoreDNS `hosts` entry that resolves `partner.lab.test` to the partner. No network policy at the start.

```sh
astrona run -c .
astrona destroy ats-059-playground-010-03
docker rm -f ats-059-playground-010-03-partner ats-059-playground-010-03-decoy
```
