# Module 01 — Linux Architecture and System Identification

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module introduces the Linux architecture and the commands used to identify and assess a Linux system. It explains the relationship between hardware, the kernel, system libraries, services, the shell, and user applications.

## Learning Objectives

After completing this module, you should be able to:

- Explain the main layers of Linux architecture.
- Describe the responsibilities of the Linux kernel.
- Identify the RHEL release and running kernel.
- Gather CPU, memory, storage, networking, and uptime information.
- Determine whether a server is physical, virtual, or cloud-hosted.
- Identify failed services and important boot errors.
- Perform an initial system-health assessment.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Linux architecture and kernel concepts
- Essential system-identification commands
- Physical and virtual server identification
- System-health investigation
- Hands-on system-report lab
- Tier III troubleshooting scenario
- Interview questions and answer key
- Revision checklist

## Key Commands

```bash
cat /etc/redhat-release
cat /etc/os-release
uname -r
hostnamectl
lscpu
free -h
lsblk
df -hT
ip -br address
uptime
systemctl --failed
journalctl -p err -b
systemd-detect-virt
```

## Practical Outcome

You will create a Bash-based system-identification report and explain how you would investigate a slow Linux production server without immediately restarting it.

## Completion Requirement

Complete the practical lab, answer the interview questions aloud, and finish the checklist in the study notes before moving to Module 02.

## Next Module

[Module 02 — Linux Filesystem Hierarchy and File Management](../module-02-filesystem-hierarchy/README.md)
