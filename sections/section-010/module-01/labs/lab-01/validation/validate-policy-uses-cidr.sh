#!/usr/bin/env bash
# A CiliumNetworkPolicy in starfleet selects app=shuttle and allows the partner
# with a /32 toCIDR (or toCIDRSet) rule. No wildcard destination.
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
policies="$(kubectl -n starfleet get ciliumnetworkpolicies -o json)"

selects_shuttle="$(echo "$policies" | jq -r '[.items[] | select(.spec.endpointSelector.matchLabels.app=="shuttle")] | length')"
if [ "$selects_shuttle" -lt 1 ]; then
  echo "FAIL: no CiliumNetworkPolicy in starfleet selects app=shuttle"
  exit 1
fi

has_partner="$(echo "$policies" | jq -r --arg ip "${partner_ip}/32" '[.items[] | select(.spec.endpointSelector.matchLabels.app=="shuttle") | .spec.egress[]? | ((.toCIDR // []) + [(.toCIDRSet // [])[]?.cidr])[]? | select(. == $ip)] | length')"
if [ "$has_partner" -lt 1 ]; then
  echo "FAIL: no egress rule with toCIDR ${partner_ip}/32 for shuttle"
  exit 1
fi

wide="$(echo "$policies" | jq -r '[.items[] | select(.spec.endpointSelector.matchLabels.app=="shuttle") | .spec.egress[]? | ((.toCIDR // []) + [(.toCIDRSet // [])[]?.cidr])[]? | select(. == "0.0.0.0/0")] | length')"
world="$(echo "$policies" | jq -r '[.items[] | select(.spec.endpointSelector.matchLabels.app=="shuttle") | .spec.egress[]? | (.toEntities // [])[]? | select(. == "world" or . == "all")] | length')"
if [ "$wide" -gt 0 ] || [ "$world" -gt 0 ]; then
  echo "FAIL: the policy allows a wildcard destination (0.0.0.0/0, world or all)"
  exit 1
fi
echo "PASS: shuttle is limited to the partner with a /32 toCIDR rule"
