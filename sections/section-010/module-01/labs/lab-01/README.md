---
estimated_duration: 25m
---

# Lab: Limit Egress To One External Partner

Graded lab. **UNTESTED:** written from the Cilium documentation and never booted. The checks below were only checked statically (`astrona validate`, `bash -n`).

`shuttle` must reach only the partner (a `/32` `toCIDR` rule), keep DNS, and leave `drifter` alone. The task is in `question.md` and the walkthrough in `solution.md`.

```sh
astrona run -c .
astrona submit -c .
astrona destroy ats-059-lab-010-01-01
```

| Script | What it proves |
| --- | --- |
| `validate-partner-reachable.sh` | `shuttle` gets HTTP 200 from the partner |
| `validate-decoy-denied.sh` | `shuttle` cannot reach the decoy container |
| `validate-dns-allowed.sh` | `shuttle` resolves cluster names |
| `validate-policy-uses-cidr.sh` | The policy has a `/32` `toCIDR` rule and no wildcard |
| `validate-drifter-unaffected.sh` | `drifter` still reaches external services |

The bootstrap starts two Docker containers (`ats-059-lab-010-01-01-partner` and `-decoy`) on the `kind` Docker network. `astrona destroy` does not remove them: run `docker rm -f` on both.
