---
estimated_duration: 40m
---

# Capstone Lab: A Restricted Partner Connection With A Fixed Source Address

Graded capstone. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`).

`shuttle` must reach only the partner, and the partner must see the dedicated gateway address. It combines a `CiliumNetworkPolicy` and a `CiliumEgressGatewayPolicy`.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-capstone-010
docker rm -f ats-059-capstone-010-partner ats-059-capstone-010-router
```

| Script | What it proves |
| --- | --- |
| `validate-partner-reachable.sh` | HTTP 200 from the partner |
| `validate-source-is-gateway.sh` | The partner sees `GATEWAY_IP` |
| `validate-other-external-denied.sh` | No TCP connection to the router on 179 |
| `validate-dns-allowed.sh` | Cluster DNS works |
| `validate-drifter-unchanged.sh` | `drifter` is unaffected |
| `validate-policies-narrow.sh` | No wildcard destination |

The bootstrap starts partner and router containers and adds a secondary address to the first worker node. `astrona destroy` does not remove the containers.
