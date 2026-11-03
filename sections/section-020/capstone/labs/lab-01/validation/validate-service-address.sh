#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
type="$(kubectl -n starfleet get service probe-public -o jsonpath='{.spec.type}' 2>/dev/null)"
selector="$(kubectl -n starfleet get service probe-public -o jsonpath='{.spec.selector.app}' 2>/dev/null)"
if [ "$type" != "LoadBalancer" ] || [ "$selector" != "probe" ]; then
  echo "FAIL: probe-public must be a LoadBalancer Service for app=probe (type '${type}', selector '${selector}')"
  exit 1
fi
if printf '%s' "$lb_ip" | grep -q '^198\.51\.100\.'; then
  echo "PASS: probe-public has the address ${lb_ip} from the pool"
  exit 0
fi
echo "FAIL: probe-public has no address from 198.51.100.0/28 (got '${lb_ip}')"
exit 1
