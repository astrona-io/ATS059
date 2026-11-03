#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
sel_key="$(kubectl get ciliumbgpadvertisements -o json 2>/dev/null | jq -r '[.items[].spec.advertisements[] | select(.advertisementType == "Service") | .selector.matchExpressions[0].key // (.selector.matchLabels | keys[0])] | map(select(. != null)) | first // empty')"
if [ -z "$sel_key" ]; then
  echo "FAIL: no Service advertisement with a selector found"
  exit 1
fi
sel_val="$(kubectl get ciliumbgpadvertisements -o json | jq -r '[.items[].spec.advertisements[] | select(.advertisementType == "Service") | (.selector.matchExpressions[0].values[0] // .selector.matchLabels[$k])] | map(select(. != null)) | first // empty' --arg k "$sel_key")"
actual="$(kubectl -n starfleet get service probe-public -o json 2>/dev/null | jq -r --arg k "$sel_key" '.metadata.labels[$k] // empty')"
if [ -n "$actual" ] && [ "$actual" = "$sel_val" ]; then
  echo "PASS: probe-public has the label ${sel_key}=${actual}"
  exit 0
fi
echo "FAIL: probe-public lacks the label ${sel_key}=${sel_val}"
exit 1
