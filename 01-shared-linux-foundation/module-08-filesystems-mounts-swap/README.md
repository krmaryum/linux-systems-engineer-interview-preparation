# Module 08 — Partitions, Filesystems, Mounts, and Swap

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains Linux block devices, partition tables, filesystems, persistent mounts, `/etc/fstab`, XFS and ext4 administration, filesystem checks, disk and inode usage, swap, and safe storage expansion.

## Learning Objectives

After completing this module, you should be able to:

- Identify disks, partitions, filesystems, UUIDs, labels, and mount points.
- Explain GPT versus MBR partition tables.
- Distinguish a block device, partition, filesystem, and mount point.
- Create and mount XFS and ext4 filesystems safely.
- Build and validate persistent `/etc/fstab` entries.
- Explain important mount options.
- Investigate full filesystems, inode exhaustion, and busy mounts.
- Perform appropriate XFS and ext4 checks.
- Create, enable, inspect, and disable swap.
- Explain the safe workflow for expanding storage.
- Troubleshoot missing devices, read-only filesystems, and emergency-mode mount failures.

## Module Contents

- [Complete Study Notes](study-notes.md)
- Linux storage layers
- Block-device naming and discovery
- GPT and MBR partitioning
- XFS and ext4
- Mounting and unmounting
- UUIDs, labels, and `/etc/fstab`
- Mount options and systemd integration
- Capacity and inode troubleshooting
- Filesystem checks and repair safety
- Swap administration
- Storage-expansion workflow
- Safe file-backed loop-device lab
- Production scenarios and interview questions

## Key Commands

```bash
lsblk -f
blkid
findmnt
fdisk -l
parted -l
mkfs.xfs DEVICE
mkfs.ext4 DEVICE
mount DEVICE MOUNTPOINT
umount MOUNTPOINT
findmnt --verify
df -hT
df -i
du -xhd1 /path
swapon --show
free -h
mkswap DEVICE
swapon DEVICE
swapoff DEVICE
```

## Practical Outcome

You will create a file-backed virtual disk, attach it to a loop device, create a GPT partition table, format an XFS filesystem, create swap, mount and test the filesystem, and clean up without touching a real disk.

## Completion Requirement

Complete the loop-device lab and explain how you would investigate a full filesystem, a busy mount, and a server entering emergency mode because of `/etc/fstab`.

## Navigation

- [Previous: Module 07 — RPM, DNF, Repositories, and Software Management](../module-07-rpm-dnf-repositories/README.md)
- Next: Module 09 — LVM Administration and Storage Expansion
