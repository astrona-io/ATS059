#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
selected="$(kubectl get ciliumbgppeerconfigs -o jsonpath='{range .items[*]}{range .spec.families[*]}{.advertisements.matchLabels.advertise}{"\n"}{end}{end}' 2>/dev/null | sort -u | grep -v '^$' | head -n 1)"
if [ -z "$selected" ]; then
  echo "FAIL: no peer configuration selects advertisements by the label 'advertise'"
  exit 1
fi
match="$(kubectl get ciliumbgpadvertisements -l "advertise=${selected}" -o name 2>/dev/null)"
if [ -n "$match" ]; then
  echo "PASS: the peer configuration selects advertise=${selected} and an advertisement carries it"
  exit 0
fi
echo "FAIL: no advertisement has the label advertise=${selected}"
exit 1
