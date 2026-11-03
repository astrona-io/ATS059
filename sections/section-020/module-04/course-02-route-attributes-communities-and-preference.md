---
draft: true
exam_objectives:
- BGP Control Plane
---
# Route Attributes: Communities And Local Preference

A route in BGP is more than a prefix. It carries attributes, and the router uses them to decide what to do. Two of them are in your hands as a cluster operator: the community and the local preference. This part explains both, shows where they go in the `CiliumBGPAdvertisement`, and shows how to verify them on the router.

## Communities

A community is a tag on a route. It has no meaning of its own. The router that receives the route has a policy that matches on the tag and acts: it can accept the route, reject it, lower its priority or pass it on to other networks only when the tag allows it. The network team agrees on the values with you, so that a tag such as `64513:100` always means the same thing, for example "internal Service address".

There are three kinds. A standard community is two 16-bit numbers written as `ASN:value`. A well-known community is a name with a fixed meaning that routers implement the same way, such as `no-export`, which tells the receiving router not to pass the route to peers in other autonomous systems. A large community is three 32-bit numbers, written as `ASN:value1:value2`, for networks that use 32-bit ASNs.

## Local preference

Local preference is a number that routers inside one autonomous system use to compare routes to the same prefix. The route with the higher value wins. It is sent only to peers in the same autonomous system, so it matters in an iBGP design and has no effect on a router in another AS in the common eBGP case. A cluster that peers with a router in another AS can still set it, but the router will not use it for its choice. Use it when the session is iBGP, or when the other side asks for it.

## Where the attributes go

Both attributes are fields of an entry in a `CiliumBGPAdvertisement`. They apply to the routes that this entry creates. Save this as `bgp-advertisement-attributes.yaml`:

```yaml
apiVersion: cilium.io/v2
kind: CiliumBGPAdvertisement
metadata:
  name: service-addresses
  labels:
    advertise: bgp
spec:
  advertisements:
  - advertisementType: Service
    service:
      addresses:
      - LoadBalancerIP
    selector:
      matchExpressions:
      - key: bgp
        operator: In
        values:
        - advertise
    attributes:
      communities:
        standard:
        - "64513:100"
      localPreference: 200
```

The `attributes` block sits in the same list item as `advertisementType`. Standard communities are strings, so quote them. The field `wellKnown` takes a list of names and `large` takes a list of large communities in the same way.

## Per-type entries

An advertisement can hold several entries of different types, and each entry has its own attributes. This lets you give pod prefixes and Service addresses different tags:

```yaml
spec:
  advertisements:
  - advertisementType: PodCIDR
    attributes:
      communities:
        standard:
        - "64513:10"
  - advertisementType: Service
    service:
      addresses:
      - LoadBalancerIP
    selector:
      matchLabels:
        bgp: advertise
    attributes:
      communities:
        standard:
        - "64513:100"
```

A router policy can then match `64513:10` for pod prefixes and `64513:100` for Service addresses and treat the two differently.

<!-- astrona:playground:renew -->

Apply the file from the first example. Make sure that the Service `probe-public` has the label `bgp=advertise` and an address from the pool. Then look at the attributes on the router:

```sh
ROUTER_CONTAINER=$(kubectl -n starfleet get configmap lab-env -o jsonpath='{.data.ROUTER_CONTAINER}')
LB_IP=$(kubectl -n starfleet get service probe-public -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
docker exec $ROUTER_CONTAINER vtysh -c "show bgp ipv4 unicast $LB_IP/32"
```

The output lists a path from each worker with the community `64513:100`. Change the community in the file, apply it again and run the router command again. The change reaches the router without a session reset, because the speaker sends an updated route on the open session.

## Try it: well-known community

Replace the standard community with the well-known community `no-export` under `wellKnown`. Predict what the router shows in its BGP table, apply the change and check.

## Pitfalls

A community only labels a route. If the router has no policy for the value, nothing changes. Verify the effect on the router, not only the presence of the tag.

Quote standard community values. An unquoted `64513:100` can be read by a YAML parser as a number in some tools, and a mismatch then shows up as an error from the API server.
