---
estimated_duration: 25m
---

# Lab: Allow The Partner By Name

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. Only static checks ran (`astrona validate`, `bash -n`).

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-010-03-01
docker rm -f ats-059-lab-010-03-01-partner ats-059-lab-010-03-01-decoy
```

| Script | What it proves |
| --- | --- |
| `validate-policy-by-name.sh` | A policy allows the partner name with `toFQDNs` on port 8080 |
| `validate-dns-rule.sh` | The DNS rule has a `rules.dns` section |
| `validate-name-works.sh` | `shuttle` reaches the partner by name |
| `validate-decoy-blocked.sh` | `shuttle` cannot reach the decoy |
| `validate-no-wildcard.sh` | No `world`, `all`, `0.0.0.0/0` or `*` destination |
| `validate-drifter-unaffected.sh` | `drifter` still reaches the decoy |

The bootstrap adds a CoreDNS `hosts` entry for the partner name. `astrona destroy` does not remove the Docker containers of the partner and the decoy.
