#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
# probe-public must be a LoadBalancer Service for app=probe with an address from the pool.
type="$(kubectl -n starfleet get service probe-public -o jsonpath='{.spec.type}' 2>/dev/null)"
selector="$(kubectl -n starfleet get service probe-public -o jsonpath='{.spec.selector.app}' 2>/dev/null)"
if [ "$type" != "LoadBalancer" ]; then
  echo "FAIL: Service probe-public has type '${type}', expected LoadBalancer"
  exit 1
fi
if [ "$selector" != "probe" ]; then
  echo "FAIL: Service probe-public selects app='${selector}', expected probe"
  exit 1
fi
if printf '%s' "$lb_ip" | grep -q '^198\.51\.100\.'; then
  echo "PASS: probe-public has the address ${lb_ip} from the pool"
  exit 0
fi
echo "FAIL: probe-public has no address from 198.51.100.0/28 (got '${lb_ip}')"
exit 1
