# Linux Systems Engineer II Interview Preparation

## Module 08 — Partitions, Filesystems, Mounts, and Swap

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 90 minutes

> Storage commands can permanently destroy data. Never run `mkfs`, `mkswap`, partitioning, repair, or destructive resize commands until you have positively identified the exact device, confirmed backups and rollback, checked active mounts and users, and obtained authorization.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain the layers between a physical or cloud disk and an application path.
- Identify disks, partitions, filesystems, UUIDs, labels, and mounts.
- Recognize common Linux block-device naming schemes.
- Explain GPT and MBR partition tables.
- Create partitions in a controlled lab.
- Explain XFS and ext4 capabilities and limitations.
- Mount and unmount filesystems.
- Build persistent mount definitions using stable identifiers.
- Read and validate all `/etc/fstab` fields.
- Explain common mount options and their security implications.
- Investigate filesystem capacity and inode exhaustion.
- Identify deleted-but-open files and hidden data beneath mount points.
- Explain safe filesystem checking and repair.
- Configure and inspect swap.
- Explain the correct order for expanding a storage stack.
- Troubleshoot busy mounts, read-only filesystems, missing devices, and failed boot mounts.

---

## 2. Linux Storage Layers

A common storage stack is:

```text
Physical disk, SAN LUN, virtual disk, or cloud volume
                         ↓
                    Block device
                         ↓
                  Partition table
                         ↓
                      Partition
                         ↓
             Optional encryption or LVM
                         ↓
                     Filesystem
                         ↓
                    Mount point
                         ↓
              Application files and data
```

Not every deployment uses every layer.

Examples:

```text
/dev/sdb1 → XFS → /data
```

```text
/dev/nvme1n1 → LVM PV → VG → LV → XFS → /var/lib/application
```

```text
EBS volume → NVMe block device → partition → ext4 → /backup
```

### Important Interview Principle

> Expanding a disk does not automatically expand its partition, LVM layer, filesystem, or mount capacity. Each applicable layer must be expanded in the correct order.

---

## 3. Block Devices

A block device provides fixed-size blocks for storage I/O.

Examples:

- Local HDD or SSD
- Virtual machine disk
- AWS EBS volume
- SAN LUN
- NVMe device
- Loop device
- LVM logical volume

List:

```bash
lsblk
```

Detailed:

```bash
lsblk -o NAME,MAJ:MIN,SIZE,TYPE,FSTYPE,FSVER,LABEL,UUID,MOUNTPOINTS
```

Filesystem view:

```bash
lsblk -f
```

### Important Columns

| Column | Meaning |
|---|---|
| `NAME` | Device name |
| `SIZE` | Reported size |
| `TYPE` | Disk, partition, LVM, loop, ROM, and so on |
| `FSTYPE` | Filesystem or signature |
| `LABEL` | Filesystem label |
| `UUID` | Filesystem UUID |
| `MOUNTPOINTS` | Current mount locations |
| `RO` | Read-only flag |
| `MODEL` | Hardware or virtual-device model |
| `SERIAL` | Device serial when available |

---

## 4. Common Device Names

| Example | Typical Meaning |
|---|---|
| `/dev/sda` | SCSI, SATA, USB, or virtual disk |
| `/dev/sda1` | First partition on `/dev/sda` |
| `/dev/vda` | Virtio virtual disk |
| `/dev/vda1` | First partition on `/dev/vda` |
| `/dev/nvme0n1` | First NVMe namespace |
| `/dev/nvme0n1p1` | First partition on the NVMe device |
| `/dev/mapper/vg-lv` | Device-mapper or LVM logical volume |
| `/dev/loop0` | File-backed loop device |

Device names can change after:

- Reboot
- Hardware discovery changes
- Cloud attachment order changes
- Storage-path changes

Use persistent identifiers for filesystems when possible.

---

## 5. Persistent Device Identifiers

### UUID

```bash
blkid
```

Specific device:

```bash
sudo blkid /dev/sdb1
```

### Labels

```bash
lsblk -f
```

### Persistent Symlinks

```bash
ls -l /dev/disk/by-uuid/
ls -l /dev/disk/by-label/
ls -l /dev/disk/by-id/
```

### Identifiers

| Identifier | Scope |
|---|---|
| `UUID=` | Filesystem identifier |
| `LABEL=` | Human-assigned filesystem label |
| `PARTUUID=` | Partition identifier |
| `/dev/disk/by-id/...` | Hardware or platform identity |

For `/etc/fstab`, UUIDs are commonly safer than volatile names such as `/dev/sdb1`.

---

## 6. Device Discovery

Useful commands:

```bash
lsblk
sudo fdisk -l
sudo parted -l
sudo blkid
findmnt
```

Kernel messages:

```bash
journalctl -k
dmesg -T
```

Device events:

```bash
udevadm info --query=all --name=/dev/DEVICE
udevadm settle
```

In virtual or cloud environments, also verify the disk attachment through the hypervisor or cloud control plane.

Do not assume the newest-looking device is the intended disk. Match size, serial, ID, attachment information, existing signatures, and expected ownership.

---

## 7. Partition Tables

A partition table describes partitions on a disk.

Two common types:

- MBR, also called DOS
- GPT

### MBR

Characteristics:

- Older format
- Common historical limit near 2 TiB with traditional 512-byte sectors
- Four primary partition entries
- Extended/logical partitions used to exceed four partitions

### GPT

Characteristics:

- Modern format
- Supports large disks
- Supports many partitions
- Stores partition GUIDs
- Includes redundancy and checksums for partition-table metadata
- Common with UEFI systems

### Recommendation

GPT is normally preferred for new enterprise storage unless a compatibility requirement dictates otherwise.

---

## 8. Partitioning Tools

Common tools:

```bash
fdisk
parted
gdisk
```

Inspect without changing:

```bash
sudo fdisk -l /dev/DEVICE
sudo parted /dev/DEVICE print
```

### High-Risk Warning

Partition tools can overwrite the partition table.

Before making changes:

```bash
lsblk -f /dev/DEVICE
findmnt -S /dev/DEVICE
sudo blkid /dev/DEVICE*
sudo wipefs -n /dev/DEVICE
```

`wipefs -n` performs a no-write signature inspection. Do not remove signatures unless destruction is explicitly authorized.

---

## 9. Kernel Partition-Table Awareness

After changing a partition table:

```bash
sudo partprobe /dev/DEVICE
sudo udevadm settle
lsblk /dev/DEVICE
```

The kernel may refuse to reread a partition table when partitions are in use.

Do not force changes on mounted or active storage. Schedule downtime when required.

---

## 10. What Is a Filesystem?

A filesystem organizes files, directories, metadata, allocation, permissions, and free space on a block device or logical volume.

Common RHEL filesystems:

- XFS
- ext4

Other types may include:

- vfat for EFI System Partitions
- NFS for network storage
- tmpfs for memory-backed storage
- ISO9660 for optical images

Display:

```bash
df -hT
lsblk -f
findmnt
```

---

## 11. XFS

XFS is a common default filesystem for modern RHEL installations.

Characteristics:

- Journaling
- Scales to large filesystems and files
- Supports online growth
- Strong parallel-I/O design
- Cannot be shrunk in place using standard supported XFS tools

Create:

```bash
sudo mkfs.xfs /dev/DEVICE
```

Force creation over an existing signature:

```bash
sudo mkfs.xfs -f /dev/DEVICE
```

Do not use `-f` unless destruction of existing content is explicitly intended.

Label:

```bash
sudo xfs_admin -L DATA /dev/DEVICE
```

Grow a mounted XFS filesystem:

```bash
sudo xfs_growfs /mountpoint
```

The underlying block device or logical volume must already be larger.

---

## 12. ext4

ext4 characteristics:

- Journaling
- Mature and widely supported
- Supports online growth
- Can be shrunk only through an offline, carefully planned process

Create:

```bash
sudo mkfs.ext4 /dev/DEVICE
```

Label:

```bash
sudo e2label /dev/DEVICE DATA
```

Grow after the underlying device is expanded:

```bash
sudo resize2fs /dev/DEVICE
```

Do not attempt shrinking without a tested backup, unmounted filesystem, exact size planning, and recovery procedure.

---

## 13. XFS vs. ext4

| Feature | XFS | ext4 |
|---|---|---|
| Journaling | Yes | Yes |
| Online growth | Yes | Yes |
| In-place shrink | No standard supported method | Offline shrink supported with careful procedure |
| Common modern RHEL default | Yes | Available |
| Growth command | `xfs_growfs` | `resize2fs` |
| Main repair tool | `xfs_repair` | `e2fsck` |

Choose based on:

- RHEL support
- Application behavior
- Size and performance requirements
- Operational procedures
- Backup and recovery design

---

## 14. Creating a Filesystem Safely

Before `mkfs`:

```bash
lsblk -f /dev/DEVICE
findmnt -S /dev/DEVICE
sudo blkid /dev/DEVICE
sudo wipefs -n /dev/DEVICE
sudo fuser -vm /dev/DEVICE
```

Confirm:

- Exact device identity
- Correct size and serial
- No active filesystem or swap
- No LVM, RAID, encryption, or database ownership
- Data destruction is approved
- Backup and rollback exist

`mkfs` creates a new filesystem and destroys access to prior filesystem metadata and data.

---

## 15. Mounting a Filesystem

Create a mount point:

```bash
sudo mkdir -p /data
```

Mount:

```bash
sudo mount /dev/DEVICE /data
```

Verify:

```bash
findmnt /data
df -hT /data
mountpoint /data
```

### Mount by UUID

```bash
sudo mount UUID=FILESYSTEM_UUID /data
```

### Temporary vs. Persistent

A manual `mount` normally lasts until:

- Unmounted
- Server reboot

Persistent mounts are commonly defined in `/etc/fstab` or a systemd mount unit.

---

## 16. Unmounting

```bash
sudo umount /data
```

The command is `umount`, not `unmount`.

Verify:

```bash
findmnt /data
mountpoint /data
```

### Busy Filesystem

Find users:

```bash
sudo fuser -vm /data
sudo lsof +D /data
```

`lsof +D` can be expensive on a large tree.

Possible causes:

- Shell current directory is inside the mount
- Application has open files
- Swap file is active
- Nested mount exists
- Process executable or library is on the filesystem

Stop or relocate users through the approved procedure.

### Force and Lazy Unmount

Options such as forced or lazy unmount can hide unresolved use and risk data integrity. They are not routine fixes.

---

## 17. Hidden Files Beneath a Mount Point

If files are created in `/data` before another filesystem is mounted there, the underlying files become hidden after the mount.

They still consume space on the underlying filesystem.

Investigate only through a controlled procedure:

- Stop dependent applications.
- Confirm mount ownership.
- Use maintenance time.
- Safely unmount or expose the underlying filesystem through an approved method.

Do not unmount a production filesystem simply to look beneath it.

---

## 18. `/etc/fstab`

`/etc/fstab` defines filesystems and swap for persistent activation.

Format:

```text
SOURCE  MOUNTPOINT  TYPE  OPTIONS  DUMP  PASS
```

Example:

```text
UUID=1111-2222  /data  xfs  defaults  0  0
```

### Six Fields

| Field | Purpose |
|---:|---|
| 1 | Device, UUID, label, network source, or other source |
| 2 | Mount point or `none` for swap |
| 3 | Filesystem type |
| 4 | Mount options |
| 5 | Legacy dump backup flag |
| 6 | Filesystem check order at boot |

### Check Order

Common values:

- `0` — do not automatically check through fstab pass logic
- `1` — root filesystem
- `2` — other applicable filesystems

XFS commonly uses `0` because its boot and repair handling differs from ext filesystems.

---

## 19. Safe `/etc/fstab` Workflow

Back up:

```bash
sudo cp -a /etc/fstab "/etc/fstab.backup-$(date +%F-%H%M%S)"
```

Gather UUID:

```bash
sudo blkid /dev/DEVICE
```

Edit:

```bash
sudo vim /etc/fstab
```

Validate:

```bash
sudo findmnt --verify --verbose
```

Reload systemd generators after fstab changes:

```bash
sudo systemctl daemon-reload
```

Testing:

```bash
sudo mount -a
```

### Important Warning

`mount -a` can:

- Mount network storage
- Trigger automount behavior
- Expose incorrect entries
- Hang on unavailable dependencies

Use it only after validation and with awareness of all fstab entries.

Never reboot to test an unvalidated fstab change.

---

## 20. Common Mount Options

| Option | Meaning |
|---|---|
| `defaults` | Common default option set |
| `ro` | Read-only |
| `rw` | Read-write |
| `noexec` | Block direct execution from the filesystem |
| `nosuid` | Ignore SUID and SGID privilege effects |
| `nodev` | Do not interpret device files |
| `noatime` | Do not update access time normally |
| `nofail` | Continue boot when mount fails |
| `_netdev` | Indicates network-dependent storage |
| `x-systemd.automount` | Generate a systemd automount unit |

### Security Limitation

`noexec`, `nosuid`, and `nodev` provide useful defense in depth, but they are not complete application isolation.

For example, an interpreter may read a script stored on a `noexec` filesystem.

---

## 21. systemd Mount Units

systemd generates mount units from `/etc/fstab`.

Display:

```bash
systemctl list-units --type=mount
```

Mount unit names correspond to escaped paths.

Example:

```text
/data → data.mount
```

Inspect:

```bash
systemctl status data.mount
systemctl cat data.mount
```

For most routine persistent mounts, `/etc/fstab` remains the standard administrative interface.

---

## 22. Filesystem Capacity

Display:

```bash
df -hT
```

Specific path:

```bash
df -hT /var
```

Important:

- `df` reports filesystem-level allocation.
- A filesystem may be full even when the physical disk has free unallocated space.
- Expanding the disk alone does not expand the filesystem.

---

## 23. Inode Usage

```bash
df -i
```

A filesystem can report:

```text
No space left on device
```

even with free blocks if it has no free inodes.

Common causes:

- Millions of small files
- Session data
- Mail queues
- Cache files
- Temporary files
- Uncontrolled application output

For ext filesystems, inode allocation is substantially determined when the filesystem is created.

XFS allocates inodes dynamically within filesystem constraints, but operational limits and metadata pressure still require investigation.

---

## 24. Finding Space Usage

Top-level usage on one filesystem:

```bash
sudo du -xhd1 /var 2>/dev/null | sort -h
```

Large files:

```bash
sudo find /var -xdev -type f -size +1G -ls 2>/dev/null
```

Deleted-but-open files:

```bash
sudo lsof +L1
```

Inode-heavy directories:

```bash
sudo du --inodes -x -d1 /var 2>/dev/null | sort -n
```

Do not delete files until you identify:

- Application owner
- Retention requirement
- Backup
- Active process use
- Correct cleanup method

---

## 25. Why `df` and `du` Can Disagree

Possible causes:

- Deleted files still open by a process
- Hidden files beneath a mount point
- Reserved blocks
- Filesystem metadata
- Permission-denied paths
- Different filesystem boundaries
- Sparse-file accounting differences

Investigation:

```bash
df -hT /path
sudo du -xsh /path
sudo lsof +L1
findmnt -T /path
```

---

## 26. Filesystem Becomes Read-Only

Possible causes:

- Mounted with `ro`
- Kernel remounted it read-only after errors
- Storage path failure
- Filesystem corruption
- Cloud or hypervisor device issue
- Snapshot or storage policy

Check:

```bash
findmnt -no SOURCE,TARGET,FSTYPE,OPTIONS /mountpoint
journalctl -k
dmesg -T
lsblk -o NAME,SIZE,TYPE,FSTYPE,RO,MOUNTPOINTS
```

Do not immediately remount read-write. The read-only state may be protecting data after a serious error.

---

## 27. Filesystem Checking and Repair

### General Principles

- Confirm backups.
- Unmount the filesystem when the repair tool requires it.
- Confirm the exact device.
- Use no-modify inspection mode first when available.
- Follow filesystem-specific guidance.
- Do not run repair casually on mounted production storage.

### XFS

No-modify check:

```bash
sudo xfs_repair -n /dev/DEVICE
```

Repair:

```bash
sudo xfs_repair /dev/DEVICE
```

The filesystem normally must be unmounted.

`xfs_repair -L` can zero a corrupt log and may lose metadata changes. It is a last-resort option under an approved recovery procedure.

### ext4

Check:

```bash
sudo e2fsck -f /dev/DEVICE
```

The filesystem should normally be unmounted.

For a mounted root filesystem, use appropriate offline or recovery-mode procedures.

---

## 28. Filesystem Labels

### XFS

```bash
sudo xfs_admin -L DATA /dev/DEVICE
```

### ext4

```bash
sudo e2label /dev/DEVICE DATA
```

Mount by label:

```text
LABEL=DATA  /data  xfs  defaults  0  0
```

Labels must be managed to avoid ambiguity.

UUIDs are generally more unique, while labels are more human-readable.

---

## 29. Swap

Swap provides disk-backed virtual memory.

It can:

- Provide additional memory headroom
- Allow inactive pages to leave RAM
- Reduce immediate OOM risk in some conditions

It is much slower than RAM and does not fix:

- Memory leaks
- Incorrect sizing
- Application defects
- Sustained memory pressure

### Inspect

```bash
swapon --show
free -h
cat /proc/swaps
```

### Swap Activity

```bash
vmstat 1 5
```

Focus on:

- `si` — swap in
- `so` — swap out

Allocated swap is not the same as active swap thrashing. Examine rates, memory pressure, latency, and workload.

---

## 30. Creating Swap on a Device

Verify the exact unused device first.

Create:

```bash
sudo mkswap /dev/DEVICE
```

Enable:

```bash
sudo swapon /dev/DEVICE
```

Verify:

```bash
swapon --show
free -h
```

Persistent fstab:

```text
UUID=SWAP_UUID  none  swap  defaults  0  0
```

Get UUID:

```bash
sudo blkid /dev/DEVICE
```

---

## 31. Swap Files

A common workflow:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Persistent entry:

```text
/swapfile  none  swap  defaults  0  0
```

### Important Limitations

Swap-file support and requirements depend on:

- Filesystem
- Allocation layout
- Copy-on-write behavior
- Encryption
- Hibernation requirements
- Kernel and distribution support

Validate the procedure for the exact platform.

---

## 32. Disabling Swap

```bash
sudo swapoff /dev/DEVICE
```

or:

```bash
sudo swapoff /swapfile
```

Before disabling:

- Confirm sufficient RAM.
- Review current swap usage.
- Understand application impact.
- Avoid forcing memory exhaustion.

Remove the persistent fstab entry only after confirming the intended change.

---

## 33. Swappiness

Display:

```bash
sysctl vm.swappiness
```

Temporary change:

```bash
sudo sysctl -w vm.swappiness=VALUE
```

Persistent settings are commonly stored under:

```text
/etc/sysctl.d/
```

Do not tune swappiness from a generic rule. Base changes on workload behavior, latency, memory pressure, vendor recommendations, and testing.

---

## 34. Safe Storage Expansion Order

The exact workflow depends on the stack.

### Partition and Filesystem

```text
Expand physical/cloud disk
        ↓
Rescan and verify new size
        ↓
Expand partition
        ↓
Expand filesystem
        ↓
Verify capacity and application
```

### LVM

```text
Expand disk or attach new disk
        ↓
Expand partition if used
        ↓
Resize or create LVM physical volume
        ↓
Extend volume group if needed
        ↓
Extend logical volume
        ↓
Grow filesystem
        ↓
Verify
```

LVM commands will be covered in Module 09.

### Before Expansion

- Confirm the correct disk through serial and cloud attachment.
- Confirm backup and rollback.
- Check filesystem type.
- Check partition and LVM layout.
- Check whether online growth is supported.
- Record current state.
- Follow change management.

---

## 35. Shrinking Storage

Shrinking is more dangerous than growing.

- XFS cannot be shrunk in place through standard supported tools.
- ext4 shrink requires an offline, carefully ordered procedure.
- LVM must never be reduced below the filesystem size.

A safer XFS approach commonly involves:

1. Create a smaller filesystem.
2. Copy and validate data.
3. Switch mounts.
4. Preserve rollback.
5. Retire old storage after approval.

Never reduce the block device before safely shrinking or migrating the filesystem.

---

## 36. Hands-On Lab — File-Backed Virtual Disk

### Lab Safety

This lab uses a regular file and loop device so no real disk is formatted.

Requirements:

- Disposable RHEL-family VM
- Root or sudo access
- `losetup`, `parted`, `mkfs.xfs`, and swap tools
- Loop-device and partition support

Do not replace the loop device with `/dev/sda`, `/dev/vda`, `/dev/nvme...`, or any real device.

### Task 1 — Create the Lab Directory and Image

```bash
mkdir -p ~/linux-engineer-prep/module-08
cd ~/linux-engineer-prep/module-08
truncate -s 512M module08-disk.img
ls -lh module08-disk.img
```

### Task 2 — Attach a Loop Device

```bash
image_path="$PWD/module08-disk.img"
loop_device="$(
    sudo losetup --find --show --partscan "$image_path"
)"
echo "$loop_device"
```

Safety validation:

```bash
case "$loop_device" in
    /dev/loop[0-9]*)
        echo "Validated loop device: $loop_device"
        ;;
    *)
        echo "Unsafe or unexpected device: $loop_device" >&2
        exit 1
        ;;
esac
```

Confirm the loop device is backed by the lab image:

```bash
sudo losetup -l "$loop_device"
```

### Task 3 — Create a GPT Partition Table

This destroys only the contents of the newly created lab image:

```bash
sudo parted -s "$loop_device" mklabel gpt
sudo parted -s "$loop_device" \
  mkpart primary 1MiB 385MiB
sudo parted -s "$loop_device" \
  mkpart primary linux-swap 385MiB 100%
```

Ask the kernel to reread:

```bash
sudo partprobe "$loop_device"
sudo udevadm settle
lsblk -f "$loop_device"
```

Expected partition paths:

```bash
filesystem_partition="${loop_device}p1"
swap_partition="${loop_device}p2"
```

Verify both exist:

```bash
test -b "$filesystem_partition"
test -b "$swap_partition"
```

Stop if either test fails.

### Task 4 — Inspect Before Formatting

```bash
lsblk -f "$loop_device"
sudo wipefs -n "$filesystem_partition"
sudo wipefs -n "$swap_partition"
```

Confirm both are partitions of the validated loop device.

### Task 5 — Create XFS and Swap

```bash
sudo mkfs.xfs -L MODULE08 "$filesystem_partition"
sudo mkswap -L MODULE08-SWAP "$swap_partition"
```

Verify signatures:

```bash
lsblk -f "$loop_device"
sudo blkid "$filesystem_partition" "$swap_partition"
```

### Task 6 — Mount the Filesystem

```bash
lab_mount="/mnt/module08-lab"
sudo mkdir -p "$lab_mount"
sudo mount "$filesystem_partition" "$lab_mount"
```

Verify:

```bash
findmnt "$lab_mount"
df -hT "$lab_mount"
```

### Task 7 — Create Test Data

```bash
echo "Module 08 filesystem lab" | sudo tee "$lab_mount/README.txt"
sudo mkdir -p "$lab_mount/data"
sudo dd if=/dev/zero \
  of="$lab_mount/data/sample.bin" \
  bs=1M count=10 status=progress
```

Check:

```bash
sudo ls -lh "$lab_mount" "$lab_mount/data"
df -hT "$lab_mount"
df -i "$lab_mount"
```

### Task 8 — Generate an fstab Example Without Editing fstab

```bash
filesystem_uuid="$(
    sudo blkid -s UUID -o value "$filesystem_partition"
)"
printf 'UUID=%s  %s  xfs  defaults  0  0\n' \
  "$filesystem_uuid" "$lab_mount" \
  | tee fstab-example.txt
```

Do not add this temporary loop-backed example to the real `/etc/fstab`.

### Task 9 — Enable Lab Swap

Check memory and swap first:

```bash
free -h
swapon --show
```

Enable only the lab partition:

```bash
sudo swapon "$swap_partition"
```

Verify:

```bash
swapon --show
free -h
```

Generate an example:

```bash
swap_uuid="$(
    sudo blkid -s UUID -o value "$swap_partition"
)"
printf 'UUID=%s  none  swap  defaults  0  0\n' \
  "$swap_uuid" \
  | tee swap-fstab-example.txt
```

Do not add it to the real fstab.

### Task 10 — Inspect the Complete Lab

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS "$loop_device"
findmnt "$lab_mount"
swapon --show
```

Save:

```bash
lsblk -f "$loop_device" > loop-storage-layout.txt
df -hT "$lab_mount" > filesystem-capacity.txt
df -i "$lab_mount" > filesystem-inodes.txt
```

### Task 11 — Clean Up in the Correct Order

Disable only the lab swap:

```bash
sudo swapoff "$swap_partition"
```

Unmount only the lab mount:

```bash
sudo umount "$lab_mount"
```

Verify:

```bash
findmnt "$lab_mount"
swapon --show | grep -F "$swap_partition" || true
```

Detach only the validated loop device:

```bash
sudo losetup -d "$loop_device"
```

Remove the empty lab mount point:

```bash
sudo rmdir "$lab_mount"
```

Keep `module08-disk.img` and reports for study, or remove the image later only after verifying it is no longer attached:

```bash
sudo losetup -j "$image_path"
```

No output means the image is not attached to a loop device.

### Lab Deliverables

```text
module-08/
├── filesystem-capacity.txt
├── filesystem-inodes.txt
├── fstab-example.txt
├── loop-storage-layout.txt
├── module08-disk.img
└── swap-fstab-example.txt
```

---

## 37. Production Troubleshooting Scenarios

### Scenario 1 — `/var` Is 100% Full

Check:

```bash
df -hT /var
df -i /var
sudo du -xhd1 /var 2>/dev/null | sort -h
sudo find /var -xdev -type f -size +1G -ls 2>/dev/null
sudo lsof +L1
```

Do not blindly delete logs or application data.

### Scenario 2 — `No space left on device` but Blocks Are Free

Check:

```bash
df -i
```

Investigate inode exhaustion and uncontrolled small-file creation.

### Scenario 3 — Filesystem Cannot Be Unmounted

Check:

```bash
sudo fuser -vm /mountpoint
sudo lsof +D /mountpoint
findmnt -R /mountpoint
```

Look for active processes, shell directories, nested mounts, and swap files.

### Scenario 4 — Filesystem Is Read-Only

Check mount options and kernel logs. Do not simply remount read-write until storage and filesystem integrity are understood.

### Scenario 5 — Server Boots into Emergency Mode After fstab Change

Through console:

```bash
journalctl -xb
cat /etc/fstab
findmnt --verify
lsblk -f
blkid
```

Correct the exact invalid source, type, option, or dependency. Do not use `nofail` to hide failure of critical storage.

### Scenario 6 — Cloud Disk Expanded but `df` Is Unchanged

Determine which layer is unchanged:

```bash
lsblk
findmnt -T /mountpoint
df -hT /mountpoint
```

The disk, partition, LVM, and filesystem may each require separate expansion.

### Scenario 7 — High Swap Usage

Check:

```bash
free -h
vmstat 1 5
ps -eo pid,user,%mem,rss,vsz,etime,cmd --sort=-rss | head
```

Distinguish allocated swap from active swapping and memory pressure.

### Scenario 8 — Device Missing After Reboot

Check:

```bash
lsblk -f
journalctl -k
cat /etc/fstab
ls -l /dev/disk/by-uuid/
```

Confirm cloud, hypervisor, SAN, multipath, LVM, and stable identifier state.

---

## 38. Common Interview Questions and Answers

### 1. What is the difference between a disk, partition, filesystem, and mount point?

A disk is a block device. A partition is a defined region of a disk. A filesystem organizes files on a block device or partition. A mount point is the directory where the filesystem becomes accessible.

### 2. What is the difference between GPT and MBR?

GPT is the modern format supporting large disks, many partitions, GUIDs, redundancy, and metadata checksums. MBR is older and has traditional size and partition-count limitations.

### 3. Why use UUID in `/etc/fstab`?

Device names can change, while a filesystem UUID is a more stable identifier.

### 4. What are the six fstab fields?

Source, mount point, filesystem type, options, dump flag, and filesystem-check order.

### 5. How do you validate fstab before reboot?

```bash
findmnt --verify --verbose
```

Then use a controlled `mount -a` test when its impact is understood.

### 6. What is the difference between XFS and ext4 regarding shrinking?

XFS cannot be shrunk in place using standard supported tools. ext4 can be shrunk offline through a carefully planned procedure.

### 7. How do you grow XFS?

Expand the underlying storage first, then:

```bash
xfs_growfs /mountpoint
```

### 8. How do you grow ext4?

Expand the underlying storage first, then:

```bash
resize2fs /dev/DEVICE
```

### 9. How can a filesystem run out of space with free gigabytes?

It may have exhausted its inodes. Check `df -i`.

### 10. Why can `df` and `du` differ?

Deleted-but-open files, hidden data beneath a mount point, reserved blocks, metadata, permissions, and traversal boundaries.

### 11. How do you find deleted-but-open files?

```bash
lsof +L1
```

### 12. Why might a filesystem remount read-only?

The kernel may detect filesystem or storage errors and protect data by preventing writes.

### 13. Can you run filesystem repair on a mounted filesystem?

Filesystem-specific requirements apply, but repair tools commonly require the filesystem to be unmounted. Use offline recovery procedures.

### 14. What does `nofail` do?

It allows boot to continue when the mount fails. It should not be used to hide failure of critical storage.

### 15. What do `nodev`, `nosuid`, and `noexec` do?

They prevent device interpretation, SUID/SGID privilege effects, and direct execution respectively, providing defense in depth.

### 16. What is swap?

Disk-backed virtual memory used for inactive pages and memory headroom. It is slower than RAM and does not fix memory leaks.

### 17. What do `si` and `so` in `vmstat` mean?

Swap-in and swap-out activity.

### 18. What is the correct order for expanding an LVM filesystem?

Expand or attach storage, expand the partition if present, resize/create the physical volume, extend the volume group and logical volume, then grow the filesystem.

### 19. Why is shrinking more dangerous than growing?

Reducing a lower layer below the data or filesystem size can cause irreversible corruption and data loss.

### 20. How would you investigate a busy mount?

I would identify open files, processes, current working directories, nested mounts, and active swap with `fuser`, `lsof`, `findmnt`, and `swapon`, then stop dependencies safely before unmounting.

---

## 39. Quick Knowledge Check

### Questions

1. Which command displays the block-device tree?
2. Which command displays filesystem UUIDs?
3. What is the preferred modern partition-table format?
4. Which command creates an XFS filesystem?
5. Which command creates an ext4 filesystem?
6. Which command displays current mounts as a tree?
7. Which fstab field contains mount options?
8. Which command validates fstab?
9. Which command checks filesystem capacity?
10. Which command checks inode usage?
11. Can XFS be shrunk in place?
12. Which command grows a mounted XFS filesystem?
13. Which command grows ext4?
14. What commonly causes `df` usage to remain high after a large log is deleted?
15. Which command lists active swap?
16. Which command prepares a device for swap?
17. What should happen before `swapoff`?
18. Why use UUID instead of `/dev/sdb1` in fstab?
19. Should a read-only filesystem immediately be remounted read-write?
20. What must be expanded after the cloud disk if a partition and filesystem exist?

### Answer Key

1. `lsblk`
2. `blkid`
3. GPT
4. `mkfs.xfs`
5. `mkfs.ext4`
6. `findmnt`
7. Field 4
8. `findmnt --verify`
9. `df -hT`
10. `df -i`
11. No.
12. `xfs_growfs /mountpoint`
13. `resize2fs /dev/DEVICE`
14. A process still has the deleted file open.
15. `swapon --show`
16. `mkswap`
17. Confirm sufficient RAM and understand current swap use and application impact.
18. UUID is a more stable filesystem identity.
19. No. Investigate filesystem and storage errors first.
20. Expand the partition and then the filesystem, plus any intermediate LVM layer.

---

## 40. Interview Practice Exercises

### Exercise 1

> `/var` is full on a production server.

Cover:

- Blocks and inodes
- Large directories and files
- Deleted-but-open files
- Log rotation and retention
- Application ownership
- Safe mitigation
- Capacity or expansion plan

### Exercise 2

> An application mount prevents the server from completing boot.

Cover:

- Console access
- Journal and failed unit
- fstab source and options
- UUID and storage availability
- Critical versus optional mount
- Validation before reboot

### Exercise 3

> An AWS EBS volume was increased from 100 GiB to 200 GiB, but the application still sees 100 GiB.

Cover:

- Confirm cloud-side completion
- Identify the correct device
- Check partition
- Check LVM
- Identify filesystem type
- Expand each layer in order
- Validate and monitor

### Exercise 4

> XFS storage must be reduced from 2 TiB to 1 TiB.

Explain that XFS does not support in-place shrinking through standard tools. Propose creating a new smaller filesystem, copying and validating data, switching mounts with rollback, and retiring the old storage only after approval.

---

## 41. Engineer I vs. Engineer II Expectations

| Skill Area | Engineer I | Engineer II |
|---|---|---|
| Discovery | Uses `lsblk`, `df`, and `findmnt` | Maps cloud/SAN, partition, LVM, filesystem, and application layers |
| Mounts | Performs approved mounts | Designs stable fstab and dependency behavior |
| Capacity | Finds large files | Diagnoses blocks, inodes, open files, hidden data, and growth |
| Repair | Collects evidence and escalates | Plans offline checks, recovery, and validation |
| Swap | Inspects and enables approved swap | Tunes based on workload and memory behavior |
| Expansion | Follows runbook | Plans multi-layer online growth and rollback |
| Incidents | Reports symptoms | Leads recovery, RCA, and prevention |

---

## 42. Module Completion Checklist

- [ ] I can explain the Linux storage layers.
- [ ] I can identify disks, partitions, filesystems, and mounts.
- [ ] I can explain common device names.
- [ ] I understand GPT versus MBR.
- [ ] I can identify filesystem UUIDs and labels.
- [ ] I can explain XFS versus ext4.
- [ ] I can mount and safely unmount a filesystem.
- [ ] I can read all six fstab fields.
- [ ] I can validate fstab before reboot.
- [ ] I understand common mount options.
- [ ] I can investigate block and inode exhaustion.
- [ ] I can identify deleted-but-open files.
- [ ] I understand XFS and ext4 repair safety.
- [ ] I can inspect and manage swap.
- [ ] I understand storage-expansion order.
- [ ] I understand why storage shrink is high risk.
- [ ] I completed the loop-device lab.
- [ ] I answered the interview questions aloud.

---

## 43. Command Revision Sheet

```bash
lsblk
lsblk -f
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS
sudo blkid
sudo fdisk -l
sudo parted -l
findmnt
findmnt -T /path
findmnt --verify --verbose
ls -l /dev/disk/by-uuid/
sudo wipefs -n /dev/DEVICE
sudo partprobe /dev/DEVICE
sudo udevadm settle
sudo mkfs.xfs /dev/DEVICE
sudo mkfs.ext4 /dev/DEVICE
sudo xfs_admin -L LABEL /dev/DEVICE
sudo e2label /dev/DEVICE LABEL
sudo mount /dev/DEVICE /mountpoint
sudo umount /mountpoint
mountpoint /mountpoint
sudo fuser -vm /mountpoint
sudo lsof +D /mountpoint
df -hT
df -i
sudo du -xhd1 /path
sudo lsof +L1
sudo xfs_repair -n /dev/DEVICE
sudo e2fsck -f /dev/DEVICE
sudo xfs_growfs /mountpoint
sudo resize2fs /dev/DEVICE
swapon --show
free -h
vmstat 1 5
sudo mkswap /dev/DEVICE
sudo swapon /dev/DEVICE
sudo swapoff /dev/DEVICE
sysctl vm.swappiness
systemctl list-units --type=mount
journalctl -k
```

---

## Next Module

**Module 09 — LVM Administration and Storage Expansion**

Topics will include:

- Physical volumes, volume groups, and logical volumes
- LVM discovery and metadata
- Creating and extending LVM storage
- Online XFS and ext4 growth
- Adding disks to a volume group
- Moving data between physical volumes
- LVM snapshots and their limitations
- Safe logical-volume removal
- Recovery and metadata backup
- Production expansion scenarios
- File-backed LVM lab and interview questions

