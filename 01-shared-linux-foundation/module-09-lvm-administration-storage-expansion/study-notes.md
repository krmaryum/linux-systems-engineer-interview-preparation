# Linux Systems Engineer II Interview Preparation

## Module 09 — LVM Administration and Storage Expansion

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 120 minutes

> **Critical safety warning:** `pvcreate`, `vgremove`, `lvremove`, `pvremove`, filesystem creation, and incorrect resize operations can permanently destroy data. In production, positively identify every device, verify backups and rollback, inspect mounts and application dependencies, obtain change approval, and test the exact procedure before making changes.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain why LVM is used in enterprise Linux.
- Describe physical volumes, volume groups, and logical volumes.
- Explain physical extents and logical extents.
- Trace a mounted path through the filesystem, LV, VG, PV, and backing disk.
- Create and inspect a basic LVM storage stack.
- Add storage to an existing volume group.
- Extend a logical volume.
- Grow XFS and ext4 filesystems safely.
- Distinguish a grown disk from a newly added disk.
- Resize a PV after its underlying device grows.
- Move allocated extents between PVs.
- Remove an unused PV from a volume group.
- Explain snapshots, thin pools, and thin volumes.
- Back up LVM metadata.
- Troubleshoot common LVM failures.
- Plan storage changes using Engineer II-level controls.

---

## 2. Why LVM Exists

Traditional storage connects a filesystem directly to a partition:

```text
Disk → Partition → Filesystem → Mount point
```

LVM inserts a flexible abstraction layer:

```text
Disk or partition
        ↓
Physical volume (PV)
        ↓
Volume group (VG)
        ↓
Logical volume (LV)
        ↓
Filesystem
        ↓
Mount point
```

This makes it easier to:

- Combine capacity from multiple devices.
- Allocate logical volumes based on application needs.
- Extend volumes when demand grows.
- Move allocated data between physical devices.
- Create snapshots.
- Build thin-provisioned storage.
- Change the physical layout without changing application paths.

LVM does not replace:

- Backups
- Filesystems
- RAID
- Multipath
- Encryption
- Storage monitoring
- Change management

It can work with these technologies as part of a larger storage stack.

---

## 3. The Three Core LVM Objects

### 3.1 Physical Volume — PV

A physical volume is a block device initialized for LVM.

Examples:

```text
/dev/sdb
/dev/sdc1
/dev/nvme1n1
/dev/mapper/mpatha
/dev/mapper/cryptdata
```

Create a PV:

```bash
sudo pvcreate /dev/DEVICE
```

> `pvcreate` writes LVM metadata to the target. Never run it on an unknown or in-use device.

### 3.2 Volume Group — VG

A volume group is a storage pool formed from one or more PVs.

Example:

```text
/dev/sdb1 ─┐
           ├── vg_app
/dev/sdc1 ─┘
```

Create:

```bash
sudo vgcreate vg_app /dev/sdb1
```

Add another PV:

```bash
sudo vgextend vg_app /dev/sdc1
```

### 3.3 Logical Volume — LV

A logical volume is allocated from free space in a VG. It behaves like a block device.

Create:

```bash
sudo lvcreate -L 10G -n lv_data vg_app
```

Common device paths:

```text
/dev/vg_app/lv_data
/dev/mapper/vg_app-lv_data
```

These normally refer to the same device-mapper device.

---

## 4. LVM Architecture at a Glance

```text
Physical devices
  /dev/sdb1                 /dev/sdc1
      │                         │
      ▼                         ▼
Physical volumes
      PV1                       PV2
       └───────────┬────────────┘
                   ▼
             Volume group
                vg_app
          ┌────────┴─────────┐
          ▼                  ▼
     lv_data              lv_logs
          │                  │
          ▼                  ▼
         XFS                ext4
          │                  │
          ▼                  ▼
        /data              /logs
```

### Interview Answer

> A PV is an LVM-initialized block device. A VG pools one or more PVs. An LV is a virtual block device allocated from the VG. A filesystem is created on the LV and mounted for application use.

---

## 5. Physical and Logical Extents

LVM allocates space in fixed-size units called extents.

- **Physical extent (PE):** allocation unit on a PV.
- **Logical extent (LE):** corresponding allocation unit in an LV.

View the VG extent size:

```bash
sudo vgdisplay vg_app
```

Typical default:

```text
PE Size 4.00 MiB
```

If the extent size is 4 MiB:

```text
256 extents = 1 GiB
```

Use extents when creating or extending:

```bash
sudo lvcreate -l 100%FREE -n lv_data vg_app
```

```bash
sudo lvextend -l +100%FREE /dev/vg_app/lv_data
```

### Important Difference

Uppercase `-L` means a size:

```bash
-L 10G
-L +5G
```

Lowercase `-l` means a number or percentage of extents:

```bash
-l 500
-l 50%VG
-l +100%FREE
```

---

## 6. Device Mapper

LVM uses the Linux device-mapper framework.

Inspect mappings:

```bash
sudo dmsetup ls
```

Tree view:

```bash
sudo dmsetup ls --tree
```

Inspect a specific device:

```bash
sudo dmsetup info /dev/mapper/vg_app-lv_data
```

Helpful relationships:

```bash
lsblk
```

```bash
lsblk -o NAME,KNAME,PKNAME,TYPE,SIZE,FSTYPE,MOUNTPOINTS
```

The friendly path:

```text
/dev/vg_app/lv_data
```

ultimately maps to a device such as:

```text
/dev/dm-2
```

Use the stable LVM path in administration and `/etc/fstab`, not `/dev/dm-2`, because the numeric device-mapper name can change.

---

## 7. LVM Discovery Commands

### 7.1 Summary Commands

```bash
sudo pvs
sudo vgs
sudo lvs
```

Useful columns:

```bash
sudo pvs -o pv_name,vg_name,pv_size,pv_free,pv_used,pv_uuid
```

```bash
sudo vgs -o vg_name,pv_count,lv_count,vg_size,vg_free,vg_uuid
```

```bash
sudo lvs -o lv_name,vg_name,lv_size,lv_attr,segtype,devices
```

### 7.2 Detailed Commands

```bash
sudo pvdisplay
sudo vgdisplay
sudo lvdisplay
```

Specific object:

```bash
sudo pvdisplay /dev/sdb1
sudo vgdisplay vg_app
sudo lvdisplay /dev/vg_app/lv_data
```

### 7.3 Full Report

```bash
sudo lvm fullreport
```

### 7.4 JSON Output

Useful for automation:

```bash
sudo pvs --reportformat json
sudo vgs --reportformat json
sudo lvs --reportformat json
```

Avoid parsing human-readable column spacing when structured output is available.

### 7.5 Filesystem and Mount Correlation

```bash
lsblk -f
findmnt
df -hT
blkid
```

An Engineer II correlates all layers instead of looking at only `df` or only `lvs`.

---

## 8. Understanding `lvs` Attributes

Run:

```bash
sudo lvs -a -o lv_name,vg_name,lv_attr,lv_size,segtype,origin,pool_lv,data_percent,metadata_percent,devices
```

The `Attr` field contains compact status flags.

Examples may indicate:

- LV type
- Permissions
- Allocation policy
- Activation state
- Open state
- Health

Because positions vary by object type and LVM version, use:

```bash
man lvs
```

Do not memorize a single attribute string without understanding the report columns.

---

## 9. Creating an LVM Stack Safely

Assume an authorized empty device:

```text
/dev/sdb1
```

### Step 1 — Verify the Device

```bash
lsblk -f /dev/sdb
sudo blkid /dev/sdb1
sudo wipefs -n /dev/sdb1
findmnt -S /dev/sdb1
sudo pvs
```

`wipefs -n` inspects signatures without writing.

### Step 2 — Create the PV

```bash
sudo pvcreate /dev/sdb1
```

### Step 3 — Create the VG

```bash
sudo vgcreate vg_app /dev/sdb1
```

### Step 4 — Create the LV

```bash
sudo lvcreate -L 10G -n lv_data vg_app
```

### Step 5 — Create the Filesystem

For XFS:

```bash
sudo mkfs.xfs /dev/vg_app/lv_data
```

For ext4:

```bash
sudo mkfs.ext4 /dev/vg_app/lv_data
```

### Step 6 — Create the Mount Point

```bash
sudo mkdir -p /data
```

### Step 7 — Mount

```bash
sudo mount /dev/vg_app/lv_data /data
```

### Step 8 — Verify

```bash
findmnt /data
df -hT /data
lsblk -f
sudo pvs
sudo vgs
sudo lvs
```

### Step 9 — Configure Persistence

Obtain the filesystem UUID:

```bash
sudo blkid /dev/vg_app/lv_data
```

Example `/etc/fstab` entry:

```fstab
UUID=FILESYSTEM_UUID /data xfs defaults 0 0
```

Validate before reboot:

```bash
sudo findmnt --verify
sudo mount -a
findmnt /data
```

---

## 10. LVM Naming Rules

Use names that describe purpose:

```text
VG: vg_app
LV: lv_data
LV: lv_logs
LV: lv_backup
```

Good practices:

- Follow the organization’s naming standard.
- Avoid spaces.
- Use lowercase names if that is the standard.
- Keep names short but meaningful.
- Do not embed temporary details that will become false.
- Avoid names that look like device names.

Remember that hyphens are escaped in `/dev/mapper`.

Example:

```text
VG: vg-app
LV: lv-data
Mapper path: /dev/mapper/vg--app-lv--data
```

The path `/dev/vg-app/lv-data` is easier to read.

---

## 11. Capacity at Every Layer

A path can appear full even when another layer has free space.

Inspect:

```bash
df -hT /data
sudo lvs
sudo vgs
sudo pvs
lsblk
```

Questions:

1. Is the filesystem full?
2. Is the LV larger than the filesystem?
3. Does the VG have free extents?
4. Does the PV have unused capacity already recognized by LVM?
5. Did the underlying disk grow?
6. Is there another device available to add?

### Example

```text
Disk: 200 GiB
PV:   200 GiB
VG:   200 GiB, 80 GiB free
LV:   120 GiB
XFS:  120 GiB
```

The LV and filesystem can grow by up to 80 GiB without adding a disk.

Another example:

```text
Cloud disk: 300 GiB
Partition:  200 GiB
PV:         200 GiB
VG free:      0 GiB
```

The cloud disk grew, but the partition and PV have not yet been expanded.

---

## 12. Safe Expansion Planning

Before changing storage:

- Confirm the exact affected path.
- Identify the application owner.
- Review current growth and forecast.
- Confirm the requested target size.
- Map every storage layer.
- Check backups and recovery.
- Verify storage-provider or hypervisor completion.
- Check VG free capacity.
- Check filesystem type.
- Confirm whether downtime is required.
- Review monitoring and alert thresholds.
- Record before-state outputs.
- Define verification and rollback.
- Obtain approval.

Before-state collection:

```bash
date
hostnamectl
findmnt /data
df -hT /data
df -i /data
lsblk -f
sudo pvs
sudo vgs
sudo lvs -a -o +devices
sudo vgcfgbackup
```

> An LVM metadata backup does not back up application data or filesystem contents.

---

## 13. Extending an LV When the VG Has Free Space

Assume:

```text
VG: vg_app
LV: lv_data
Mount: /data
Filesystem: XFS
VG free: 20 GiB
Requested growth: 5 GiB
```

### Step 1 — Verify

```bash
findmnt /data
df -hT /data
sudo lvs /dev/vg_app/lv_data
sudo vgs vg_app
```

### Step 2 — Extend the LV

```bash
sudo lvextend -L +5G /dev/vg_app/lv_data
```

The plus sign matters:

```text
-L +5G = add 5 GiB
-L 5G  = set final LV size to 5 GiB
```

### Step 3 — Grow XFS

XFS is grown using its mounted path:

```bash
sudo xfs_growfs /data
```

### Step 4 — Verify

```bash
sudo lvs /dev/vg_app/lv_data
df -hT /data
xfs_info /data
```

---

## 14. Extending an ext4 Filesystem

Extend the LV:

```bash
sudo lvextend -L +5G /dev/vg_app/lv_data
```

Grow ext4 using the block-device path:

```bash
sudo resize2fs /dev/vg_app/lv_data
```

Verify:

```bash
sudo lvs /dev/vg_app/lv_data
df -hT /data
```

Modern ext4 filesystems commonly support online growth while mounted. Validate the environment and supported procedure before production use.

---

## 15. Using `lvextend --resizefs`

LVM can call the appropriate filesystem resize helper:

```bash
sudo lvextend --resizefs -L +5G /dev/vg_app/lv_data
```

Short form:

```bash
sudo lvextend -r -L +5G /dev/vg_app/lv_data
```

Advantages:

- One coordinated command
- Reduces the chance of forgetting filesystem growth

Engineer II considerations:

- Confirm that the filesystem is supported by `fsadm` or the invoked helper.
- Read the proposed change carefully.
- Capture output and exit status.
- Verify both LV and filesystem size afterward.
- Separate the steps when the change procedure requires granular control.

---

## 16. Percentage-Based Extension

Use all remaining free extents:

```bash
sudo lvextend -l +100%FREE /dev/vg_app/lv_data
```

With filesystem resize:

```bash
sudo lvextend -r -l +100%FREE /dev/vg_app/lv_data
```

Production caution:

Using all free space may leave no emergency capacity for:

- Other LVs
- Snapshot data
- Metadata
- Unexpected growth
- Recovery operations

A better plan may reserve capacity.

---

## 17. Adding a New Device to a VG

Assume a new, authorized device:

```text
/dev/sdc1
```

### Step 1 — Verify It Is the Correct Empty Device

```bash
lsblk -f /dev/sdc
sudo blkid /dev/sdc1
sudo wipefs -n /dev/sdc1
findmnt -S /dev/sdc1
sudo pvs
```

### Step 2 — Create a PV

```bash
sudo pvcreate /dev/sdc1
```

### Step 3 — Add It to the VG

```bash
sudo vgextend vg_app /dev/sdc1
```

### Step 4 — Verify

```bash
sudo pvs
sudo vgs vg_app
sudo vgdisplay vg_app
```

### Step 5 — Extend LV and Filesystem

XFS example:

```bash
sudo lvextend -L +20G /dev/vg_app/lv_data
sudo xfs_growfs /data
```

Or:

```bash
sudo lvextend -r -L +20G /dev/vg_app/lv_data
```

---

## 18. Growing an Existing Disk or Partition

This is different from adding a new disk.

Possible stack:

```text
Cloud volume → NVMe disk → partition → PV → VG → LV → XFS
```

Correct order:

1. Expand the cloud, SAN, hypervisor, or hardware device.
2. Rescan so Linux sees the new device size.
3. Grow the partition, if a partition is used.
4. Run `pvresize`.
5. Extend the LV.
6. Grow the filesystem.
7. Verify every layer.

### Rescan Examples

The exact method depends on the platform.

SCSI host scan example:

```bash
echo "- - -" | sudo tee /sys/class/scsi_host/hostN/scan
```

Block-device rescan example, if supported:

```bash
echo 1 | sudo tee /sys/class/block/DEVICE/device/rescan
```

Verify:

```bash
lsblk
sudo blockdev --getsize64 /dev/DEVICE
```

Do not copy a rescan command blindly. Identify the correct host and device for the environment.

### Grow a Partition

One common tool:

```bash
sudo growpart /dev/DEVICE PARTITION_NUMBER
```

Example:

```bash
sudo growpart /dev/nvme1n1 1
```

Verify:

```bash
lsblk /dev/nvme1n1
```

### Resize the PV

```bash
sudo pvresize /dev/nvme1n1p1
```

Verify:

```bash
sudo pvs
sudo vgs
```

### Extend LV and Filesystem

```bash
sudo lvextend -r -L +50G /dev/vg_app/lv_data
```

Final validation:

```bash
lsblk -f
sudo pvs
sudo vgs
sudo lvs
df -hT /data
```

---

## 19. Whole-Disk PV vs. Partition PV

Both designs exist:

```text
/dev/sdb   as a PV
```

```text
/dev/sdb1  as a PV
```

### Whole-Disk PV

Advantages:

- Fewer layers
- Simple expansion

Considerations:

- Organization or platform standards may require partitioning.
- Partition tables can make device purpose clearer to some tools and teams.

### Partition PV

Advantages:

- Fits partition-based standards.
- Can use a GPT partition type indicating Linux LVM.

Considerations:

- Expansion includes a partition-growth step.
- More layers to troubleshoot.

Follow the environment’s standard consistently.

---

## 20. `pvresize`

After an underlying device or partition becomes larger:

```bash
sudo pvresize /dev/DEVICE
```

This tells LVM to recognize the new size.

Preview current size:

```bash
sudo pvs -o pv_name,pv_size,pv_free,dev_size
```

The important comparison:

```text
DevSize > PSize
```

may indicate that the backing device is larger than the LVM PV.

Never use a smaller `--setphysicalvolumesize` casually. Reducing a PV size incorrectly can make allocated extents inaccessible.

---

## 21. Mapping LV Extents to PVs

Show devices used by each LV:

```bash
sudo lvs -o lv_name,vg_name,lv_size,segtype,devices
```

Show physical segments:

```bash
sudo pvs --segments
```

Detailed:

```bash
sudo pvs --segments -o pv_name,vg_name,pvseg_start,pvseg_size,lv_name,seg_start_pe
```

This is important when:

- Retiring a disk
- Investigating uneven allocation
- Planning `pvmove`
- Understanding striped or RAID LVs
- Confirming whether a PV is empty

---

## 22. Moving Data with `pvmove`

`pvmove` relocates allocated extents from one PV to other suitable PVs in the same VG.

### Check Current Allocation

```bash
sudo pvs -o pv_name,vg_name,pv_size,pv_used,pv_free
sudo lvs -o lv_name,vg_name,devices
```

### Move All Allocated Extents Away

```bash
sudo pvmove /dev/sdb1
```

### Move to a Specific Destination PV

```bash
sudo pvmove /dev/sdb1 /dev/sdc1
```

### Monitor

```bash
sudo pvmove --interval 5 /dev/sdb1
```

Or in another terminal:

```bash
watch -n 5 'sudo pvs; sudo lvs -o +devices'
```

### Requirements

- Enough suitable free extents must exist on destination PVs.
- Source and destination must be in the same VG.
- The storage must remain healthy.
- Performance impact must be considered.
- The operation may take a long time.

Do not interrupt, reboot, or remove a device during an active move unless following a tested recovery procedure.

---

## 23. Removing a PV from a VG

Assume `/dev/sdb1` must be retired.

### Step 1 — Inspect

```bash
sudo pvs -o pv_name,vg_name,pv_size,pv_used,pv_free
sudo lvs -o lv_name,vg_name,devices
```

### Step 2 — Move Allocated Extents

```bash
sudo pvmove /dev/sdb1
```

### Step 3 — Confirm the PV Is Empty

```bash
sudo pvs -o pv_name,vg_name,pv_used,pv_free
```

Expected for the source:

```text
PUsed = 0
```

### Step 4 — Remove from VG

```bash
sudo vgreduce vg_app /dev/sdb1
```

### Step 5 — Verify

```bash
sudo pvs
sudo vgs
sudo lvs -o +devices
```

### Step 6 — Remove the PV Label Only If Authorized

```bash
sudo pvremove /dev/sdb1
```

Only after the device is no longer needed as an LVM PV.

---

## 24. Activating and Deactivating LVs

Activate an LV:

```bash
sudo lvchange -ay /dev/vg_app/lv_data
```

Deactivate:

```bash
sudo lvchange -an /dev/vg_app/lv_data
```

Activate all appropriate LVs in a VG:

```bash
sudo vgchange -ay vg_app
```

Deactivate:

```bash
sudo vgchange -an vg_app
```

Before deactivation:

- Stop dependent applications.
- Unmount the filesystem.
- Disable swap if the LV is swap.
- Check for open holders.
- Confirm the change is authorized.

Useful checks:

```bash
findmnt -S /dev/vg_app/lv_data
sudo fuser -vm /data
lsblk
```

---

## 25. LVM Scanning

Scan for PVs:

```bash
sudo pvscan
```

Scan for VGs:

```bash
sudo vgscan
```

Scan for LVs:

```bash
sudo lvscan
```

These can help when:

- A new device was presented.
- A VG was imported.
- An LV appears inactive.
- Device discovery changed.

On modern RHEL systems, LVM and system services often manage discovery automatically. Use scanning commands as part of diagnosis, not as a substitute for finding the underlying device problem.

---

## 26. LVM Device Selection

Enterprise hosts may see:

- Local disks
- SAN paths
- Multipath maps
- Installer media
- Container loop devices
- Stale device paths

LVM must scan the intended devices and avoid duplicate underlying paths.

Inspect configuration:

```bash
sudo lvmconfig
```

Relevant files may include:

```text
/etc/lvm/lvm.conf
/etc/lvm/devices/system.devices
```

On modern RHEL releases, the LVM devices file can restrict which devices LVM uses.

Inspect:

```bash
sudo lvmdevices
```

Never change filters or the devices file in production without understanding:

- Multipath
- Boot volumes
- Clustered storage
- Existing PV visibility
- Initramfs requirements

---

## 27. Multipath and LVM

With SAN storage, multiple paths may lead to one LUN.

The desired stack is commonly:

```text
SAN paths → multipath map → LVM PV → VG → LV → filesystem
```

The PV should normally be created on the multipath device, not independently on each underlying path.

Useful commands:

```bash
sudo multipath -ll
lsblk
sudo pvs -o pv_name,vg_name,pv_uuid
```

A duplicate PV warning may mean LVM is seeing both:

- The multipath map
- One or more component paths

Treat this as a device-discovery and multipath configuration issue. Do not initialize or remove labels to “fix” it without mapping the storage first.

---

## 28. LVM Metadata

LVM metadata describes:

- PV identities
- VG membership
- LV definitions
- Extent mappings
- Snapshot relationships
- Thin-pool information

Automatic metadata archives are commonly kept under:

```text
/etc/lvm/archive/
```

Current VG backups are commonly kept under:

```text
/etc/lvm/backup/
```

Inspect configuration:

```bash
sudo lvmconfig --type full backup
```

### Manual Metadata Backup

```bash
sudo vgcfgbackup vg_app
```

Back up all VGs:

```bash
sudo vgcfgbackup
```

List:

```bash
sudo ls -l /etc/lvm/backup /etc/lvm/archive
```

### Critical Distinction

`vgcfgbackup` saves LVM metadata. It does not save:

- Files in the filesystem
- Database contents
- Application state
- Bootloader data outside LVM metadata

---

## 29. Metadata Restore Concepts

Inspect available archives:

```bash
sudo vgcfgrestore --list vg_app
```

Test the restore command’s available options:

```bash
sudo vgcfgrestore --help
```

A restore may use:

```bash
sudo vgcfgrestore -f /path/to/metadata-backup vg_app
```

> Do not run a metadata restore casually. Incorrect metadata can map LVs to the wrong extents and cause severe data loss.

Before a real restore:

- Stop dependent applications.
- Prevent writes.
- Preserve current metadata and logs.
- Confirm exact PV UUIDs.
- Confirm the correct archive time.
- Review missing-device status.
- Follow the vendor-supported recovery procedure.
- Have application-data backups available.

---

## 30. Standard LVM Snapshots

A standard snapshot creates a point-in-time view of an LV using copy-on-write storage.

Create:

```bash
sudo lvcreate -s -L 2G -n lv_data_snap /dev/vg_app/lv_data
```

Inspect:

```bash
sudo lvs -a -o lv_name,origin,lv_size,data_percent,lv_attr
```

Mount read-only for inspection:

```bash
sudo mkdir -p /mnt/lv_data_snap
sudo mount -o ro /dev/vg_app/lv_data_snap /mnt/lv_data_snap
```

Remove after unmounting:

```bash
sudo umount /mnt/lv_data_snap
sudo lvremove /dev/vg_app/lv_data_snap
```

### How It Works

After the snapshot is created:

- Unchanged blocks are shared with the origin.
- Before an origin block changes, its old data is copied to snapshot storage.
- Snapshot capacity stores changed blocks and metadata, not a full initial copy.

### Snapshot Risks

- If snapshot space fills, the snapshot can become invalid.
- Snapshots add I/O overhead.
- Long-lived snapshots can hurt performance.
- A crash-consistent snapshot is not automatically application-consistent.
- Database applications may require quiescing, flushing, or native backup integration.

### Interview Principle

> An LVM snapshot is not a complete backup. It normally resides on the same storage stack and can be lost with the origin storage.

---

## 31. Snapshot Monitoring

Monitor:

```bash
sudo lvs -a -o lv_name,origin,lv_size,data_percent,lv_attr
```

Check frequently during:

- Backup jobs
- Patch testing
- Upgrade rollback windows
- High-write application periods

Capacity planning depends on:

- Origin write rate
- Snapshot lifetime
- Expected changed blocks
- Performance requirements

Do not leave a standard snapshot unattended.

---

## 32. Thin Provisioning

Thin provisioning separates virtual LV size from immediately allocated physical capacity.

Components:

```text
VG
└── Thin pool
    ├── Data LV
    ├── Metadata LV
    ├── Thin LV A
    └── Thin LV B
```

Create a thin pool:

```bash
sudo lvcreate --type thin-pool -L 20G -n thin_pool vg_app
```

Create a thin LV:

```bash
sudo lvcreate --type thin -V 50G -n thin_data --thinpool thin_pool vg_app
```

Here:

- `-L 20G` allocates 20 GiB to the pool.
- `-V 50G` gives the thin LV a 50 GiB virtual size.

### Benefits

- Capacity is allocated as data is written.
- Large virtual volumes can be presented efficiently.
- Thin snapshots are space-efficient.

### Risks

- Overcommitment can exhaust the thin pool.
- Metadata exhaustion is serious.
- Monitoring must include `Data%` and `Meta%`.
- Applications may receive I/O errors if the pool cannot allocate space.
- Auto-extension policy must be designed and tested.

Monitor:

```bash
sudo lvs -a -o lv_name,lv_size,pool_lv,data_percent,metadata_percent,lv_attr
```

Thin provisioning requires stronger monitoring, not weaker monitoring.

---

## 33. Standard Snapshot vs. Thin Snapshot

| Feature | Standard snapshot | Thin snapshot |
|---|---|---|
| Storage model | Separate COW snapshot LV | Allocates from thin pool |
| Size argument | Snapshot capacity specified | Uses thin-pool capacity |
| Monitoring | Snapshot `Data%` | Pool `Data%` and `Meta%` |
| Lifetime | Usually short | Can be more flexible |
| Failure risk | Snapshot fills | Pool or metadata fills |
| Backup replacement | No | No |

Always identify the snapshot type before choosing commands.

---

## 34. Reducing Logical Volumes

Reduction is far riskier than extension.

### XFS

XFS does not support shrinking.

To use a smaller XFS LV, the safe design usually involves:

1. Create a new, smaller LV and filesystem.
2. Stop or quiesce the application.
3. Copy and verify data.
4. Change mounts.
5. Test the application.
6. Retain rollback until approved.
7. Remove old storage only after successful validation.

### ext4

ext4 can support shrinking, but the filesystem must be reduced before the LV, usually while unmounted.

Conceptual order:

```text
Backup → unmount → filesystem check → shrink filesystem → shrink LV → verify → mount
```

Never shrink the LV first. Doing so cuts off filesystem blocks and can destroy data.

Production reduction should follow a tested, filesystem-specific procedure with verified backups.

---

## 35. Safe LV Removal

Before removal:

- Confirm the exact LV and purpose.
- Verify application-owner approval.
- Confirm backups and retention.
- Stop dependent services.
- Unmount the filesystem.
- Remove or comment the `/etc/fstab` entry.
- Check open users.
- Capture `lvs -a -o +devices`.
- Back up VG metadata.

Commands:

```bash
findmnt -S /dev/vg_app/lv_old
sudo fuser -vm /mountpoint
sudo vgcfgbackup vg_app
```

Remove:

```bash
sudo lvremove /dev/vg_app/lv_old
```

Verify:

```bash
sudo lvs vg_app
sudo vgs vg_app
```

`lvremove` destroys access to the LV’s data.

---

## 36. Safe VG and PV Removal

Only remove a VG when all LVs are no longer required.

Inspect:

```bash
sudo lvs vg_old
sudo vgs vg_old
sudo pvs
```

Deactivate:

```bash
sudo vgchange -an vg_old
```

Remove VG:

```bash
sudo vgremove vg_old
```

Remove PV labels only after verifying the correct devices:

```bash
sudo pvremove /dev/DEVICE1 /dev/DEVICE2
```

These are destructive operations and require explicit authorization.

---

## 37. Renaming LVs and VGs

Rename an LV:

```bash
sudo lvrename vg_app lv_old lv_new
```

Rename a VG:

```bash
sudo vgrename vg_old vg_new
```

After renaming, review:

- `/etc/fstab`
- systemd mount units
- application configuration
- backup jobs
- monitoring
- scripts
- initramfs for root or boot-critical LVs
- cluster or multipath configuration

For a root VG rename, additional bootloader and initramfs work may be required. Treat it as a boot-critical change.

---

## 38. Importing and Exporting VGs

For planned movement between systems:

```bash
sudo vgexport vg_app
```

On the receiving system:

```bash
sudo vgimport vg_app
sudo vgchange -ay vg_app
```

This requires careful control of:

- Device ownership
- Duplicate VG names
- PV UUIDs
- Multipath visibility
- Filesystem consistency
- Application shutdown
- Cluster membership

Do not allow the same writable VG to be independently active on multiple non-cluster-aware hosts.

---

## 39. Common LVM Error: Insufficient Free Space

Example:

```text
Insufficient free space: N extents needed, but only M available
```

Investigate:

```bash
sudo vgs
sudo vgdisplay vg_app
sudo pvs
```

Possible causes:

- The VG truly lacks free extents.
- Requested size is too large.
- A snapshot or thin pool consumes space.
- Free extents exist in another VG.
- Allocation policy or segment type requires specific placement.
- Striped or RAID layout needs free extents on multiple PVs.

Solutions may include:

- Request a smaller extension.
- Add a PV.
- Expand an existing PV.
- Remove approved unused LVs or snapshots.
- Adjust the design after reviewing allocation constraints.

---

## 40. Common LVM Error: PV Not Found

Symptoms:

- VG is partial.
- LV is inactive.
- `pvs` shows an unknown device.
- Boot enters emergency mode.
- LVM reports a missing PV UUID.

Investigate:

```bash
lsblk
sudo blkid
sudo pvs -a -o +pv_uuid,devices
sudo vgs
sudo lvs -a -o +devices
sudo dmesg -T | tail -100
sudo journalctl -b -p warning
```

Check:

- Was a cloud disk or SAN LUN detached?
- Did device discovery fail?
- Is multipath healthy?
- Did the device name change?
- Is the LVM devices file excluding it?
- Is encryption unlocked?
- Is the storage path down?

Do not run `vgreduce --removemissing` until you understand exactly what data was on the missing PV and have an approved recovery decision.

---

## 41. Common LVM Error: LV Inactive

Inspect:

```bash
sudo lvs -a -o lv_name,vg_name,lv_attr,devices
sudo vgscan
sudo pvscan
sudo vgchange -ay vg_app
```

Possible causes:

- Missing PV
- Duplicate VG or PV identity
- Device filter or devices-file problem
- Thin-pool failure
- Snapshot relationship issue
- Cluster locking
- Activation policy
- Encryption layer not opened

If activation fails, capture the exact error and investigate the lower storage layers before forcing activation.

---

## 42. Common LVM Error: Filesystem Did Not Grow

Symptom:

```text
lvs shows larger LV
df shows old filesystem size
```

Cause:

Only the LV was extended.

Identify filesystem:

```bash
findmnt -no FSTYPE,SOURCE,TARGET /data
```

For XFS:

```bash
sudo xfs_growfs /data
```

For ext4:

```bash
sudo resize2fs /dev/vg_app/lv_data
```

Verify:

```bash
sudo lvs /dev/vg_app/lv_data
df -hT /data
```

---

## 43. Common LVM Error: Disk Grew but VG Did Not

Compare layers:

```bash
lsblk
sudo pvs -o pv_name,dev_size,pv_size,pv_free
sudo vgs
```

Possible missing step:

- Kernel has not recognized the new disk size.
- Partition has not grown.
- `pvresize` has not been run.

Correct the missing lower-layer step, then verify before extending the LV.

---

## 44. Thin-Pool Capacity Incident

Inspect:

```bash
sudo lvs -a -o lv_name,lv_size,data_percent,metadata_percent,lv_health_status,lv_attr
sudo vgs
```

Response priorities:

1. Protect application integrity.
2. Stop uncontrolled growth if possible.
3. Determine whether data or metadata is exhausted.
4. Add capacity or extend the appropriate thin-pool component.
5. Follow supported recovery guidance.
6. Validate all thin LVs and applications.
7. Fix monitoring and auto-extension controls.

Do not treat a thin pool’s virtual free space as actual physical capacity.

---

## 45. Production Change Example — Extend `/var`

### Request

`/var` is 90% full. Add 20 GiB.

### Discovery

```bash
findmnt /var
df -hT /var
df -i /var
sudo lvs -o lv_name,vg_name,lv_size,devices
sudo vgs
sudo pvs
```

### Decision

Suppose:

- Source: `/dev/vg_os/lv_var`
- Filesystem: XFS
- VG free: 35 GiB
- Required addition: 20 GiB

### Change

```bash
sudo vgcfgbackup vg_os
sudo lvextend -L +20G /dev/vg_os/lv_var
sudo xfs_growfs /var
```

### Validation

```bash
sudo lvs /dev/vg_os/lv_var
df -hT /var
findmnt /var
sudo journalctl -p err --since "10 minutes ago"
```

### Engineer II Follow-Up

- Confirm application health.
- Confirm monitoring sees new capacity.
- Attach before-and-after evidence to the change.
- Check whether log retention or runaway files caused the growth.
- Close the change with actual results.

Adding capacity treats the symptom; root cause may still require action.

---

## 46. Production Change Example — Add an EBS Volume

Conceptual AWS workflow:

1. Create and attach the approved EBS volume.
2. Confirm the device mapping from AWS and the instance.
3. Identify the new NVMe device by serial or EBS volume ID.
4. Confirm it has no filesystem, partition, mount, or PV.
5. Create the PV.
6. Extend the VG.
7. Extend the target LV and filesystem.
8. Validate application and monitoring.

Linux commands:

```bash
lsblk -o NAME,SERIAL,SIZE,TYPE,FSTYPE,MOUNTPOINTS
sudo nvme list
sudo wipefs -n /dev/nvmeNEW
sudo pvcreate /dev/nvmeNEW
sudo vgextend vg_app /dev/nvmeNEW
sudo lvextend -r -L +50G /dev/vg_app/lv_data
```

The exact device name may differ from the block-device mapping shown by AWS. Identify by metadata and serial, not by guessing the next NVMe number.

---

## 47. Performance and Layout Considerations

LVM flexibility does not eliminate physical-storage limits.

Consider:

- Underlying disk performance
- SAN or EBS throughput and IOPS
- Queue depth
- RAID level
- Multipath policy
- Stripe geometry
- Snapshot overhead
- Thin-pool metadata
- Filesystem workload
- Application I/O pattern

Useful commands:

```bash
iostat -xz 1
lsblk -D
sudo lvs -o lv_name,segtype,stripes,stripesize,devices
sudo dmsetup table
```

An LV spanning slow and fast PVs does not automatically provide predictable performance.

---

## 48. LVM and Encryption

Two common layouts:

### Encryption Below LVM

```text
Disk → LUKS → PV → VG → LV → filesystem
```

This can protect the entire LVM container.

### Encryption Above LVM

```text
Disk → PV → VG → LV → LUKS → filesystem
```

This allows individual LVs to be encrypted separately.

Expansion order depends on the layout.

For encryption below LVM:

```text
Grow disk → grow partition → resize LUKS → pvresize → lvextend → grow filesystem
```

For encryption above LVM:

```text
Grow disk/PV/VG → lvextend → resize LUKS → grow filesystem
```

Never assume the order. Map the exact stack with:

```bash
lsblk -f
sudo dmsetup ls --tree
sudo pvs
sudo lvs -o +devices
```

---

## 49. Monitoring LVM

Monitor:

- VG free space
- LV utilization
- Filesystem utilization
- Inode utilization
- Snapshot `Data%`
- Thin-pool `Data%`
- Thin-pool `Meta%`
- PV and device health
- Storage latency and errors
- Multipath path health

Commands:

```bash
sudo vgs
sudo lvs -a -o +data_percent,metadata_percent,lv_health_status
df -hT
df -i
iostat -xz 1
sudo journalctl -k -p warning
```

Good alerts leave enough time to act before exhaustion.

---

## 50. Safe File-Backed LVM Lab

This lab uses two regular files attached to loop devices. It does not require a real spare disk.

> Run this only on a disposable Linux practice system where you have `sudo`. Read every command before running it. The validation checks require loop devices and intentionally reject normal disk names.

### Requirements

Install tools on RHEL-family systems:

```bash
sudo dnf install -y lvm2 xfsprogs util-linux
```

### Lab Variables

```bash
lab_dir="$PWD/module09-lab"
disk_one_image="$lab_dir/disk-one.img"
disk_two_image="$lab_dir/disk-two.img"
mount_point="$lab_dir/mnt"
vg_name="vg_module09"
lv_name="lv_practice"
snapshot_name="lv_practice_snap"
```

### Step 1 — Create Lab Files

```bash
mkdir -p "$lab_dir" "$mount_point"
truncate -s 700M "$disk_one_image"
truncate -s 700M "$disk_two_image"
ls -lh "$disk_one_image" "$disk_two_image"
```

### Step 2 — Attach Loop Devices

```bash
loop_one="$(sudo losetup --find --show "$disk_one_image")"
loop_two="$(sudo losetup --find --show "$disk_two_image")"
printf 'loop_one=%s\nloop_two=%s\n' "$loop_one" "$loop_two"
```

### Step 3 — Safety Validation

```bash
case "$loop_one" in
  /dev/loop[0-9]*) ;;
  *) echo "Safety check failed for loop_one"; exit 1 ;;
esac

case "$loop_two" in
  /dev/loop[0-9]*) ;;
  *) echo "Safety check failed for loop_two"; exit 1 ;;
esac
```

Confirm both devices are backed by files in the lab:

```bash
sudo losetup -l "$loop_one" "$loop_two"
```

Do not continue unless both are the expected loop devices.

### Step 4 — Inspect for Signatures

```bash
sudo wipefs -n "$loop_one"
sudo wipefs -n "$loop_two"
```

### Step 5 — Create the First PV

```bash
sudo pvcreate "$loop_one"
sudo pvs "$loop_one"
```

### Step 6 — Create the VG

```bash
sudo vgcreate "$vg_name" "$loop_one"
sudo vgs "$vg_name"
```

### Step 7 — Create the LV

Reserve free space for the snapshot:

```bash
sudo lvcreate -L 300M -n "$lv_name" "$vg_name"
sudo lvs "$vg_name"
```

### Step 8 — Create XFS

```bash
sudo mkfs.xfs "/dev/$vg_name/$lv_name"
```

### Step 9 — Mount and Test

```bash
sudo mount "/dev/$vg_name/$lv_name" "$mount_point"
echo "Module 09 LVM practice" | sudo tee "$mount_point/verification.txt"
sudo sync
findmnt "$mount_point"
df -hT "$mount_point"
sudo cat "$mount_point/verification.txt"
```

### Step 10 — Inspect the Complete Stack

```bash
lsblk -f "$loop_one"
sudo pvs -o pv_name,vg_name,pv_size,pv_used,pv_free
sudo vgs -o vg_name,pv_count,lv_count,vg_size,vg_free
sudo lvs -o lv_name,vg_name,lv_size,lv_attr,devices
sudo dmsetup ls --tree
```

### Step 11 — Extend the LV and XFS

```bash
sudo lvextend -L +100M "/dev/$vg_name/$lv_name"
sudo xfs_growfs "$mount_point"
sudo lvs "/dev/$vg_name/$lv_name"
df -hT "$mount_point"
```

### Step 12 — Add the Second PV

```bash
sudo pvcreate "$loop_two"
sudo vgextend "$vg_name" "$loop_two"
sudo pvs
sudo vgs "$vg_name"
```

### Step 13 — Extend Again

```bash
sudo lvextend -r -L +100M "/dev/$vg_name/$lv_name"
sudo lvs -o lv_name,lv_size,devices "$vg_name"
df -hT "$mount_point"
```

### Step 14 — Create a Snapshot

```bash
sudo lvcreate -s -L 100M -n "$snapshot_name" "/dev/$vg_name/$lv_name"
sudo lvs -a -o lv_name,origin,lv_size,data_percent,devices "$vg_name"
```

Change the origin:

```bash
echo "New data after snapshot" | sudo tee "$mount_point/after-snapshot.txt"
sudo sync
sudo lvs -a -o lv_name,origin,lv_size,data_percent "$vg_name"
```

### Step 15 — Mount Snapshot Read-Only

```bash
snapshot_mount="$lab_dir/snapshot-mnt"
mkdir -p "$snapshot_mount"
sudo mount -o ro,nouuid "/dev/$vg_name/$snapshot_name" "$snapshot_mount"
sudo ls -la "$snapshot_mount"
```

For an XFS snapshot clone, `nouuid` allows mounting because the origin and snapshot contain the same XFS UUID. Mount it read-only for this lab.

The snapshot should contain:

```text
verification.txt
```

It should not contain the file created after the snapshot:

```text
after-snapshot.txt
```

Verify:

```bash
sudo test -f "$snapshot_mount/verification.txt" && echo "Original file is present"
sudo test ! -f "$snapshot_mount/after-snapshot.txt" && echo "Snapshot point-in-time verified"
```

### Step 16 — Unmount and Remove Snapshot

```bash
sudo umount "$snapshot_mount"
sudo lvremove -y "/dev/$vg_name/$snapshot_name"
sudo lvs -a "$vg_name"
```

### Step 17 — Back Up Metadata

```bash
sudo vgcfgbackup "$vg_name"
sudo vgcfgrestore --list "$vg_name"
```

Do not perform an actual metadata restore in this healthy lab.

### Step 18 — Review Extent Placement

```bash
sudo pvs --segments
sudo lvs -o lv_name,vg_name,lv_size,devices
```

### Optional Step 19 — Move Extents from the First PV

First verify the second PV has enough free capacity:

```bash
sudo pvs -o pv_name,pv_size,pv_used,pv_free
```

Then:

```bash
sudo pvmove "$loop_one" "$loop_two"
```

Verify:

```bash
sudo pvs -o pv_name,pv_used,pv_free
sudo lvs -o lv_name,devices
```

If the destination lacks enough space, do not force the operation. This lab’s sizes should normally allow it, but actual LVM allocation and metadata sizes must be checked.

### Optional Step 20 — Remove the Empty First PV

Only if `PUsed` for `loop_one` is zero:

```bash
sudo vgreduce "$vg_name" "$loop_one"
sudo pvs
sudo vgs "$vg_name"
```

### Step 21 — Lab Cleanup

Stop using the mounted filesystem:

```bash
cd /
sudo umount "$mount_point"
```

Remove the LV:

```bash
sudo lvremove -y "/dev/$vg_name/$lv_name"
```

If both PVs remain in the VG, remove the VG:

```bash
sudo vgremove -y "$vg_name"
```

If `loop_one` was already removed with `vgreduce`, remove any remaining LVM label:

```bash
if sudo pvs "$loop_one" >/dev/null 2>&1; then
  sudo pvremove -y "$loop_one"
fi
```

Remove the second PV label if it remains:

```bash
if sudo pvs "$loop_two" >/dev/null 2>&1; then
  sudo pvremove -y "$loop_two"
fi
```

Verify no LVM object still uses the loop devices:

```bash
sudo pvs
sudo vgs
sudo lvs
lsblk "$loop_one" "$loop_two"
```

Detach only the validated loop devices:

```bash
sudo losetup -d "$loop_one"
sudo losetup -d "$loop_two"
```

The image files can now be deleted:

```bash
rm -f "$disk_one_image" "$disk_two_image"
rmdir "$snapshot_mount" "$mount_point" "$lab_dir" 2>/dev/null || true
```

### Lab Success Criteria

You should be able to explain:

- Why the first PV could not be removed while it contained extents.
- How `pvmove` changes physical placement without changing the LV path.
- Why XFS growth used the mount point.
- Why the snapshot needed capacity monitoring.
- Why the snapshot was mounted with `nouuid`.
- Why the lab still required safety checks even though it used files.

---

## 51. Production Troubleshooting Scenarios

### Scenario 1 — `/data` Is Full, VG Has Free Space

Approach:

```bash
findmnt /data
df -hT /data
sudo lvs
sudo vgs
```

If approved, extend LV and grow the filesystem.

### Scenario 2 — VG Has No Free Space

Approach:

- Check whether the underlying PV can grow.
- Check whether an approved new PV can be added.
- Review stale snapshots and unused LVs.
- Do not delete storage merely to satisfy the request.

### Scenario 3 — Cloud Disk Was Expanded

Approach:

- Confirm Linux sees the larger disk.
- Grow the partition if present.
- Run `pvresize`.
- Extend LV and filesystem.

### Scenario 4 — Disk Must Be Retired

Approach:

- Confirm destination free capacity.
- Run and monitor `pvmove`.
- Verify source `PUsed` is zero.
- Run `vgreduce`.
- Remove PV label only when authorized.

### Scenario 5 — Snapshot Is Near 100%

Approach:

- Confirm whether it is still required.
- Estimate write rate.
- Extend it if supported and approved, or complete the backup and remove it.
- Do not ignore it.

### Scenario 6 — Thin Pool Near Capacity

Approach:

- Inspect data and metadata percentages.
- Control write growth.
- Extend the correct pool component.
- Confirm monitoring and auto-extension.

### Scenario 7 — LV Is Larger but `df` Is Unchanged

Approach:

- Identify filesystem type.
- Run `xfs_growfs` or `resize2fs`.
- Verify both layers.

### Scenario 8 — VG Is Partial

Approach:

- Find the missing PV UUID.
- Investigate storage presentation, multipath, encryption, and device rules.
- Do not remove the missing PV until recovery impact is approved.

---

## 52. Interview Questions and Model Answers

### 1. What is LVM?

LVM is a storage-abstraction layer that combines physical block devices into volume groups and allocates flexible logical volumes from those pools.

### 2. What is the difference between PV, VG, and LV?

A PV is an LVM-initialized block device, a VG pools one or more PVs, and an LV is a virtual block device allocated from the VG.

### 3. What are physical and logical extents?

Physical extents are fixed allocation units on PVs. Logical extents are the corresponding units assigned to LVs.

### 4. How do you check available VG capacity?

Use `vgs` or `vgdisplay`. The `VFree` or free-extents field shows capacity that can be allocated.

### 5. How do you extend an XFS filesystem on LVM?

Confirm VG free space, extend the LV with `lvextend`, then grow mounted XFS with `xfs_growfs MOUNTPOINT`. Verify with `lvs` and `df -hT`.

### 6. How do you extend ext4 on LVM?

Extend the LV and run `resize2fs` against the LV device. Online growth is commonly supported, but the production procedure must be validated.

### 7. What does `lvextend -r` do?

It extends the LV and invokes the filesystem resize helper so the filesystem grows in the same operation.

### 8. The cloud disk grew but the VG did not. Why?

Linux may not have rescanned the device, a partition may still be the old size, or the PV may require `pvresize`.

### 9. How do you add a disk to a VG?

Verify the correct unused device, create a PV with `pvcreate`, then add it using `vgextend`.

### 10. How do you remove a PV safely?

Use `pvmove` to evacuate its allocated extents, verify `PUsed` is zero, run `vgreduce`, and remove the PV label only if authorized.

### 11. What happens if `pvmove` has no destination space?

The move cannot complete. You need enough suitable free extents in the same VG or must add capacity.

### 12. Is an LVM snapshot a backup?

No. It is a point-in-time block view and normally shares the same storage failure domain. It can support a backup workflow but does not replace an independent backup.

### 13. What happens when a standard snapshot fills?

It can become invalid and no longer provide the expected point-in-time view.

### 14. What is thin provisioning?

Thin provisioning presents virtual capacity and allocates physical pool space as blocks are written.

### 15. What must be monitored in a thin pool?

Both data usage and metadata usage, along with actual VG free capacity and application behavior.

### 16. Can XFS be shrunk?

No. A common safe approach is to create a smaller filesystem, migrate and verify data, then switch mounts.

### 17. Why must a filesystem be shrunk before an ext4 LV?

Reducing the LV first can remove blocks still owned by the filesystem and cause corruption or data loss.

### 18. What does `vgcfgbackup` back up?

It backs up LVM VG metadata, not application files or filesystem data.

### 19. Why can `/dev/dm-2` be a poor persistent reference?

The numeric device-mapper name can change. Use an LVM path or filesystem UUID.

### 20. How do you trace `/data` to physical storage?

Start with `findmnt /data`, inspect `lsblk`, then use `lvs -o +devices`, `vgs`, `pvs`, and device-mapper or multipath tools.

### 21. What is the difference between `-L +10G` and `-L 10G`?

`-L +10G` adds 10 GiB. `-L 10G` requests a final size of 10 GiB.

### 22. Why should you avoid `-l +100%FREE` without planning?

It consumes all free VG extents and leaves no reserve for other LVs, snapshots, or emergencies.

### 23. What causes a partial VG?

One or more PVs are missing or unavailable, often because of storage presentation, path, device-selection, encryption, or hardware problems.

### 24. Can LVM move live data between PVs?

`pvmove` can relocate allocated extents while LVs remain available in many normal cases, but it requires capacity, monitoring, and risk planning.

### 25. What does an Engineer II add beyond the commands?

End-to-end layer mapping, capacity analysis, application coordination, change control, monitoring, rollback planning, evidence collection, and root-cause follow-up.

---

## 53. Quick Knowledge Check

1. Which object pools storage from one or more PVs?
2. Which command shows VG free space?
3. Which option means “add 5 GiB”?
4. Which command grows mounted XFS?
5. Which command grows ext4?
6. What step follows partition growth for an LVM PV?
7. Which command moves allocated extents?
8. What must be true before `vgreduce` removes a PV safely?
9. Does `vgcfgbackup` save application data?
10. What happens if a standard snapshot fills?
11. Which two percentages matter for thin pools?
12. Can XFS be shrunk?
13. Why is `/dev/dm-N` not ideal in `/etc/fstab`?
14. What does `-l +100%FREE` mean?
15. What must you inspect before running `pvcreate`?

### Answers

1. Volume group
2. `vgs` or `vgdisplay`
3. `-L +5G`
4. `xfs_growfs MOUNTPOINT`
5. `resize2fs LV_DEVICE`
6. `pvresize`
7. `pvmove`
8. It must contain no allocated extents
9. No
10. It can become invalid
11. Data percent and metadata percent
12. No
13. The numeric mapping can change
14. Add all currently free extents to the LV
15. Device identity, signatures, mounts, data, holders, PV status, authorization, and backups

---

## 54. Engineer I vs. Engineer II Expectations

| Area | Engineer I | Engineer II |
|---|---|---|
| Discovery | Runs `pvs`, `vgs`, and `lvs` | Correlates application, filesystem, LV, VG, PV, device mapper, and physical storage |
| Creation | Builds a basic PV/VG/LV stack | Applies naming, allocation, security, performance, and lifecycle standards |
| Expansion | Extends LV and filesystem | Validates capacity, growth path, downtime, rollback, monitoring, and application health |
| Troubleshooting | Recognizes common errors | Finds the failed layer and prevents destructive recovery actions |
| Snapshots | Creates and removes snapshots | Plans consistency, size, lifetime, performance, monitoring, and backup integration |
| Thin provisioning | Understands virtual allocation | Manages overcommitment, data/metadata thresholds, and failure response |
| Disk retirement | Knows `pvmove` and `vgreduce` | Plans capacity, performance, recovery, evidence, and vendor coordination |
| Documentation | Records commands | Produces change plan, validation, rollback, root cause, and operational runbook |
| Leadership | Escalates complex issues | Mentors others and reviews high-risk storage changes |

---

## 55. Module Completion Checklist

- [ ] I can explain PV, VG, and LV.
- [ ] I understand physical and logical extents.
- [ ] I can trace a mount to its backing PVs.
- [ ] I can create a basic LVM stack in a lab.
- [ ] I know the difference between `-L` and `-l`.
- [ ] I can extend XFS.
- [ ] I can extend ext4.
- [ ] I understand `lvextend -r`.
- [ ] I can add a new PV to a VG.
- [ ] I know when to use `pvresize`.
- [ ] I can explain `pvmove`.
- [ ] I know the safe PV-removal order.
- [ ] I understand snapshot risks.
- [ ] I understand thin-pool data and metadata monitoring.
- [ ] I know XFS cannot shrink.
- [ ] I understand that metadata backup is not data backup.
- [ ] I can troubleshoot a partial VG.
- [ ] I can design a controlled production expansion.
- [ ] I completed the loop-device lab.
- [ ] I can answer the interview questions without notes.

---

## 56. Command Revision Sheet

### Discovery

```bash
sudo pvs
sudo vgs
sudo lvs
sudo lvs -a -o +devices
sudo pvs --segments
lsblk -f
findmnt
sudo dmsetup ls --tree
```

### Creation

```bash
sudo pvcreate /dev/DEVICE
sudo vgcreate vg_name /dev/DEVICE
sudo lvcreate -L 10G -n lv_name vg_name
sudo mkfs.xfs /dev/vg_name/lv_name
```

### Expansion

```bash
sudo vgextend vg_name /dev/NEW_DEVICE
sudo pvresize /dev/GROWN_PV
sudo lvextend -L +5G /dev/vg_name/lv_name
sudo xfs_growfs /mountpoint
sudo resize2fs /dev/vg_name/lv_name
sudo lvextend -r -L +5G /dev/vg_name/lv_name
```

### Movement and Removal

```bash
sudo pvmove /dev/SOURCE_PV /dev/DESTINATION_PV
sudo vgreduce vg_name /dev/EMPTY_PV
sudo pvremove /dev/FORMER_PV
sudo lvremove /dev/vg_name/lv_name
```

### Snapshots and Metadata

```bash
sudo lvcreate -s -L 2G -n snap_name /dev/vg_name/lv_name
sudo lvs -a -o lv_name,origin,data_percent
sudo lvremove /dev/vg_name/snap_name
sudo vgcfgbackup vg_name
sudo vgcfgrestore --list vg_name
```

---

## 57. Official Reference

For production work, verify commands and supported behavior against the documentation and man pages for the installed RHEL release:

- [Red Hat Enterprise Linux 9 — Configuring and Managing Logical Volumes](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/index)
- `man lvm`
- `man pvs`
- `man vgs`
- `man lvs`
- `man pvcreate`
- `man vgextend`
- `man lvextend`
- `man pvmove`
- `man lvmthin`

---

## Next Module

**Module 10 — Boot Process, GRUB2, systemd Targets, and Recovery**

Topics will include:

- Firmware, boot devices, and bootloader stages
- BIOS versus UEFI
- GRUB2 configuration
- Kernel and initramfs
- systemd boot targets
- Default target management
- Kernel command-line parameters
- Rescue and emergency modes
- Resetting the root password safely
- Rebuilding initramfs and GRUB configuration
- Diagnosing boot failures
- Production recovery scenarios and interview questions
