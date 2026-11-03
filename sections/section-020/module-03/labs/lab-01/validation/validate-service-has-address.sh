#!/usr/bin/env bash
set -uo pipefail
worker="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')"
pool_base="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.POOL_BASE}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
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
if printf '%s' "$lb_ip" | grep -q "^${pool_base}\."; then
  echo "PASS: probe-public has the address ${lb_ip} from the pool"
  exit 0
fi
echo "FAIL: probe-public has no address from the pool (got '${lb_ip}')"
exit 1
