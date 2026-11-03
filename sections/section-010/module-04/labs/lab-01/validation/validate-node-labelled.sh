#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway2_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_IP}')"
gateway2_node="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY2_NODE}')"
# Only the second worker may carry the role label.
nodes="$(kubectl get nodes -l role=egress-gateway -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)"
if [ "$nodes" = "$gateway2_node" ]; then
  echo "PASS: only ${gateway2_node} has the label role=egress-gateway"
  exit 0
fi
echo "FAIL: nodes with role=egress-gateway are '${nodes}', expected only ${gateway2_node}"
exit 1
