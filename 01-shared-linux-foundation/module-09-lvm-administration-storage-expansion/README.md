# Module 09 — LVM Administration and Storage Expansion

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux

## Overview

This module explains Linux Logical Volume Manager architecture and operations: physical volumes, volume groups, logical volumes, extents, discovery, creation, online expansion, adding and evacuating disks, snapshots, metadata backup, safe removal, and production troubleshooting.

## Learning Objectives

After completing this module, you should be able to:

- Explain the PV, VG, LV, device-mapper, filesystem, and mount layers.
- Discover LVM objects and trace them to physical devices.
- Create an LVM stack safely.
- Extend a logical volume and grow XFS or ext4.
- Add a new disk or partition to an existing volume group.
- Expand a physical volume after its backing device grows.
- Move allocated extents away from a physical volume with `pvmove`.
- Remove an unused physical volume safely.
- Explain standard snapshots and thin provisioning.
- Back up and inspect LVM metadata.
- Troubleshoot inactive volumes, missing PVs, full VGs, and failed expansions.
- Describe Engineer II planning, validation, rollback, and change-control expectations.

## Module Contents

- [Complete Study Notes](study-notes.md)
- LVM architecture and device mapper
- Physical and logical extents
- PV, VG, and LV discovery
- LVM creation workflow
- XFS and ext4 online growth
- New-disk and grown-disk expansion workflows
- `pvmove` and safe PV removal
- Standard snapshots and thin provisioning
- Metadata backup and recovery concepts
- Safe LV, VG, and PV removal
- Production troubleshooting scenarios
- Safe file-backed LVM lab
- Interview questions and Engineer I/II expectations

## Key Commands

```bash
pvs
vgs
lvs
pvdisplay
vgdisplay
lvdisplay
lsblk -f
dmsetup ls --tree
pvcreate DEVICE
vgcreate VG_NAME DEVICE
lvcreate -L SIZE -n LV_NAME VG_NAME
vgextend VG_NAME DEVICE
lvextend -L +SIZE /dev/VG_NAME/LV_NAME
xfs_growfs MOUNTPOINT
resize2fs /dev/VG_NAME/LV_NAME
pvresize DEVICE
pvmove DEVICE
vgreduce VG_NAME DEVICE
vgcfgbackup VG_NAME
```

## Practical Outcome

You will build an isolated LVM environment on file-backed loop devices, create an XFS logical volume, extend it, add a second PV, move extents between PVs, create and remove a snapshot, verify metadata backups, and clean up without touching a real disk.

## Completion Requirement

Complete the lab and explain how you would safely handle:

1. A filesystem that needs more capacity.
2. A cloud disk that was enlarged but still shows the old LVM size.
3. A physical volume that must be removed from a volume group.
4. An inactive logical volume after reboot.
5. A volume group with insufficient free extents.

## Navigation

- [Previous: Module 08 — Partitions, Filesystems, Mounts, and Swap](../module-08-filesystems-mounts-swap/README.md)
- Next: Module 10 — Boot Process, GRUB2, systemd Targets, and Recovery

