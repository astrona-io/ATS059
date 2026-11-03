#!/usr/bin/env bash
# Environment setup (copy into every lab/playground as bootstrap/setup.sh).
# Set ENV_NAME to metadata.name of the config.yaml. astrona names the kind
# cluster "astro-<ENV_NAME>": context "kind-astro-<ENV_NAME>", node containers
# "astro-<ENV_NAME>-control-plane" and "astro-<ENV_NAME>-worker", "-worker2".
# UNTESTED: written from the Cilium and kind documentation, never booted.
set -euo pipefail

ENV_NAME="ats-059-lab-010-04-01"
CHART_VERSION="1.20.2"
CHART_SHA256="b2afd87b7f75f875f92a14559f14f59b7babbb479d968e3fd625a20bf30ec20e"
FRR_IMAGE="quay.io/frrouting/frr:10.3.1"
HTTPBIN_IMAGE="mccutchen/go-httpbin:2.25.0"
BGP_LOCAL_ASN=64513   # Cilium nodes
BGP_ROUTER_ASN=64512  # external router
bootstrap_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(kubectl config current-context)" != "kind-astro-${ENV_NAME}" ]]; then
  printf 'Refusing to operate on another Kubernetes context\n' >&2
  exit 1
fi

control_plane="astro-${ENV_NAME}-control-plane"
partner_name="${ENV_NAME}-partner"
router_name="${ENV_NAME}-router"

install_cilium() {
  local chart_path
  chart_path="$(mktemp)"
  curl --fail --silent --show-error --location --max-time 120 \
    "https://helm.cilium.io/cilium-${CHART_VERSION}.tgz" -o "$chart_path"
  python3 - "$chart_path" "$CHART_SHA256" <<'CHECKSUM'
import hashlib, sys
digest = hashlib.sha256(open(sys.argv[1], 'rb').read()).hexdigest()
assert digest == sys.argv[2], 'Chart checksum differs'
CHECKSUM
  helm upgrade --install cilium "$chart_path" --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost="$control_plane" \
    --set k8sServicePort=6443 \
    --set bpf.masquerade=true \
    --set ipv4NativeRoutingCIDR=10.244.0.0/16 \
    --set egressGateway.enabled=true \
    --set bgpControlPlane.enabled=true \
    --set operator.replicas=1 \
    --set hubble.relay.enabled=true \
    --wait --timeout 300s
  rm -f "$chart_path"
  kubectl -n kube-system rollout status daemonset/cilium --timeout=300s
  kubectl wait --for=condition=Ready nodes --all --timeout=180s
}

container_ip() {
  docker inspect -f '{{ (index .NetworkSettings.Networks "kind").IPAddress }}' "$1"
}

start_partner() {
  # External HTTP service on the kind Docker network, outside the cluster.
  docker rm -f "$partner_name" >/dev/null 2>&1 || true
  docker run -d --name "$partner_name" --network kind "$HTTPBIN_IMAGE" >/dev/null
}

start_router() {
  # External BGP router (FRR) on the kind Docker network. Accepts sessions from
  # any address in the kind subnet that uses AS $BGP_LOCAL_ASN.
  local subnet
  subnet="$(docker network inspect kind -f '{{ range .IPAM.Config }}{{ .Subnet }} {{ end }}' | tr ' ' '\n' | grep -v ':' | head -n 1)"
  docker rm -f "$router_name" >/dev/null 2>&1 || true
  docker run -d --name "$router_name" --network kind --privileged "$FRR_IMAGE" >/dev/null
  docker exec "$router_name" sed -i 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons
  docker restart "$router_name" >/dev/null
  sleep 5
  docker exec "$router_name" vtysh \
    -c 'configure terminal' \
    -c "router bgp ${BGP_ROUTER_ASN}" \
    -c 'bgp router-id 192.0.2.1' \
    -c 'no bgp ebgp-requires-policy' \
    -c 'neighbor CILIUM peer-group' \
    -c "neighbor CILIUM remote-as ${BGP_LOCAL_ASN}" \
    -c "bgp listen range ${subnet} peer-group CILIUM" \
    -c 'address-family ipv4 unicast' \
    -c 'neighbor CILIUM activate' \
    -c 'exit-address-family' \
    -c 'end' \
    -c 'write memory'
}

add_gateway_address() {
  # Adds a second IPv4 address to the first worker node. The egress gateway
  # policy uses it as the egress IP. Prints the address.
  local worker_container worker_ip gateway_ip
  worker_container="astro-${ENV_NAME}-worker"
  worker_ip="$(container_ip "$worker_container")"
  gateway_ip="${worker_ip%.*}.200"
  docker exec "$worker_container" ip addr add "${gateway_ip}/32" dev eth0
  printf %s "$gateway_ip"
}

write_environment_map() {
  # Facts the learner reads instead of guessing addresses. Extra arguments are
  # passed to kubectl create configmap (for example --from-literal=KEY=value).
  kubectl create namespace starfleet --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n starfleet create configmap lab-env --dry-run=client -o yaml \
    --from-literal=PARTNER_CONTAINER="$partner_name" \
    --from-literal=PARTNER_IP="$(container_ip "$partner_name" 2>/dev/null || true)" \
    --from-literal=ROUTER_CONTAINER="$router_name" \
    --from-literal=ROUTER_IP="$(container_ip "$router_name" 2>/dev/null || true)" \
    --from-literal=BGP_ROUTER_ASN="$BGP_ROUTER_ASN" \
    --from-literal=BGP_LOCAL_ASN="$BGP_LOCAL_ASN" "$@" | kubectl apply -f -
}

wait_for_workloads() {
  kubectl -n starfleet rollout status deployment/probe --timeout=180s
  kubectl -n starfleet wait --for=condition=Ready pod/shuttle --timeout=120s
  kubectl -n outpost wait --for=condition=Ready pod/drifter --timeout=120s
}
# --- per-environment section ---------------------------------------------
install_cilium
start_partner
gateway_ip="$(add_gateway_address)"
# Second egress address on the second worker node.
worker2_container="astro-${ENV_NAME}-worker2"
worker2_ip="$(container_ip "$worker2_container")"
gateway2_ip="${worker2_ip%.*}.201"
docker exec "$worker2_container" ip addr add "${gateway2_ip}/32" dev eth0
write_environment_map \
  --from-literal=GATEWAY_IP="$gateway_ip" \
  --from-literal=GATEWAY_NODE="astro-${ENV_NAME}-worker" \
  --from-literal=GATEWAY2_IP="$gateway2_ip" \
  --from-literal=GATEWAY2_NODE="astro-${ENV_NAME}-worker2"
kubectl apply -f "$bootstrap_directory/manifests/start.yaml"
wait_for_workloads
# Starting state: shuttle leaves through the first worker.
partner_ip="$(container_ip "$partner_name")"
kubectl apply -f - <<YAML
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: shuttle-to-partner
spec:
  selectors:
  - podSelector:
      matchLabels:
        io.kubernetes.pod.namespace: starfleet
        app: shuttle
  destinationCIDRs:
  - ${partner_ip}/32
  egressGateway:
    nodeSelector:
      matchLabels:
        kubernetes.io/hostname: astro-${ENV_NAME}-worker
    egressIP: ${gateway_ip}
YAML
