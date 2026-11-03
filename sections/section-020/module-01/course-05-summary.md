---
draft: true
exam_objectives:
- BGP Control Plane
---
# Summary

BGP is the protocol that routers use to tell each other which prefixes they can reach. Two routers open a TCP connection on port 179, check each other's autonomous system number, agree on timers and then exchange prefixes. A session moves through the states Idle, Connect, Active, OpenSent, OpenConfirm and Established, and only an Established session carries prefixes. A wrong ASN, a wrong address or a blocked connection each stop the session at a different point, so the state tells you where to look.

Cilium runs a BGP speaker inside the agent of each selected node. The feature is off until `bgpControlPlane.enabled=true` is set. You describe the peering with Kubernetes resources: the `CiliumBGPClusterConfig` selects nodes with a label and defines instances and peers, the `CiliumBGPPeerConfig` holds the timers and the address families, the `CiliumBGPAdvertisement` selects what to announce, and the `CiliumBGPNodeConfigOverride` changes one node. The operator creates a `CiliumBGPNodeConfig` for each selected node, and the agent writes the session state into its status.

A session can be Established without any prefix. The peer configuration only sends prefixes that a matching advertisement selects by label. The state of a session is read from both ends: the status of the node configuration or the Cilium client on the cluster side, and the routing software on the router side.

When peering fails, the order of checks is the same each time. Confirm that the feature is on, that the node carries the label that the selector expects, that the names of the referenced resources exist, that the ASNs and the peer address match the router, and that the conditions in the status report no conflict.

<!-- astrona:playground:destroy -->
