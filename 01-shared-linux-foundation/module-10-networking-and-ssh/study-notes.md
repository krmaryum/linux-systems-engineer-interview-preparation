# Linux Systems Engineer II Interview Preparation

## Module 10 — Linux Networking and SSH

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 150 minutes

> **Remote-access safety:** A wrong address, route, DNS, firewall, or SSH change can disconnect a production server. Before changing remote networking, confirm console or out-of-band access, preserve the current session, record the working configuration, validate syntax, define rollback, and test a second session before closing the first.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain how data moves from an application to a remote host.
- Distinguish MAC addresses, IP addresses, ports, and process IDs.
- Interpret IPv4 addresses and CIDR prefixes.
- Calculate a basic subnet, address range, and gateway relationship.
- Explain IPv6 link-local and global addresses.
- Inspect interface, address, neighbor, route, and socket state.
- Distinguish NetworkManager devices from connection profiles.
- Configure DHCP and static IPv4 settings with `nmcli`.
- Configure persistent routes and DNS servers.
- Explain hostname resolution order.
- Diagnose local, link, route, DNS, port, service, firewall, and application problems.
- Explain TCP versus UDP.
- Administer OpenSSH clients and servers.
- Create and protect SSH key pairs.
- Validate `sshd` configuration safely.
- Interpret common SSH error messages.
- Perform a safe network-namespace lab.

---

## 2. The Linux Network Communication Path

When an application connects to a remote service, the path is approximately:

```text
Application
    ↓
Hostname resolution
    ↓
Destination IP address and port
    ↓
Routing-table lookup
    ↓
Next-hop neighbor resolution
    ↓
Network interface
    ↓
Switch, router, firewall, or cloud network
    ↓
Remote interface
    ↓
Remote listening socket
    ↓
Remote application
```

Every layer must work.

Example:

```bash
ssh admin@app01.example.com
```

The client must:

1. Resolve `app01.example.com`.
2. Select an IPv4 or IPv6 destination.
3. Find a matching route.
4. Resolve the local next hop at the link layer.
5. Reach TCP port 22.
6. Complete the TCP handshake.
7. Negotiate SSH algorithms.
8. Verify the server host key.
9. Authenticate the user.
10. Start the requested shell or command.

This layered model is the basis of good troubleshooting.

---

## 3. Essential Network Terms

| Term | Meaning |
|---|---|
| NIC | Physical or virtual network interface card |
| Interface | Linux representation of a network connection |
| MAC address | Link-layer identifier used on the local network |
| IP address | Logical address used for routed communication |
| Prefix | Number of bits identifying the network portion |
| Subnet | Group of addresses sharing a network prefix |
| Gateway | Router used to reach other networks |
| Route | Rule telling the kernel where to send packets |
| DNS | System that maps names to data such as IP addresses |
| Port | Logical service endpoint in TCP or UDP |
| Socket | Kernel endpoint combining protocol, addresses, and ports |
| MTU | Maximum packet size a link transmits without fragmentation |
| VLAN | Logical layer-2 network identified by a VLAN tag |
| Bond | Multiple interfaces combined for resilience or throughput |

---

## 4. OSI and TCP/IP Models

The OSI model is useful for reasoning:

| OSI layer | Examples | Linux evidence |
|---|---|---|
| 7 Application | SSH, HTTP, DNS | Application logs, `curl`, `dig`, `ssh` |
| 4 Transport | TCP, UDP | `ss`, ports, handshakes |
| 3 Network | IPv4, IPv6, ICMP | `ip address`, `ip route`, `ping` |
| 2 Data link | Ethernet, MAC, VLAN | `ip link`, `ip neigh` |
| 1 Physical | Cable, optic, radio, virtual link | Link state, hypervisor, switch |

The practical TCP/IP model often groups these as:

```text
Application → Transport → Internet → Link
```

### Interview Principle

> Troubleshoot from evidence, not assumptions. Prove interface state, address, route, name resolution, socket, service, and policy separately.

---

## 5. Interface Names

Modern RHEL commonly uses predictable names:

```text
enp1s0
ens3
eno1
enp0s8
```

Other common names:

```text
lo       loopback
bond0    bonded interface
br0      bridge
vlan100  VLAN interface
veth...  virtual Ethernet interface
```

List interfaces:

```bash
ip link show
```

Brief view:

```bash
ip -br link
```

NetworkManager view:

```bash
nmcli device status
```

Do not assume the interface is `eth0`.

---

## 6. Interface State

Example:

```bash
ip -br link
```

Possible state indicators:

- `UP`: administratively enabled.
- `DOWN`: administratively disabled.
- `LOWER_UP`: lower-layer carrier is detected.
- `NO-CARRIER`: no carrier or virtual link.
- `UNKNOWN`: common for loopback or some virtual interfaces.

Detailed statistics:

```bash
ip -s link show dev enp1s0
```

Look for:

- RX errors
- TX errors
- Dropped packets
- Overruns
- Carrier errors

Physical or virtual platform checks may still be necessary:

- Switch port
- VLAN
- Hypervisor NIC connection
- Cloud interface attachment
- Security policy

---

## 7. MAC Addresses and Neighbor Resolution

Display MAC address:

```bash
ip link show dev enp1s0
```

Example:

```text
link/ether 52:54:00:12:34:56
```

IPv4 uses ARP to resolve a local IPv4 address to a MAC address.

IPv6 uses Neighbor Discovery Protocol.

Linux exposes both through:

```bash
ip neigh
```

Specific interface:

```bash
ip neigh show dev enp1s0
```

Common states:

| State | Meaning |
|---|---|
| `REACHABLE` | Neighbor recently confirmed |
| `STALE` | Entry exists but requires confirmation when reused |
| `DELAY` | Waiting before probing |
| `PROBE` | Actively checking reachability |
| `INCOMPLETE` | Resolution has not completed |
| `FAILED` | Neighbor resolution failed |

An `INCOMPLETE` or `FAILED` gateway entry points toward:

- Wrong subnet or gateway
- VLAN mismatch
- Link-layer failure
- Gateway down
- Layer-2 filtering

---

## 8. IPv4 Address Structure

Example:

```text
192.168.10.25/24
```

Components:

```text
Address: 192.168.10.25
Prefix:  /24
Mask:    255.255.255.0
Network: 192.168.10.0
```

The `/24` means the first 24 bits identify the network.

### Common Prefixes

| Prefix | Netmask | Total addresses | Typical usable host addresses |
|---|---|---:|---:|
| `/8` | `255.0.0.0` | 16,777,216 | 16,777,214 |
| `/16` | `255.255.0.0` | 65,536 | 65,534 |
| `/24` | `255.255.255.0` | 256 | 254 |
| `/25` | `255.255.255.128` | 128 | 126 |
| `/26` | `255.255.255.192` | 64 | 62 |
| `/27` | `255.255.255.224` | 32 | 30 |
| `/28` | `255.255.255.240` | 16 | 14 |
| `/29` | `255.255.255.248` | 8 | 6 |
| `/30` | `255.255.255.252` | 4 | 2 |
| `/31` | `255.255.255.254` | 2 | Special point-to-point use |
| `/32` | `255.255.255.255` | 1 | Single-host route |

Traditional usable-host counts exclude the network and broadcast addresses. `/31` and `/32` have special routing uses and do not follow the ordinary host-subnet rule.

---

## 9. Basic Subnet Calculation

Example:

```text
Address: 192.168.10.70/26
```

A `/26` creates blocks of 64 addresses:

```text
192.168.10.0–63
192.168.10.64–127
192.168.10.128–191
192.168.10.192–255
```

`192.168.10.70` belongs to:

```text
Network:   192.168.10.64
Hosts:     192.168.10.65–126
Broadcast: 192.168.10.127
```

Check with installed tools:

```bash
ipcalc 192.168.10.70/26
```

### Why This Matters

If a host uses:

```text
IP:      192.168.10.70/26
Gateway: 192.168.10.1
```

the gateway is outside the host’s directly connected `/26` subnet. This is normally incorrect unless special on-link routing is configured.

---

## 10. Private, Loopback, and Link-Local IPv4

Private IPv4 ranges:

```text
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

Loopback:

```text
127.0.0.0/8
```

Most applications use:

```text
127.0.0.1
```

IPv4 link-local:

```text
169.254.0.0/16
```

An unexpected `169.254.x.x` address can indicate that normal address configuration failed, though link-local addressing can also be intentional.

Documentation example ranges:

```text
192.0.2.0/24
198.51.100.0/24
203.0.113.0/24
```

These are used in examples and should not represent real public services.

---

## 11. IPv6 Fundamentals

IPv6 addresses are 128 bits.

Example:

```text
2001:db8:10::25/64
```

The documentation prefix is:

```text
2001:db8::/32
```

### Common IPv6 Types

| Type | Example | Purpose |
|---|---|---|
| Loopback | `::1/128` | Local host |
| Link-local | `fe80::/10` | Local link and neighbor discovery |
| Global unicast | Usually `2000::/3` | Routable IPv6 |
| Unique local | `fc00::/7` | Private-style internal use |
| Multicast | `ff00::/8` | One-to-many delivery |

IPv6 does not use broadcast in the IPv4 sense.

Display addresses:

```bash
ip -6 address
```

Routes:

```bash
ip -6 route
```

Neighbors:

```bash
ip -6 neigh
```

Ping IPv6:

```bash
ping -6 -c 4 2001:db8:10::1
```

For a link-local destination, specify the interface:

```bash
ping -6 -c 4 fe80::1%enp1s0
```

Do not disable IPv6 merely because the immediate incident appears IPv4-related. Confirm application and platform requirements first.

---

## 12. Viewing IP Addresses

All addresses:

```bash
ip address show
```

Brief:

```bash
ip -br address
```

Specific interface:

```bash
ip address show dev enp1s0
```

IPv4 only:

```bash
ip -4 address show
```

IPv6 only:

```bash
ip -6 address show
```

Look for:

- Expected address
- Correct prefix
- Duplicate or stale address
- Address scope
- Dynamic versus permanent
- Interface state
- IPv6 link-local availability

---

## 13. Routing Fundamentals

The kernel routing table decides where packets go.

Display:

```bash
ip route
```

Example:

```text
default via 192.168.10.1 dev enp1s0 proto dhcp metric 100
192.168.10.0/24 dev enp1s0 proto kernel scope link src 192.168.10.25 metric 100
```

Meaning:

- Local `/24` traffic goes directly through `enp1s0`.
- Other IPv4 traffic uses gateway `192.168.10.1`.

### Longest Prefix Match

The most specific matching route wins.

Given:

```text
default via 192.168.10.1
10.0.0.0/8 via 192.168.10.2
10.20.0.0/16 via 192.168.10.3
```

Traffic to `10.20.5.10` uses the `/16` route because it is more specific than `/8`.

### Metrics

When multiple otherwise comparable routes exist, a lower metric is generally preferred.

Do not treat metric as stronger than longest-prefix matching.

---

## 14. Route Selection Tests

Ask the kernel how it would reach a destination:

```bash
ip route get 203.0.113.10
```

Example output may include:

- Gateway
- Interface
- Source address
- Routing table
- UID

IPv6:

```bash
ip -6 route get 2001:db8::10
```

This is more reliable than guessing from a long route table.

---

## 15. Default Gateway

The default route is used when no more specific route matches.

Show:

```bash
ip route show default
```

Common problems:

- Missing default route
- Wrong gateway
- Gateway outside the local subnet
- Multiple default routes with unintended metrics
- Default route attached to the wrong profile
- Policy-routing rule changes

Test the gateway first:

```bash
ping -c 4 GATEWAY_IP
```

But remember that ICMP may be filtered. Use multiple forms of evidence.

---

## 16. Policy Routing Awareness

Linux can use multiple routing tables and rules.

Inspect:

```bash
ip rule
ip route show table all
```

Policy routing can choose a route based on:

- Source address
- Packet mark
- Input interface
- Destination
- Priority

When `ip route` looks correct but packets still use an unexpected path, inspect rules and alternate tables.

Advanced policy routing is covered later in the Engineer II networking module.

---

## 17. Temporary vs. Persistent Network Changes

An `ip` command usually changes the running kernel state only:

```bash
sudo ip address add 192.0.2.25/24 dev enp1s0
```

It normally does not persist after reboot or connection reactivation.

NetworkManager profile changes persist:

```bash
sudo nmcli connection modify PROFILE ipv4.addresses 192.0.2.25/24
```

### Interview Answer

> Use `ip` to inspect and perform controlled temporary testing. Use NetworkManager tools such as `nmcli` for persistent RHEL network configuration.

---

## 18. NetworkManager Architecture

Key concepts:

```text
Network device
     +
Connection profile
     ↓
Activated configuration
```

### Device

A network interface:

```text
enp1s0
```

### Connection Profile

A saved set of settings:

```text
production-lan
```

One device can have multiple profiles, but typically only one profile is active on it at a time.

Inspect:

```bash
nmcli device status
nmcli connection show
nmcli connection show --active
```

Do not confuse a connection profile’s name with the interface name.

---

## 19. NetworkManager Service

Check:

```bash
systemctl status NetworkManager
```

Journal:

```bash
journalctl -u NetworkManager -b
```

General state:

```bash
nmcli general status
```

Networking state:

```bash
nmcli networking connectivity
```

Reload profile files:

```bash
sudo nmcli connection reload
```

Avoid restarting NetworkManager on a remote production server as a casual troubleshooting step. A restart may disrupt multiple interfaces and dependent services.

---

## 20. Inspecting Connection Profiles

List:

```bash
nmcli connection show
```

Active:

```bash
nmcli connection show --active
```

Details:

```bash
nmcli connection show PROFILE
```

Selected fields:

```bash
nmcli -f connection.id,connection.interface-name,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.routes connection show PROFILE
```

Runtime device details:

```bash
nmcli device show enp1s0
```

Key difference:

- `connection show PROFILE` displays saved profile configuration.
- `device show INTERFACE` displays current device state and active values.

---

## 21. Creating a DHCP Profile

Example:

```bash
sudo nmcli connection add \
  type ethernet \
  ifname enp1s0 \
  con-name production-dhcp \
  ipv4.method auto \
  ipv6.method auto
```

Activate:

```bash
sudo nmcli connection up production-dhcp
```

Verify:

```bash
nmcli connection show --active
ip -br address show dev enp1s0
ip route
```

On a remote server, activating a new profile can drop the session. Use console access or a tested rollback mechanism.

---

## 22. Creating a Static IPv4 Profile

Example values:

```text
Interface: enp1s0
Profile:   production-static
Address:   192.0.2.25/24
Gateway:   192.0.2.1
DNS:       192.0.2.53 and 192.0.2.54
```

Create:

```bash
sudo nmcli connection add \
  type ethernet \
  ifname enp1s0 \
  con-name production-static \
  ipv4.method manual \
  ipv4.addresses 192.0.2.25/24 \
  ipv4.gateway 192.0.2.1 \
  ipv4.dns "192.0.2.53 192.0.2.54" \
  ipv6.method auto
```

Inspect before activation:

```bash
nmcli connection show production-static
```

Activate only under the approved safe procedure:

```bash
sudo nmcli connection up production-static
```

Verify:

```bash
ip -br address show dev enp1s0
ip route
nmcli device show enp1s0
getent hosts example.com
```

---

## 23. Modifying an Existing Profile

Set a static address:

```bash
sudo nmcli connection modify PROFILE \
  ipv4.method manual \
  ipv4.addresses 192.0.2.25/24 \
  ipv4.gateway 192.0.2.1
```

Set DNS:

```bash
sudo nmcli connection modify PROFILE \
  ipv4.ignore-auto-dns yes \
  ipv4.dns "192.0.2.53 192.0.2.54"
```

Add a second DNS server without replacing existing entries:

```bash
sudo nmcli connection modify PROFILE +ipv4.dns 192.0.2.55
```

Remove a specific DNS server:

```bash
sudo nmcli connection modify PROFILE -ipv4.dns 192.0.2.55
```

The leading `+` adds; the leading `-` removes. Without `+`, a property may be replaced.

---

## 24. Applying Profile Changes

Options include:

```bash
sudo nmcli connection up PROFILE
```

For supported changes on an active device:

```bash
sudo nmcli device reapply enp1s0
```

`reapply` can apply compatible profile changes without fully disconnecting the device, but not every property can be changed live.

Remote-change approach:

1. Preserve the current SSH session.
2. Confirm console or out-of-band access.
3. Capture the current profile.
4. Create or modify the new profile.
5. Inspect it before activation.
6. Apply under a change window.
7. Test gateway, DNS, application, and a second SSH session.
8. Close the original session only after successful validation.

---

## 25. Static Routes with NetworkManager

Add a route:

```bash
sudo nmcli connection modify PROFILE \
  +ipv4.routes "198.51.100.0/24 192.0.2.10"
```

Add with a metric:

```bash
sudo nmcli connection modify PROFILE \
  +ipv4.routes "198.51.100.0/24 192.0.2.10 50"
```

Remove:

```bash
sudo nmcli connection modify PROFILE \
  -ipv4.routes "198.51.100.0/24 192.0.2.10"
```

Inspect:

```bash
nmcli -f ipv4.routes connection show PROFILE
```

Apply and verify:

```bash
sudo nmcli connection up PROFILE
ip route
ip route get 198.51.100.25
```

Using `ipv4.routes` without a leading `+` replaces the current route list for that property. Review existing routes first.

---

## 26. Multiple Interfaces and Default Routes

A server may have:

- Management NIC
- Application NIC
- Backup NIC
- Storage NIC
- Public NIC

Not every connection should install a default route.

Prevent a profile from becoming a default route:

```bash
sudo nmcli connection modify PROFILE ipv4.never-default yes
```

Adjust route metric:

```bash
sudo nmcli connection modify PROFILE ipv4.route-metric 200
```

Inspect:

```bash
ip route show default
nmcli -f connection.id,ipv4.gateway,ipv4.never-default,ipv4.route-metric connection show
```

Multiple default routes can be intentional, but they require deliberate metrics, policy routing, and failure behavior.

---

## 27. NetworkManager Profile Storage

RHEL 9 commonly stores NetworkManager keyfiles under:

```text
/etc/NetworkManager/system-connections/
```

Inspect names and permissions:

```bash
sudo ls -l /etc/NetworkManager/system-connections/
```

Profile files can contain sensitive network information and should normally be root-only.

Prefer:

- `nmcli`
- RHEL network system role
- `nmstate`

over manually editing keyfiles. Tooling reduces syntax errors and keeps permissions consistent.

---

## 28. Hostnames

Show:

```bash
hostnamectl
hostname
hostname -f
```

Set persistently:

```bash
sudo hostnamectl set-hostname app01.example.com
```

Important distinctions:

- Static hostname
- Transient hostname
- Pretty hostname
- DNS records

Changing the local hostname does not automatically create or update DNS records.

---

## 29. Hostname Resolution Order

Linux name-service order is controlled through:

```text
/etc/nsswitch.conf
```

Inspect:

```bash
grep '^hosts:' /etc/nsswitch.conf
```

Example:

```text
hosts: files dns
```

This generally means:

1. Check local files such as `/etc/hosts`.
2. Query DNS.

Use the system’s normal resolver path:

```bash
getent hosts app01.example.com
```

`getent` is valuable because it follows Name Service Switch configuration.

---

## 30. `/etc/hosts`

Example:

```text
192.0.2.25 app01.example.com app01
```

Uses:

- Local override
- Bootstrapping
- Small isolated lab
- Temporary controlled testing

Limitations:

- Not centrally managed
- Easy to become stale
- Must be maintained on each host
- Can hide DNS problems

Inspect:

```bash
cat /etc/hosts
getent hosts app01.example.com
```

Do not leave undocumented temporary overrides in production.

---

## 31. DNS Configuration

Inspect resolver configuration:

```bash
cat /etc/resolv.conf
```

On RHEL, NetworkManager normally manages DNS settings.

NetworkManager view:

```bash
nmcli device show | grep -E 'IP[46]\\.DNS|GENERAL.DEVICE'
```

If `systemd-resolved` is in use:

```bash
resolvectl status
```

Query through the configured resolver:

```bash
getent ahosts app01.example.com
```

Direct DNS queries:

```bash
dig app01.example.com
dig +short app01.example.com
dig @192.0.2.53 app01.example.com
```

`dig @SERVER` tests a specific DNS server and may not represent the complete system resolver path.

---

## 32. DNS Record Awareness

Common records:

| Record | Purpose |
|---|---|
| `A` | Name to IPv4 address |
| `AAAA` | Name to IPv6 address |
| `CNAME` | Alias to another name |
| `PTR` | Reverse lookup |
| `MX` | Mail exchange |
| `NS` | Authoritative name server |
| `TXT` | Text-based verification or policy |
| `SRV` | Service location |

Examples:

```bash
dig A app01.example.com
dig AAAA app01.example.com
dig -x 192.0.2.25
dig MX example.com
```

Deep DNS administration appears in Module 13. This module focuses on client-side resolution and connectivity.

---

## 33. TCP and UDP

### TCP

TCP is:

- Connection-oriented
- Ordered
- Reliable
- Flow-controlled

Examples:

- SSH
- HTTPS
- Many database connections

### UDP

UDP is:

- Connectionless
- Message-oriented
- Lower overhead
- Not responsible for delivery or ordering

Examples:

- Many DNS queries
- NTP
- Some logging and streaming protocols

Applications can implement reliability on top of UDP.

---

## 34. TCP Three-Way Handshake

```text
Client → Server: SYN
Server → Client: SYN-ACK
Client → Server: ACK
```

If the handshake cannot complete:

- Service may not be listening.
- Host firewall may block.
- Network firewall or security group may block.
- Route may be wrong.
- Return path may be wrong.
- Server may actively reject.

Different errors offer clues:

| Symptom | Likely direction |
|---|---|
| Connection refused | Host reached; no listener or active reject |
| Connection timed out | Drop, route failure, unreachable path, or no response |
| No route to host | Local routing or returned unreachable condition |
| Name not known | Resolution failure |

These are starting points, not final proof.

---

## 35. Ports and Sockets

Port range:

```text
0–65535
```

Common categories:

| Range | General use |
|---|---|
| `0–1023` | Well-known or privileged ports |
| `1024–49151` | Registered ports |
| `49152–65535` | Dynamic/private range |

Common ports:

| Service | Port/protocol |
|---|---|
| SSH | 22/TCP |
| DNS | 53/UDP and TCP |
| HTTP | 80/TCP |
| HTTPS | 443/TCP |
| NTP | 123/UDP |
| SMTP | 25/TCP |
| LDAP | 389/TCP/UDP depending on use |
| LDAPS | 636/TCP |

Do not assume a service uses its default port. Inspect actual configuration and sockets.

---

## 36. Inspecting Listening Sockets

All listening TCP and UDP sockets:

```bash
sudo ss -lntup
```

Options:

```text
-l  listening
-n  numeric addresses and ports
-t  TCP
-u  UDP
-p  process information
```

TCP port 22:

```bash
sudo ss -lntp 'sport = :22'
```

All TCP connections:

```bash
ss -tan
```

Important bind examples:

```text
127.0.0.1:8080  local IPv4 only
0.0.0.0:8080    all IPv4 addresses
[::1]:8080      local IPv6 only
[::]:8080       IPv6 wildcard; dual-stack behavior depends on settings
```

A service listening only on loopback is not remotely reachable.

---

## 37. Socket and Process Correlation

Find listener:

```bash
sudo ss -lntup
```

Process details:

```bash
ps -fp PID
sudo systemctl status SERVICE
sudo journalctl -u SERVICE
```

Check a port with `lsof`, if installed:

```bash
sudo lsof -nP -iTCP:8080 -sTCP:LISTEN
```

The service can be active in systemd while failing to bind the expected address or port. Always check the socket.

---

## 38. Core Connectivity Tools

### `ping`

```bash
ping -c 4 192.0.2.1
```

Tests IP reachability using ICMP echo if permitted.

### `tracepath`

```bash
tracepath 203.0.113.10
```

Shows path and can help identify MTU information.

### `traceroute`

```bash
traceroute 203.0.113.10
```

May require installation and different probe modes.

### `curl`

```bash
curl -I https://example.com
curl -v http://192.0.2.25:8080/
```

Tests application-level connectivity.

### `nc`

```bash
nc -vz 192.0.2.25 22
```

Tests a TCP connection to a host and port.

UDP testing with `nc` is less conclusive because UDP has no handshake.

---

## 39. Packet Capture Awareness

Capture on an interface:

```bash
sudo tcpdump -ni enp1s0
```

SSH traffic:

```bash
sudo tcpdump -ni enp1s0 tcp port 22
```

Specific host:

```bash
sudo tcpdump -ni enp1s0 host 192.0.2.25
```

DNS:

```bash
sudo tcpdump -ni any port 53
```

Use packet capture responsibly:

- Obtain authorization.
- Limit interface, host, port, and duration.
- Protect captured data.
- Avoid collecting credentials or sensitive payloads.
- Delete captures according to policy.

Packet capture is covered more deeply in the Engineer II advanced networking module.

---

## 40. MTU and Path MTU

Display MTU:

```bash
ip link show dev enp1s0
```

Typical Ethernet MTU:

```text
1500
```

Symptoms of an MTU problem:

- Small connections work but large transfers stall.
- SSH connects but file transfer freezes.
- VPN or tunnel traffic behaves inconsistently.
- TLS handshake or application request stalls.

Tools:

```bash
tracepath DESTINATION
```

Controlled IPv4 test:

```bash
ping -c 4 -M do -s 1472 DESTINATION
```

For IPv4 Ethernet with 1500 MTU, 1472 bytes of payload plus 28 bytes of IPv4 and ICMP headers equals 1500. Tunnels and IPv6 change the calculation.

Do not change MTU until the complete path and platform requirements are understood.

---

## 41. Basic Firewall Awareness

Network reachability can be affected by:

- Host firewalld/nftables
- Cloud security group
- Cloud network ACL
- Router ACL
- Load balancer
- External firewall
- Application access control

Basic host checks:

```bash
sudo systemctl status firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
```

Do not disable the firewall as a first troubleshooting step.

Firewalld and SELinux are covered in Module 14.

---

## 42. A Layered Troubleshooting Workflow

### Layer 1 — Local Process and Configuration

```bash
systemctl status SERVICE
journalctl -u SERVICE
```

### Layer 2 — Listening Socket

```bash
sudo ss -lntup
```

### Layer 3 — Interface and Address

```bash
ip -br link
ip -br address
```

### Layer 4 — Route

```bash
ip route
ip route get DESTINATION
```

### Layer 5 — Neighbor and Gateway

```bash
ip neigh
ping -c 4 GATEWAY
```

### Layer 6 — DNS

```bash
getent hosts HOSTNAME
dig HOSTNAME
```

### Layer 7 — Port

```bash
nc -vz HOST PORT
curl -v URL
```

### Layer 8 — Security Policy

Check host firewall, SELinux, cloud rules, network ACLs, and upstream firewalls.

### Layer 9 — Packet Evidence

```bash
sudo tcpdump -ni any host DESTINATION
```

Do not jump randomly between layers. Preserve evidence.

---

## 43. Troubleshooting “IP Works, Name Fails”

Example:

```bash
ping -c 2 192.0.2.25
ping -c 2 app01.example.com
```

If IP works and name fails:

```bash
grep '^hosts:' /etc/nsswitch.conf
getent hosts app01.example.com
cat /etc/resolv.conf
nmcli device show
dig app01.example.com
dig @DNS_SERVER app01.example.com
```

Possible causes:

- Wrong DNS server
- DNS server unreachable
- Missing record
- Incorrect search domain
- Stale `/etc/hosts`
- VPN DNS priority
- Split-DNS issue
- IPv6 result selected but IPv6 path broken

---

## 44. Troubleshooting “Service Runs but Is Unreachable”

Check service:

```bash
systemctl status SERVICE
```

Check socket:

```bash
sudo ss -lntup
```

Ask:

- Is it listening on the expected port?
- Is it bound only to `127.0.0.1`?
- Is it listening only on IPv4 or only IPv6?
- Is the application healthy?
- Is the local firewall allowing the port?
- Is SELinux denying the operation?
- Is cloud or network policy allowing it?
- Does the return route exist?

Test locally:

```bash
curl -v http://127.0.0.1:PORT/
curl -v http://SERVER_IP:PORT/
```

Then test remotely.

---

## 45. Troubleshooting “Can Reach Gateway but Not Remote Network”

Inspect:

```bash
ip route
ip route get REMOTE_IP
tracepath REMOTE_IP
```

Check:

- Default or specific route
- Upstream router
- Network firewall
- NAT
- Remote route back to the source
- Asymmetric routing
- Source-address selection
- VPN or policy-routing rules

The return path matters as much as the forward path.

---

## 46. OpenSSH Components

OpenSSH includes:

| Component | Purpose |
|---|---|
| `ssh` | Remote shell and command client |
| `sshd` | SSH server daemon |
| `ssh-keygen` | Key generation and management |
| `ssh-agent` | Holds private keys in memory |
| `ssh-add` | Adds keys to an agent |
| `scp` | Secure copy over SSH |
| `sftp` | Secure file-transfer client |
| `ssh-keyscan` | Retrieves public host keys |

RHEL packages commonly include:

```text
openssh
openssh-clients
openssh-server
```

Check:

```bash
rpm -qa | grep '^openssh'
```

---

## 47. SSH Client Basics

Connect:

```bash
ssh user@server.example.com
```

Specific port:

```bash
ssh -p 2222 user@server.example.com
```

Run a command:

```bash
ssh user@server.example.com 'hostnamectl'
```

Verbose diagnosis:

```bash
ssh -vvv user@server.example.com
```

Use a specific identity:

```bash
ssh -i ~/.ssh/id_ed25519 user@server.example.com
```

Do not paste private keys into chat, tickets, repositories, or command output.

---

## 48. SSH Client Configuration

User configuration:

```text
~/.ssh/config
```

Example:

```sshconfig
Host app01
    HostName app01.example.com
    User admin
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Connect:

```bash
ssh app01
```

Permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

System-wide client configuration:

```text
/etc/ssh/ssh_config
/etc/ssh/ssh_config.d/*.conf
```

View effective client configuration:

```bash
ssh -G app01
```

---

## 49. SSH User Key Pairs

A key pair contains:

- Private key: remains protected on the client.
- Public key: installed on authorized servers.

Create an Ed25519 key:

```bash
ssh-keygen -t ed25519 -a 100 -C "admin-access"
```

Choose:

- A clear file path
- A strong passphrase
- A meaningful comment

Example files:

```text
~/.ssh/id_ed25519
~/.ssh/id_ed25519.pub
```

Never share the private key.

---

## 50. Installing a Public Key

If password login is allowed:

```bash
ssh-copy-id user@server.example.com
```

Specific public key:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server.example.com
```

The public key is normally placed in:

```text
~/.ssh/authorized_keys
```

Verify permissions on the server:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown -R "$USER":"$(id -gn)" ~/.ssh
```

The home directory and parent path must also not violate `sshd` ownership and permission checks.

---

## 51. SSH Key Permissions

Recommended client-side permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/known_hosts
```

Server-side:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Too-open private-key permissions can cause the SSH client to reject the key.

Incorrect ownership of `authorized_keys` can cause the server to ignore it.

---

## 52. SSH Agent

Start an agent in a shell:

```bash
eval "$(ssh-agent -s)"
```

Add a key:

```bash
ssh-add ~/.ssh/id_ed25519
```

List:

```bash
ssh-add -l
```

Remove:

```bash
ssh-add -d ~/.ssh/id_ed25519
```

Remove all:

```bash
ssh-add -D
```

Agent forwarding can expose authentication capability to a remote environment. Use it only when required and trusted.

---

## 53. Server Host Keys

Host keys identify the SSH server.

Common location:

```text
/etc/ssh/ssh_host_*_key
/etc/ssh/ssh_host_*_key.pub
```

List fingerprints:

```bash
sudo ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

Clients store trusted host keys in:

```text
~/.ssh/known_hosts
```

System-wide known hosts:

```text
/etc/ssh/ssh_known_hosts
```

### Host Key Warning

```text
REMOTE HOST IDENTIFICATION HAS CHANGED
```

Possible reasons:

- Server rebuilt
- IP or DNS now points to another server
- Host keys regenerated
- Load-balancer design issue
- Man-in-the-middle attack

Do not automatically delete the old key. Verify the new fingerprint through a trusted channel first.

---

## 54. Managing `sshd`

Check service:

```bash
sudo systemctl status sshd
```

Enable and start:

```bash
sudo systemctl enable --now sshd
```

Logs:

```bash
sudo journalctl -u sshd
sudo journalctl -u sshd -b
```

Listening socket:

```bash
sudo ss -lntp 'sport = :22'
```

Package files:

```bash
rpm -ql openssh-server
```

---

## 55. SSH Server Configuration

Main file:

```text
/etc/ssh/sshd_config
```

Drop-in directory:

```text
/etc/ssh/sshd_config.d/
```

Inspect active, non-comment settings:

```bash
sudo sshd -T
```

For a particular user, host, and address:

```bash
sudo sshd -T -C user=admin,host=app01,addr=192.0.2.50
```

This is important when `Match` blocks change effective settings.

---

## 56. Safe `sshd` Change Procedure

Before modifying:

1. Confirm console or out-of-band access.
2. Keep the current SSH session open.
3. Back up or version-control the approved configuration.
4. Use a drop-in where appropriate.
5. Validate syntax.
6. Reload, not blindly restart.
7. Test a new SSH session.
8. Verify logs and effective settings.
9. Close the original session only after success.

Validate:

```bash
sudo sshd -t
```

Show effective configuration:

```bash
sudo sshd -T
```

Reload:

```bash
sudo systemctl reload sshd
```

Verify:

```bash
sudo systemctl status sshd
sudo journalctl -u sshd --since "10 minutes ago"
sudo ss -lntp 'sport = :22'
```

---

## 57. Important `sshd` Directives

Example concepts:

```sshconfig
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
AllowGroups ssh-users
MaxAuthTries 4
LoginGraceTime 30
```

Do not copy these into production without confirming:

- Existing authentication method
- Automation accounts
- Break-glass access
- Identity-management integration
- Compliance standard
- RHEL crypto policies
- Required forwarding or subsystems

### Critical Lockout Warning

Do not disable password authentication until a tested public-key or enterprise authentication method works in a new session.

---

## 58. Restricting SSH Access

Examples:

```sshconfig
AllowUsers admin backup
```

```sshconfig
AllowGroups ssh-users
```

```sshconfig
DenyUsers former-admin
```

`Match` example:

```sshconfig
Match Group sftp-only
    ForceCommand internal-sftp
    X11Forwarding no
    AllowTcpForwarding no
```

Ordering and matching matter. Use:

```bash
sudo sshd -T -C user=USERNAME,host=HOSTNAME,addr=CLIENT_IP
```

to inspect effective settings for a connection context.

---

## 59. Root Login

Common secure design:

- Administrators authenticate as named users.
- Privileged commands use `sudo`.
- Direct root SSH login is disabled or tightly controlled.

Check effective setting:

```bash
sudo sshd -T | grep '^permitrootlogin'
```

Before changing:

- Confirm working named admin accounts.
- Confirm `sudo`.
- Confirm break-glass process.
- Confirm automation does not depend on root SSH.

Security changes must preserve an approved recovery path.

---

## 60. SSH and System-Wide Crypto Policies

RHEL applies system-wide cryptographic policies to services including OpenSSH.

Show current policy:

```bash
update-crypto-policies --show
```

Weak or obsolete clients may fail after policy hardening.

Do not lower the entire system policy merely to connect one legacy client. Identify:

- Required algorithms
- Business owner
- Risk acceptance
- Upgrade path
- Narrow supported exception, if permitted

Crypto-policy management is covered more deeply in the security modules.

---

## 61. SSH File Transfer

### `scp`

Upload:

```bash
scp local-file user@server:/remote/path/
```

Download:

```bash
scp user@server:/remote/file .
```

### `sftp`

```bash
sftp user@server
```

Common interactive commands:

```text
pwd
lpwd
ls
lls
get FILE
put FILE
exit
```

### `rsync` over SSH

If installed:

```bash
rsync -av --progress source/ user@server:/destination/
```

For important transfers:

- Verify destination capacity.
- Preserve required ownership and metadata.
- Use checksums when appropriate.
- Avoid trailing-slash mistakes.
- Protect sensitive data.

---

## 62. SSH Tunneling Awareness

Local forwarding:

```bash
ssh -L 8080:internal-app:80 user@jump-host
```

Then local port `8080` forwards through SSH to `internal-app:80`.

Remote forwarding:

```bash
ssh -R 9000:localhost:3000 user@remote-host
```

Dynamic SOCKS proxy:

```bash
ssh -D 1080 user@jump-host
```

Forwarding can bypass intended network controls. Use it only when authorized and monitored.

---

## 63. Jump Hosts

Connect through a bastion:

```bash
ssh -J admin@bastion.example.com admin@app01.internal
```

Client configuration:

```sshconfig
Host bastion
    HostName bastion.example.com
    User admin

Host app01
    HostName app01.internal
    User admin
    ProxyJump bastion
```

Do not copy private keys to a jump host. Prefer `ProxyJump` so authentication remains on the client.

---

## 64. SSH Failure: Timeout

Example:

```text
ssh: connect to host app01 port 22: Connection timed out
```

Investigate:

```bash
getent hosts app01
ip route get DESTINATION_IP
ping -c 4 DESTINATION_IP
nc -vz DESTINATION_IP 22
tracepath DESTINATION_IP
```

Server-side or network-team checks:

```bash
sudo ss -lntp 'sport = :22'
sudo firewall-cmd --list-all
sudo tcpdump -ni any tcp port 22
```

Likely areas:

- Route
- Security group
- Firewall drop
- Network ACL
- Server down
- Wrong IP
- Return-path failure

---

## 65. SSH Failure: Connection Refused

Example:

```text
ssh: connect to host app01 port 22: Connection refused
```

This often means the host was reached but:

- `sshd` is stopped.
- Nothing listens on that port.
- SSH uses another port.
- A firewall actively rejects.
- Service is bound to another address.

Server checks:

```bash
sudo systemctl status sshd
sudo ss -lntp
sudo journalctl -u sshd -b
sudo sshd -t
```

---

## 66. SSH Failure: Permission Denied

Examples:

```text
Permission denied (publickey).
Permission denied (publickey,password).
```

Client:

```bash
ssh -vvv -i ~/.ssh/id_ed25519 user@server
ssh-add -l
```

Server:

```bash
sudo journalctl -u sshd --since "10 minutes ago"
sudo sshd -T -C user=USER,host=SERVER,addr=CLIENT_IP
```

Check:

- Correct username
- Correct private key
- Key offered by client
- Public key in `authorized_keys`
- File ownership and permissions
- Home-directory permissions
- `AllowUsers` or `AllowGroups`
- Account locked or expired
- SELinux file contexts
- Authentication policy

---

## 67. SSH Failure: Host Key Changed

Do not immediately run:

```bash
ssh-keygen -R HOST
```

First:

1. Stop the connection.
2. Confirm whether the server was rebuilt or reassigned.
3. Obtain the new fingerprint from a trusted source or console.
4. Compare the fingerprint.
5. Remove the stale key only after verification.
6. Connect and store the verified new key.

After approval:

```bash
ssh-keygen -R app01.example.com
```

Security is the reason for the warning.

---

## 68. SSH Failure: Slow Login

Possible causes:

- Slow DNS or reverse DNS
- Identity provider delay
- GSSAPI or Kerberos issue
- PAM module delay
- Home directory or NFS delay
- Shell startup file problem
- Resource exhaustion

Measure:

```bash
time ssh -vvv user@server true
```

Server:

```bash
sudo journalctl -u sshd --since "10 minutes ago"
```

Compare:

- TCP connection time
- Key exchange time
- Authentication time
- Session startup time

Do not disable security features without proving the cause.

---

## 69. SSH and SELinux Awareness

SELinux can affect:

- Nonstandard SSH ports
- Home-directory contexts
- `authorized_keys`
- Chrooted SFTP
- Custom key locations

Check recent denials:

```bash
sudo ausearch -m AVC -ts recent
```

Check contexts:

```bash
ls -ldZ ~/.ssh
ls -lZ ~/.ssh/authorized_keys
```

Restore expected contexts:

```bash
sudo restorecon -Rv ~/.ssh
```

Do not disable SELinux as the solution. Identify and correct the labeling or policy issue.

---

## 70. Safe Network Namespace Lab

This lab creates two isolated network namespaces connected by a virtual Ethernet pair. It does not modify the host’s physical interface, default route, NetworkManager profiles, DNS, firewall, or SSH configuration.

### Requirements

RHEL-family tools:

```bash
sudo dnf install -y iproute iputils curl python3
```

### Create the Lab Script

Save this as:

```text
module10-network-lab.sh
```

```bash
#!/usr/bin/env bash

set -euo pipefail

lab_id="$$"
ns_a="m10a-${lab_id}"
ns_b="m10b-${lab_id}"
veth_a="m10a${lab_id}"
veth_b="m10b${lab_id}"
http_pid=""
log_file="/tmp/module10-http-${lab_id}.log"

cleanup() {
    if [[ -n "$http_pid" ]]; then
        sudo kill "$http_pid" 2>/dev/null || true
    fi

    sudo ip netns del "$ns_a" 2>/dev/null || true
    sudo ip netns del "$ns_b" 2>/dev/null || true
    rm -f "$log_file"
}

trap cleanup EXIT INT TERM

printf 'Creating namespaces: %s and %s\n' "$ns_a" "$ns_b"
sudo ip netns add "$ns_a"
sudo ip netns add "$ns_b"

printf 'Creating virtual Ethernet pair\n'
sudo ip link add "$veth_a" type veth peer name "$veth_b"

sudo ip link set "$veth_a" netns "$ns_a"
sudo ip link set "$veth_b" netns "$ns_b"

printf 'Assigning documentation-range addresses\n'
sudo ip -n "$ns_a" address add 192.0.2.1/24 dev "$veth_a"
sudo ip -n "$ns_b" address add 192.0.2.2/24 dev "$veth_b"

sudo ip -n "$ns_a" link set lo up
sudo ip -n "$ns_b" link set lo up
sudo ip -n "$ns_a" link set "$veth_a" up
sudo ip -n "$ns_b" link set "$veth_b" up

printf '\nNamespace A addresses\n'
sudo ip -n "$ns_a" -br address

printf '\nNamespace B addresses\n'
sudo ip -n "$ns_b" -br address

printf '\nRoutes\n'
sudo ip -n "$ns_a" route
sudo ip -n "$ns_b" route

printf '\nTesting ICMP from A to B\n'
sudo ip netns exec "$ns_a" ping -c 3 192.0.2.2

printf '\nNeighbor table after communication\n'
sudo ip -n "$ns_a" neigh

printf '\nStarting temporary HTTP server in namespace B\n'
sudo ip netns exec "$ns_b" \
    python3 -m http.server 8080 \
    --bind 192.0.2.2 \
    --directory /tmp >"$log_file" 2>&1 &
http_pid="$!"

sleep 1

printf '\nListening socket in namespace B\n'
sudo ip netns exec "$ns_b" ss -lntp 'sport = :8080'

printf '\nHTTP request from namespace A\n'
sudo ip netns exec "$ns_a" curl -fsS http://192.0.2.2:8080/ >/dev/null
printf 'HTTP test succeeded\n'

printf '\nKernel route decision in namespace A\n'
sudo ip -n "$ns_a" route get 192.0.2.2

printf '\nSimulating a missing connected route\n'
sudo ip -n "$ns_a" route del 192.0.2.0/24 dev "$veth_a"

if sudo ip netns exec "$ns_a" ping -c 1 -W 1 192.0.2.2; then
    printf 'Unexpected: ping still succeeded\n' >&2
    exit 1
else
    printf 'Expected failure observed\n'
fi

printf '\nRestoring the route\n'
sudo ip -n "$ns_a" route add 192.0.2.0/24 dev "$veth_a" src 192.0.2.1
sudo ip netns exec "$ns_a" ping -c 2 192.0.2.2

printf '\nFinal verification\n'
sudo ip -n "$ns_a" -s link show dev "$veth_a"
sudo ip -n "$ns_b" -s link show dev "$veth_b"
sudo ip -n "$ns_a" neigh
printf 'Module 10 lab completed successfully\n'
```

### Validate Script Syntax

```bash
bash -n module10-network-lab.sh
```

### Make Executable

```bash
chmod +x module10-network-lab.sh
```

### Run

```bash
./module10-network-lab.sh
```

### What the Lab Demonstrates

- Isolated network stacks
- Virtual Ethernet interfaces
- IPv4 address assignment
- Connected routes
- Neighbor resolution
- ICMP testing
- TCP listening sockets
- Application-level HTTP testing
- Route-failure simulation
- Cleanup through a shell trap

### Manual Cleanup Check

The script cleans up automatically. Confirm:

```bash
ip netns list
ip link show type veth
```

If a namespace from this exact lab remains, remove only its explicit name:

```bash
sudo ip netns delete NAMESPACE_NAME
```

Do not delete unrelated namespaces or virtual interfaces.

---

## 71. Optional Safe SSH Client Lab

This lab creates a separate key pair without changing the SSH server.

Create a lab directory:

```bash
mkdir -p "$HOME/module10-ssh-lab"
chmod 700 "$HOME/module10-ssh-lab"
```

Create a key:

```bash
ssh-keygen \
  -t ed25519 \
  -a 100 \
  -C "module10-lab" \
  -f "$HOME/module10-ssh-lab/id_ed25519"
```

Inspect public fingerprint:

```bash
ssh-keygen -lf "$HOME/module10-ssh-lab/id_ed25519.pub"
```

Inspect permissions:

```bash
stat -c '%A %a %n' "$HOME/module10-ssh-lab"/*
```

Show public key:

```bash
cat "$HOME/module10-ssh-lab/id_ed25519.pub"
```

Do not display the private key.

After practice, remove only the lab directory when no longer needed:

```bash
rm -f "$HOME/module10-ssh-lab/id_ed25519"
rm -f "$HOME/module10-ssh-lab/id_ed25519.pub"
rmdir "$HOME/module10-ssh-lab"
```

---

## 72. Production Scenario — Remote Static-IP Change

### Request

Change an application server from DHCP to static addressing.

### Before the Change

```bash
date
hostnamectl
nmcli device status
nmcli connection show
nmcli connection show --active
ip -br address
ip route
ip rule
cat /etc/resolv.conf
```

Confirm:

- Approved address and prefix
- Gateway
- DNS servers
- Search domains
- VLAN
- Duplicate-address check
- Network reservation
- Console access
- Application maintenance window
- Rollback profile

### Build Without Activating

Create a new profile and inspect it:

```bash
nmcli connection show NEW_PROFILE
```

### Activation and Validation

Under the approved window:

```bash
sudo nmcli connection up NEW_PROFILE
```

Validate:

```bash
ip -br address
ip route
ping -c 3 GATEWAY
getent hosts REQUIRED_HOST
nc -vz REQUIRED_SERVICE REQUIRED_PORT
```

Test a new SSH connection before closing the original.

---

## 73. Production Scenario — SSH Hardening

### Goal

Disable direct root login and require approved user authentication.

### Preconditions

- Named admin account exists.
- `sudo` works.
- Public-key authentication is tested.
- Break-glass access is documented.
- Automation dependencies are reviewed.
- Console access is available.

### Change Pattern

Create an approved drop-in:

```text
/etc/ssh/sshd_config.d/40-local-hardening.conf
```

Example:

```sshconfig
PermitRootLogin no
```

Validate:

```bash
sudo sshd -t
sudo sshd -T | grep '^permitrootlogin'
```

Reload:

```bash
sudo systemctl reload sshd
```

Test:

- New named-user session
- `sudo`
- Expected root denial
- Automation health
- Logs

Keep the original session until validation completes.

---

## 74. Production Scenario — Intermittent Connectivity

Collect time-correlated evidence:

```bash
date
ip -s link
ip neigh
ip route
ss -s
journalctl -u NetworkManager --since "30 minutes ago"
journalctl -k --since "30 minutes ago"
```

Controlled tests:

```bash
ping -D -c 20 GATEWAY
ping -D -c 20 REMOTE_IP
```

Look for:

- Link flaps
- RX/TX errors
- Duplicate IP
- Neighbor-table failures
- Route changes
- DHCP renewal
- Firewall session timeout
- Load balancer behavior
- Resource exhaustion
- MTU symptoms

“Intermittent” requires timestamps and repeated measurements.

---

## 75. Production Scenario — Port Reachable Locally Only

Server:

```bash
sudo ss -lntp 'sport = :PORT'
curl -v http://127.0.0.1:PORT/
curl -v http://SERVER_IP:PORT/
```

If loopback works but server IP fails:

- Check bind address.
- Check local policy.
- Check application virtual-host configuration.

If server IP works locally but remote client fails:

- Check host firewall.
- Check cloud or network policy.
- Check route and return route.
- Capture packets on the server.

---

## 76. Production Scenario — DNS Gives the Wrong Address

Compare:

```bash
getent ahosts app01.example.com
dig app01.example.com
dig @DNS_SERVER app01.example.com
grep app01 /etc/hosts
```

Check:

- `/etc/hosts` override
- DNS search suffix
- CNAME chain
- Split DNS
- Cache
- Multiple A/AAAA records
- Recent DNS change and TTL
- Load-balancer health

Do not change the host’s resolver globally until the authoritative data and expected result are confirmed.

---

## 77. Interview Questions and Model Answers

### 1. What is the difference between a MAC address and an IP address?

A MAC address identifies an interface on the local link. An IP address is a logical address used for communication across routed networks.

### 2. What does `/24` mean?

The first 24 bits identify the network. Its IPv4 netmask is `255.255.255.0`.

### 3. What is a default gateway?

It is the next-hop router used when no more specific route matches the destination.

### 4. How does Linux choose a route?

It uses routing rules and tables, preferring the longest matching prefix. Metrics help choose among otherwise comparable routes.

### 5. How do you see which route Linux will use?

Run `ip route get DESTINATION`.

### 6. What is the difference between an interface and a NetworkManager profile?

An interface is a network device. A profile is a saved set of configuration values that can be activated on a compatible device.

### 7. Are `ip address add` changes persistent?

Normally no. Use NetworkManager configuration for persistent RHEL settings.

### 8. How do you add a persistent static route with `nmcli`?

Use `nmcli connection modify PROFILE +ipv4.routes "PREFIX GATEWAY"`, reactivate or reapply the profile, and verify with `ip route`.

### 9. What is the difference between TCP and UDP?

TCP provides connection-oriented, ordered, reliable delivery. UDP sends independent datagrams without transport-level delivery guarantees.

### 10. What does “connection refused” usually mean?

The destination host was reached, but no service accepted the connection on that port or a policy actively rejected it.

### 11. What does an SSH timeout suggest?

A dropped or unreachable path, firewall or security policy, incorrect route, host outage, or return-path problem.

### 12. Why can a service be active but unreachable?

It may be bound to the wrong address or port, blocked by security policy, unhealthy at the application layer, or missing a return route.

### 13. How do you see listening ports and their processes?

Use `sudo ss -lntup`.

### 14. Why use `getent hosts` during DNS troubleshooting?

It follows the system’s Name Service Switch configuration and represents the resolver path applications commonly use.

### 15. What is the purpose of `ip neigh`?

It displays IPv4 ARP and IPv6 neighbor-discovery entries that map next-hop IP addresses to link-layer neighbors.

### 16. What is the difference between `0.0.0.0:8080` and `127.0.0.1:8080`?

`0.0.0.0` listens on all IPv4 interfaces. `127.0.0.1` listens only on local loopback.

### 17. What is an SSH host key?

It identifies the SSH server. Clients verify its fingerprint to detect unexpected server identity changes.

### 18. What is the difference between a user key and a host key?

A user key authenticates a client user. A host key authenticates the server to the client.

### 19. How do you validate SSH server configuration?

Use `sshd -t` for syntax and `sshd -T` for effective settings.

### 20. How do you avoid locking yourself out during SSH changes?

Confirm console access, keep the current session open, validate syntax, reload, and prove a second session and `sudo` before closing the first.

### 21. Why should you not ignore a changed-host-key warning?

It can indicate a rebuild or reassignment, but also a man-in-the-middle attack. Verify the new fingerprint through a trusted channel.

### 22. What can cause public-key authentication to fail?

Wrong user or key, bad ownership or permissions, missing public key, account policy, `AllowUsers`/`AllowGroups`, SELinux context, or crypto-policy incompatibility.

### 23. What is a jump host?

A controlled intermediary used to reach internal systems. OpenSSH `ProxyJump` can connect through it without copying private keys there.

### 24. What is asymmetric routing?

Forward and return traffic use different paths. It can break stateful firewalls, source validation, or troubleshooting assumptions.

### 25. What distinguishes Engineer II troubleshooting?

Engineer II maps every layer, preserves evidence, correlates both directions, understands dependencies, avoids high-risk shortcuts, coordinates teams, and documents root cause and prevention.

---

## 78. Quick Knowledge Check

1. Which command gives a brief interface and address view?
2. Which command shows the kernel’s route to one destination?
3. What is the netmask for `/26`?
4. What is the IPv6 loopback address?
5. Which table maps local next-hop IPs to link-layer neighbors?
6. Which command shows active NetworkManager profiles?
7. What does `+ipv4.routes` do?
8. Which command follows NSS hostname resolution?
9. Which command lists listening TCP and UDP sockets with processes?
10. What bind address means IPv4 loopback only?
11. Which SSH option provides maximum client debug output?
12. Which file stores a user’s authorized public keys?
13. What permission is commonly expected on a private key?
14. Which command validates `sshd` syntax?
15. Why must the original SSH session stay open during a change?

### Answers

1. `ip -br address`
2. `ip route get DESTINATION`
3. `255.255.255.192`
4. `::1`
5. Neighbor table, viewed with `ip neigh`
6. `nmcli connection show --active`
7. Adds a route without replacing the existing route list
8. `getent hosts HOSTNAME`
9. `sudo ss -lntup`
10. `127.0.0.1`
11. `-vvv`
12. `~/.ssh/authorized_keys`
13. `600`
14. `sshd -t`
15. It provides a recovery path while a second session verifies the new configuration

---

## 79. Engineer I vs. Engineer II Expectations

| Area | Engineer I | Engineer II |
|---|---|---|
| IP configuration | Reads and updates a profile | Plans remote changes, rollback, multi-interface behavior, and dependency validation |
| Routing | Understands connected and default routes | Diagnoses metrics, policy rules, asymmetric paths, and return routing |
| DNS | Tests records and configured resolvers | Correlates NSS, split DNS, priorities, caching, IPv4/IPv6 selection, and application behavior |
| Sockets | Finds listening ports | Correlates bind address, process, firewall, SELinux, load balancer, and packet path |
| NetworkManager | Uses common `nmcli` commands | Reviews profile lifecycle, live reapply limits, automation, and outage risk |
| SSH | Configures keys and checks `sshd` | Plans hardening without lockout, analyzes effective policy, crypto, PAM, and automation impact |
| Troubleshooting | Follows a checklist | Forms and tests hypotheses using time-correlated evidence |
| Change management | Executes approved steps | Designs implementation, validation, rollback, communication, and evidence |
| Leadership | Escalates cross-team issues | Coordinates network, cloud, security, identity, and application teams |

---

## 80. Module Completion Checklist

- [ ] I can explain MAC, IP, port, and socket.
- [ ] I can interpret common IPv4 prefixes.
- [ ] I understand a default gateway.
- [ ] I can use `ip route get`.
- [ ] I can inspect IPv6 addresses and routes.
- [ ] I can read the neighbor table.
- [ ] I understand devices versus NetworkManager profiles.
- [ ] I can create a DHCP profile.
- [ ] I can create a static profile safely.
- [ ] I can add persistent DNS and routes.
- [ ] I can inspect hostname-resolution order.
- [ ] I can distinguish TCP and UDP.
- [ ] I can identify listening sockets.
- [ ] I can troubleshoot by layers.
- [ ] I can create and protect an SSH key.
- [ ] I understand host-key verification.
- [ ] I can validate `sshd` configuration.
- [ ] I can explain timeout versus refusal.
- [ ] I completed the network-namespace lab.
- [ ] I can answer all interview questions without notes.

---

## 81. Command Revision Sheet

### Interfaces and Addresses

```bash
ip -br link
ip -br address
ip -s link
nmcli device status
nmcli device show INTERFACE
```

### Routes and Neighbors

```bash
ip route
ip -6 route
ip route get DESTINATION
ip rule
ip neigh
```

### NetworkManager

```bash
nmcli general status
nmcli connection show
nmcli connection show --active
nmcli connection show PROFILE
sudo nmcli connection up PROFILE
sudo nmcli device reapply INTERFACE
```

### DNS

```bash
grep '^hosts:' /etc/nsswitch.conf
getent hosts HOSTNAME
cat /etc/resolv.conf
resolvectl status
dig HOSTNAME
dig @DNS_SERVER HOSTNAME
```

### Connectivity and Sockets

```bash
ping -c 4 HOST
tracepath HOST
nc -vz HOST PORT
curl -v URL
sudo ss -lntup
sudo tcpdump -ni any host HOST
```

### SSH

```bash
ssh user@host
ssh -vvv user@host
ssh-keygen -t ed25519 -a 100
ssh-copy-id user@host
ssh -G HOST
sudo sshd -t
sudo sshd -T
sudo systemctl status sshd
sudo journalctl -u sshd
```

---

## 82. Official References

Verify production behavior against the documentation and man pages for the installed RHEL release:

- [RHEL 9 — Configuring and Managing Networking](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_networking/index)
- [RHEL 9 — Using Secure Communications Between Two Systems with OpenSSH](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/securing_networks/assembly_using-secure-communications-between-two-systems-with-openssh_securing-networks)
- `man ip`
- `man nmcli`
- `man NetworkManager`
- `man ss`
- `man ssh`
- `man ssh_config`
- `man sshd`
- `man sshd_config`

---

## Shared Linux Foundation Milestone

You have now completed Modules 01–10:

1. Linux architecture
2. Filesystem hierarchy
3. Users, groups, and `sudo`
4. Permissions, ACLs, and special bits
5. Processes, jobs, signals, and resources
6. systemd services and boot
7. RPM, DNF, and repositories
8. Filesystems, mounts, and swap
9. LVM administration and storage expansion
10. Linux networking and SSH

The next layer begins the **Linux Systems Engineer I** track.

## Next Module

**Module 11 — Centralized Logging and Log Analysis**

Topics will include:

- Journald architecture and persistent storage
- `journalctl` filtering and boot history
- rsyslog facilities, priorities, and rules
- Local and remote log forwarding
- Log rotation and retention awareness
- Authentication, kernel, service, and audit logs
- Time correlation across systems
- Common logging failures
- Production incident evidence
- Engineer I troubleshooting scenarios and interview questions
