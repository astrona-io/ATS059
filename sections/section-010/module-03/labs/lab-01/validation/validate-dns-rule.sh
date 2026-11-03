#!/usr/bin/env bash
set -uo pipefail
partner_name="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_NAME}')"
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
decoy_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.DECOY_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json 2>/dev/null)"
# The policy needs a DNS rule: port 53 with rules.dns.
count="$(printf '%s' "$policies" | jq '[.items[] | select(.spec.endpointSelector.matchLabels.app == "shuttle") | select([.spec.egress[]? | select(any(.toPorts[]?; (.rules.dns // []) | length > 0))] | length > 0)] | length' 2>/dev/null)"
if [ "${count:-0}" -ge 1 ]; then
  echo "PASS: a policy for shuttle has a rules.dns section"
  exit 0
fi
echo "FAIL: no policy for shuttle has a rules.dns section on its DNS rule"
exit 1
