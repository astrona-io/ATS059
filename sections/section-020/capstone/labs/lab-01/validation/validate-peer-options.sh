#!/usr/bin/env bash
set -uo pipefail
router_container="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')"
workers="$(kubectl get nodes -l '!node-role.kubernetes.io/control-plane' -o jsonpath='{.items[*].metadata.name}')"
lb_ip="$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)"
refs="$(kubectl get ciliumbgpclusterconfigs -o jsonpath='{range .items[*]}{range .spec.bgpInstances[*]}{range .peers[*]}{.peerConfigRef.name}{"\n"}{end}{end}{end}' 2>/dev/null | sort -u)"
if [ -z "$refs" ]; then
  echo "FAIL: no peerConfigRef found in any CiliumBGPClusterConfig"
  exit 1
fi
for ref in $refs; do
  graceful="$(kubectl get ciliumbgppeerconfig "$ref" -o jsonpath='{.spec.gracefulRestart.enabled}' 2>/dev/null)"
  hold="$(kubectl get ciliumbgppeerconfig "$ref" -o jsonpath='{.spec.timers.holdTimeSeconds}' 2>/dev/null)"
  if [ "$graceful" = "true" ] && [ -n "$hold" ] && [ "$hold" -le 30 ] 2>/dev/null; then
    echo "PASS: ${ref} enables graceful restart with hold time ${hold}"
    exit 0
  fi
done
echo "FAIL: no referenced peer configuration has gracefulRestart.enabled=true and holdTimeSeconds <= 30"
exit 1
