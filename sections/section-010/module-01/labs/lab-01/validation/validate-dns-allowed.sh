#!/usr/bin/env bash
# shuttle must still resolve cluster names.
set -uo pipefail
if kubectl -n starfleet exec shuttle -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then
  echo "PASS: shuttle resolves cluster DNS names"
  exit 0
fi
echo "FAIL: shuttle cannot resolve kubernetes.default.svc.cluster.local; allow DNS to kube-dns on port 53"
exit 1
