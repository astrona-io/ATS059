# Curriculum Coverage

Exam: Cilium Certified Associate (CCA). Domain: BGP and External Networking (6%).

The [official objectives](https://training.linuxfoundation.org/certification/cilium-certified-associate-cca/) were checked on 2026-10-11. Teaching structure is independently authored and does not add official requirements.

| Section | Official objective | Modules |
| --- | --- | --- |
| 010 | Egress Connectivity Requirements | 2 |
| 020 | Understand Options to Connect Cilium-managed Clusters with External Networks | 2 |

| Section / module | Module | Teaching files |
| --- | --- | --- |
| 010 / 01 | Trace Outbound Traffic From Pods To External Services | Egress path and masquerading; controlling egress with network policy; source identity and return paths |
| 010 / 02 | Give Pods A Fixed Source Address With The Egress Gateway | Why a fixed source address; writing an egress gateway policy; gateway failures and network policy |
| 020 / 01 | Peer Cilium Nodes With An External Router Using BGP | BGP for Kubernetes engineers; the Cilium BGP resources; bringing up a peering session |
| 020 / 02 | Advertise Pod And Service Addresses With BGP And LB IPAM | Advertising pod and Service addresses; load balancer addresses from a pool; connection options and failures |

AUTHORING.yaml records measurable goals and adaptation sources. Every objective retains its section ID. All technical readings remain draft. Question banks are separate from the reading manifest and follow their declared summaries. Private playgrounds and independent labs are included. Live verification is recorded separately.

## Hands-On Coverage

This course has 4 ungraded playgrounds (one per module), 4 module labs and 2 capstone labs. Each task, launch entry and solution follows the reading part it practises. Every lab and playground passed static checks only (`astrona validate`, `bash -n`, YAML parsing). None was booted or run, so all labs are untested and live verification is pending.

| Module | Lab | Level |
| --- | --- | --- |
| 010/01 | Limit Egress To One External Partner | intermediate |
| 010/02 | Give shuttle A Fixed Source Address | intermediate |
| 010 | Capstone: A Restricted Partner Connection With A Fixed Source Address | advanced |
| 020/01 | Peer The Worker Nodes With The External Router | intermediate |
| 020/02 | Advertise The probe Service And The Pod Prefixes | intermediate |
| 020 | Capstone: Publish The probe Service To The External Router | advanced |
