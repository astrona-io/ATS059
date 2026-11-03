---
draft: true
exam_objectives:
- BGP Control Plane
- Understand Options to Connect Cilium-managed Clusters with External Networks
---
# Troubleshooting A Route That Does Not Arrive

Two symptoms cover most BGP faults in a Cilium cluster: the session does not establish, or the session is up and the route does not arrive. In both cases the safe way is a fixed order of checks, from the cluster outward to the router. Each check removes a possible cause, so you never guess.

## Order of checks for a session that does not establish

1. The feature is on. The agent configuration has `enable-bgp-control-plane` set to `true`. If it is not, the Helm value `bgpControlPlane.enabled` is missing. Read it with `kubectl -n kube-system get configmap cilium-config -o yaml`.
2. The node is selected. The node carries the label that the `nodeSelector` of the `CiliumBGPClusterConfig` uses, and a `CiliumBGPNodeConfig` exists for it.
3. The names exist. The `peerConfigRef` names a `CiliumBGPPeerConfig` that exists. The conditions in the status of the cluster configuration say when a reference is missing.
4. The numbers match. `localASN` is the number the router expects as the neighbor ASN, and `peerASN` is the ASN of the router. A mismatch ends in the state `idle` or `active`, and the router log shows a notification about a bad peer AS.
5. The address is reachable. The nodes must reach `peerAddress` on TCP port 179. Test from a node container with `docker exec <NODE> nc -zv <ROUTER> 179` when the tool is in the node image, or from the router container toward the node.
6. The router accepts the neighbor. The router has a neighbor entry for the node address with the right remote AS, or a listen range that contains the node address. Look at `show bgp summary` and at the router log.

A state of `active` means that the node tries and the TCP connection does not complete. A state of `idle` after a failed attempt means that the speaker is waiting before it tries again. A state of `opensent` or `openconfirm` that does not change points at a mismatch in the open message, usually the ASN or an authentication setting.

## Order of checks for a route that does not arrive

The session is up and the router lacks the prefix. Check in this order:

1. The Service has an address. A `LoadBalancer` Service with `<pending>` as external address has nothing to announce. Check that a pool matches the Service and has free addresses.
2. The advertisement selects the Service. The `selector` in the entry of the `CiliumBGPAdvertisement` must match the labels of the Service. A selector on a label that the Service does not have is the most common cause.
3. The peer configuration selects the advertisement. The `advertisements.matchLabels` in the family of the `CiliumBGPPeerConfig` must match the labels of the `CiliumBGPAdvertisement`. A typo in either label leaves the advertisement unused and raises no error.
4. The node has the route. `cilium bgp routes available ipv4 unicast` lists the prefix on the node. If not, the checks 1 and 2 failed.
5. The node advertises the route. `cilium bgp routes advertised ipv4 unicast` lists the prefix for the peer. If the route is available and not advertised, the check 3 failed.
6. The router has the route. `show bgp ipv4 unicast <ADDRESS>/32` shows the path. If the node advertises it and the router does not show it, a policy on the router rejects it. Look at the inbound policy of the neighbor and at `show bgp neighbor <ADDRESS> received-routes` if the router keeps a copy of unfiltered routes.

A related case is the traffic policy. A Service with `externalTrafficPolicy: Local` is announced only by nodes that have a ready backend. If the Service is advertised and a node is missing as a next hop, check where the pods run.

<!-- astrona:playground:renew -->

In the playground, the Service `probe-public` exists with an address, and the `CiliumBGPAdvertisement` below has a typo in the label:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: service-addresses
  labels:
    advertise: bgpp
spec:
  advertisements:
  - advertisementType: Service
    service:
      addresses:
      - LoadBalancerIP
    selector:
      matchLabels:
        bgp: advertise
```

Apply it. Run the four views and decide at which check the order stops. Fix the label to `advertise: bgp` and check that the route arrives.

## Try it: a second fault

After the route arrives, remove the label `bgp=advertise` from the Service. Name the check that now fails and the view that proves it.

## Reading the router log

When the router refuses a session, its log says why. In the FRR container, `docker logs $ROUTER_CONTAINER` shows the notifications. A notification with "Bad Peer AS" names an ASN mismatch. One with "Unsupported Optional Parameter" or "Unacceptable Hold Time" points at timers or capabilities. Quote the exact text when you ask the network team for help.

## Pitfalls

Do not restart agents as a first step. A restart hides the cause, drops the sessions and, without graceful restart, removes routes for every Service on the node.

Do not read only the router. If the router lacks a route, the cause can still be on the node side in the advertisement selection.
