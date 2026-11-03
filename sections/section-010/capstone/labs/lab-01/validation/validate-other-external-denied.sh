#!/usr/bin/env bash
set -uo pipefail
partner_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.PARTNER_IP}')"
gateway_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.GATEWAY_IP}')"
router_ip="$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_IP}')"
# The router container listens on TCP 179. shuttle must not be able to connect to it.
connect_time="$(kubectl -n starfleet exec shuttle -- curl -s -o /dev/null --connect-timeout 4 --max-time 5 -w '%{time_connect}' "telnet://${router_ip}:179" 2>/dev/null)"
case "$connect_time" in
  ""|0|0.000000|0.00000)
    echo "PASS: shuttle cannot connect to ${router_ip}:179"
    exit 0
    ;;
esac
echo "FAIL: shuttle connected to ${router_ip}:179 (connect time ${connect_time})"
exit 1
