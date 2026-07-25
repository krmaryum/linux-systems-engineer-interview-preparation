# Module 10 — Linux Networking and SSH

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module builds the networking foundation required for Linux support: interfaces, IPv4 and IPv6, CIDR, gateways, routing, neighbor discovery, DNS resolution, ports, sockets, NetworkManager, connectivity troubleshooting, and secure remote administration with OpenSSH.

## Learning Objectives

After completing this module, you should be able to:

- Explain how a Linux host communicates locally and across routed networks.
- Interpret IPv4 addresses, subnet prefixes, default gateways, and routes.
- Recognize essential IPv6 address types and commands.
- Inspect interfaces, addresses, neighbors, routes, sockets, and DNS settings.
- Distinguish a NetworkManager device from a connection profile.
- Configure and safely activate DHCP or static connection profiles with `nmcli`.
- Add persistent DNS servers and static routes.
- Troubleshoot connectivity layer by layer.
- Explain TCP, UDP, ports, listening sockets, and established sessions.
- Configure SSH client aliases and key-based authentication.
- Validate SSH server configuration before reload.
- Diagnose SSH failures without locking out remote access.
- Demonstrate Engineer II-level change planning and evidence collection.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Network communication model
- IPv4, CIDR, subnets, gateways, and routes
- IPv6 fundamentals
- Interfaces, addresses, neighbor tables, and sockets
- NetworkManager devices and connection profiles
- DHCP and static `nmcli` configuration
- DNS and hostname resolution
- TCP and UDP troubleshooting
- OpenSSH client and server administration
- SSH keys, host keys, permissions, and hardening
- Safe network-namespace lab
- SSH troubleshooting decision tree
- Production scenarios and interview questions

## Key Commands

```bash
ip -br link
ip -br address
ip route
ip -6 route
ip neigh
nmcli device status
nmcli connection show
nmcli connection show --active
resolvectl status
getent hosts HOSTNAME
ss -lntup
ping -c 4 HOST
tracepath HOST
ssh -vvv USER@HOST
sshd -t
systemctl status sshd
journalctl -u sshd
```

## Practical Outcome

You will build two isolated Linux network namespaces connected by a virtual Ethernet pair, assign addresses, test neighbor discovery and routing, run a temporary web service, inspect TCP sockets, simulate a broken route, repair it, and clean up without changing the host’s production network configuration.

## Completion Requirement

Complete the namespace lab and explain how you would diagnose:

1. A server with an IP address but no gateway reachability.
2. An application reachable by IP but not by hostname.
3. A service process running but not accepting remote connections.
4. SSH timing out versus SSH returning “connection refused.”
5. SSH public-key authentication failing after a configuration change.

## Navigation

- [Previous: Module 09 — LVM Administration and Storage Expansion](../module-09-lvm-administration-storage-expansion/README.md)
- Next: Module 11 — Centralized Logging and Log Analysis
