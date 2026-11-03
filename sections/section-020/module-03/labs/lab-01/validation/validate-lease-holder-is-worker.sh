#!/usr/bin/env bash
set -uo pipefail
worker="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.WORKER_NODE}')"
pool_base="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.POOL_BASE}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
holder="$(kubectl -n kube-system get lease cilium-l2announce-starfleet-probe-public -o jsonpath='{.spec.holderIdentity}' 2>/dev/null)"
if [ -z "$holder" ]; then
  echo "FAIL: the lease cilium-l2announce-starfleet-probe-public has no holder"
  exit 1
fi
case "$holder" in
  *control-plane*) echo "FAIL: the lease is held by the control plane node ${holder}"; exit 1 ;;
esac
echo "PASS: the lease is held by ${holder}"
exit 0
