---
estimated_duration: 25m
---

# Lab: Move The Egress Gateway To The Second Worker

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`).

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-010-04-01
docker rm -f ats-059-lab-010-04-01-partner
```

| Script | What it proves |
| --- | --- |
| `validate-node-labelled.sh` | Only the second worker has `role=egress-gateway` |
| `validate-policy-uses-label.sh` | The policy selects the gateway by the role label |
| `validate-policy-uses-new-address.sh` | The `egressIP` is the second gateway address |
| `validate-shuttle-new-origin.sh` | The partner sees the second address for `shuttle` |
| `validate-drifter-unselected.sh` | `drifter` is not selected |
| `validate-no-wildcard-destination.sh` | No wildcard destination |

The bootstrap adds one extra address to each worker node. `astrona destroy` does not remove the partner container.
