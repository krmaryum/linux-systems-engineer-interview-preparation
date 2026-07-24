# Linux Systems Engineer II Interview Preparation

## Module 02 — Linux Filesystem Hierarchy and File Management

**Target role:** Linux Systems Engineer II  
**Primary platform:** Red Hat Enterprise Linux (RHEL)  
**Recommended study time:** 60–90 minutes  
**Practice environment:** RHEL, AlmaLinux, Rocky Linux, CentOS Stream, or an AWS EC2 Linux instance

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain the Linux filesystem hierarchy.
- Describe the purpose of important directories under `/`.
- Work safely with absolute and relative paths.
- Identify regular files, directories, links, devices, sockets, and named pipes.
- Explain filenames, inodes, and directory entries.
- Create and troubleshoot hard links and symbolic links.
- Copy, move, rename, and remove files safely.
- Search for files by name, owner, size, time, and type.
- Search inside files with `grep`.
- Investigate filesystem-capacity and inode-exhaustion problems.
- Detect deleted files that are still held open by processes.
- Explain `df`, `du`, `lsblk`, `findmnt`, `lsof`, and related commands in an interview.

---

## 2. Understanding the Linux Filesystem

Linux presents files, directories, devices, and mounted filesystems under one directory tree.

The top of that tree is:

```text
/
```

This is called the **root directory**. It is different from:

```text
/root
```

`/root` is the home directory of the `root` user.

### Important Difference

| Path | Meaning |
|---|---|
| `/` | Top of the entire Linux directory tree |
| `/root` | Home directory of the root user |
| `/home/khalid` | Example home directory of a regular user |

Linux can mount different storage devices and remote filesystems at directories within this single tree.

Example:

```text
/
├── /boot       → boot filesystem
├── /home       → local filesystem or separate disk
├── /data       → LVM volume or attached cloud disk
└── /mnt/share  → NFS network filesystem
```

Display mounted filesystems as a tree:

```bash
findmnt
```

---

## 3. Linux Filesystem Hierarchy

### 3.1 Important Directories

| Directory | Main Purpose |
|---|---|
| `/` | Root of the complete filesystem hierarchy |
| `/boot` | Kernel, initramfs, bootloader files, and boot configuration |
| `/dev` | Device files representing hardware and virtual devices |
| `/etc` | System-wide configuration files |
| `/home` | Home directories for regular users |
| `/root` | Home directory for the root user |
| `/run` | Runtime state created since boot, such as PID files and sockets |
| `/tmp` | Temporary files; commonly cleared automatically |
| `/usr` | Most user-space applications, libraries, documentation, and shared data |
| `/var` | Variable data such as logs, caches, queues, databases, and web content |
| `/opt` | Optional or third-party application software |
| `/srv` | Data served by system services |
| `/mnt` | Temporary or administrator-managed mount points |
| `/media` | Mount points for removable media |
| `/proc` | Virtual filesystem exposing process and kernel information |
| `/sys` | Virtual filesystem exposing devices, drivers, and kernel objects |

### 3.2 Important Subdirectories

| Directory | Main Purpose |
|---|---|
| `/etc/systemd/system` | Administrator-created or overridden systemd units |
| `/etc/ssh` | OpenSSH server and client configuration |
| `/etc/fstab` | Filesystems configured for mounting |
| `/var/log` | System and application logs |
| `/var/tmp` | Temporary files generally expected to survive reboots |
| `/var/lib` | Persistent variable state used by applications |
| `/var/cache` | Re-creatable application cache data |
| `/var/spool` | Queued work, such as mail or print jobs |
| `/usr/bin` | Most user commands |
| `/usr/sbin` | Most system-administration commands |
| `/usr/lib` and `/usr/lib64` | Shared libraries and application support files |
| `/usr/local` | Software installed locally by the administrator |

### 3.3 `/bin`, `/sbin`, and the Unified `/usr` Layout

On modern RHEL systems, these paths are commonly symbolic links:

```bash
ls -ld /bin /sbin /lib /lib64
```

Typical relationships:

```text
/bin   → /usr/bin
/sbin  → /usr/sbin
/lib   → /usr/lib
/lib64 → /usr/lib64
```

This is known as the unified `/usr` layout. You may still use commands through paths such as `/bin/bash`, even when `/bin` points to `/usr/bin`.

### 3.4 Virtual Filesystems

`/proc` and `/sys` do not normally contain ordinary files stored on disk.

Examples:

```bash
cat /proc/cpuinfo
cat /proc/meminfo
cat /proc/mounts
ls /proc/$$
ls /sys/class/net
```

- `/proc` exposes process and kernel information.
- `/sys` exposes devices, drivers, buses, and kernel objects.
- Much of this information is generated dynamically by the kernel.

---

## 4. Paths and Navigation

### 4.1 Absolute Path

An absolute path begins with `/` and identifies a location from the root directory.

Example:

```bash
/var/log/messages
```

### 4.2 Relative Path

A relative path is interpreted from the current working directory.

Example:

```bash
logs/application.log
```

### 4.3 Special Path Symbols

| Symbol | Meaning |
|---|---|
| `.` | Current directory |
| `..` | Parent directory |
| `~` | Current user’s home directory |
| `~username` | Named user’s home directory |
| `-` | Previous directory when used with `cd` |

Examples:

```bash
pwd
cd /var/log
cd ..
cd ~
cd -
```

### 4.4 Canonical and Resolved Paths

Display an absolute, normalized path:

```bash
realpath file_name
```

Resolve a command through `PATH`:

```bash
command -v ls
type -a ls
```

---

## 5. Linux File Types

Linux uses several file types. The first character of `ls -l` output identifies the type.

```bash
ls -l
```

| Character | File Type |
|---|---|
| `-` | Regular file |
| `d` | Directory |
| `l` | Symbolic link |
| `b` | Block device |
| `c` | Character device |
| `p` | Named pipe, also called a FIFO |
| `s` | Socket |

Examples:

```bash
ls -l /etc/hosts
ls -ld /etc
ls -l /dev/null
ls -l /dev/sda 2>/dev/null
```

Use `file` to inspect content type:

```bash
file /etc/hosts
file /usr/bin/ls
file script.sh
```

The `file` command examines content and metadata. It does not rely only on the filename extension.

---

## 6. Filenames, Directory Entries, and Inodes

### 6.1 What Is an Inode?

An inode is a filesystem data structure that stores metadata about a file.

An inode commonly stores:

- File type
- Permissions
- Owner and group IDs
- File size
- Timestamps
- Link count
- Pointers to the file’s data blocks

The filename is stored in a directory entry that maps the name to an inode number.

### 6.2 What an Inode Does Not Store

An inode does not normally store:

- The filename
- The full path

A directory connects a filename to an inode number.

### 6.3 Display Inode Numbers

```bash
ls -li
```

Display detailed metadata:

```bash
stat file_name
```

### 6.4 File Timestamps

`stat` commonly shows:

| Timestamp | Meaning |
|---|---|
| Access | Last time file data was accessed, subject to mount options |
| Modify | Last time file content was modified |
| Change | Last time inode metadata or file content changed |
| Birth | File creation time when supported by the filesystem |

Linux `ctime` means **change time**, not creation time.

### 6.5 Inode Exhaustion

A filesystem can have free disk space but still be unable to create new files if all available inodes are used.

Check disk capacity:

```bash
df -h
```

Check inode usage:

```bash
df -i
```

Large numbers of small files—such as session files, cache entries, mail queues, or unrotated application files—can exhaust inodes.

---

## 7. Hard Links and Symbolic Links

### 7.1 Hard Link

A hard link is another filename pointing to the same inode and file data.

Create one:

```bash
ln original.txt hard-link.txt
```

Verify inode numbers:

```bash
ls -li original.txt hard-link.txt
```

Both names should show the same inode number.

### 7.2 Symbolic Link

A symbolic link is a separate file containing a path to another file or directory.

Create one:

```bash
ln -s original.txt symbolic-link.txt
```

Inspect it:

```bash
ls -li original.txt symbolic-link.txt
readlink symbolic-link.txt
readlink -f symbolic-link.txt
```

### 7.3 Comparison

| Feature | Hard Link | Symbolic Link |
|---|---|---|
| Shares target inode | Yes | No |
| Can link to a directory normally | No | Yes |
| Can cross filesystems | No | Yes |
| Works if original filename is removed | Yes | No, unless target remains reachable at the stored path |
| Has its own inode | No separate target data inode | Yes |
| Can become broken | Not in the same way | Yes |

### 7.4 Important Interview Point

Removing a filename does not necessarily delete the file data immediately. The data is released when:

- The inode’s hard-link count becomes zero, and
- No process still has the file open.

---

## 8. Creating Files and Directories

Create an empty file or update timestamps:

```bash
touch file1.txt
```

Create a directory:

```bash
mkdir reports
```

Create a parent structure:

```bash
mkdir -p project/logs/archive
```

Create multiple files:

```bash
touch file1.txt file2.txt file3.txt
```

Create a file with controlled content:

```bash
printf '%s\n' 'Linux Systems Engineer' > role.txt
```

Append content:

```bash
printf '%s\n' 'Module 02' >> role.txt
```

---

## 9. Copying, Moving, and Renaming

### 9.1 Copy Files

```bash
cp source.txt destination.txt
```

Copy a directory recursively while preserving common metadata:

```bash
cp -a source_directory destination_directory
```

`cp -a` is commonly preferred for administrator copies because archive mode preserves attributes and copies directories recursively.

### 9.2 Interactive and No-Clobber Options

Prompt before overwrite:

```bash
cp -i source.txt destination.txt
```

Do not overwrite an existing destination:

```bash
cp -n source.txt destination.txt
```

Be aware that aliases and behavior can vary. For scripts, use explicit options and perform validation.

### 9.3 Move or Rename

```bash
mv old-name.txt new-name.txt
```

Move a file into a directory:

```bash
mv report.txt reports/
```

Prompt before replacing:

```bash
mv -i source.txt destination.txt
```

### 9.4 Preserve Evidence Before Editing

Before modifying a production configuration file:

```bash
sudo cp -a /etc/ssh/sshd_config \
    /etc/ssh/sshd_config.backup-$(date +%F-%H%M%S)
```

Then validate the configuration before reloading the service:

```bash
sudo sshd -t
```

This example will be covered in more detail in the SSH module.

---

## 10. Removing Files Safely

Remove a regular file:

```bash
rm file.txt
```

Prompt before removal:

```bash
rm -i file.txt
```

Remove an empty directory:

```bash
rmdir empty_directory
```

Recursively remove a known directory tree:

```bash
rm -r specific_directory
```

### Production Safety Checklist

Before deleting:

1. Confirm the current directory:

   ```bash
   pwd
   ```

2. Display the exact target:

   ```bash
   ls -ld -- /exact/path/to/target
   ```

3. Check whether it is a mount point:

   ```bash
   findmnt --target /exact/path/to/target
   mountpoint /exact/path/to/target
   ```

4. Check size and contents:

   ```bash
   du -sh -- /exact/path/to/target
   find /exact/path/to/target -maxdepth 1 -mindepth 1 -ls
   ```

5. Confirm retention, backup, ownership, and authorization.

6. Prefer moving data to an approved quarantine or recovery location when practical.

Avoid dangerous deletion commands that use:

- Unverified variables
- Broad wildcard patterns
- Ambiguous relative paths
- Unexpected mount points
- Production paths without approval

---

## 11. Viewing and Inspecting Files

| Purpose | Command |
|---|---|
| Display a short file | `cat file.txt` |
| View page by page | `less file.txt` |
| First lines | `head file.txt` |
| Last lines | `tail file.txt` |
| Follow new log entries | `tail -f file.log` |
| Follow across log rotation more reliably | `tail -F file.log` |
| Count lines, words, and bytes | `wc file.txt` |
| Display numbered lines | `nl -ba file.txt` |
| Identify content type | `file file.txt` |
| Display metadata | `stat file.txt` |
| Display hexadecimal content | `hexdump -C file.bin` |

Use `less` for large files instead of loading everything into an editor.

Useful `less` controls:

| Key | Action |
|---|---|
| `/pattern` | Search forward |
| `n` | Next match |
| `N` | Previous match |
| `G` | End of file |
| `g` | Beginning of file |
| `q` | Quit |

---

## 12. Searching for Files with `find`

General structure:

```bash
find SEARCH_PATH TESTS ACTIONS
```

### 12.1 Search by Name

Case-sensitive:

```bash
find /etc -name 'sshd_config'
```

Case-insensitive:

```bash
find /var/log -iname '*.log'
```

Quote wildcard patterns so the shell does not expand them before `find` receives them.

### 12.2 Search by Type

Regular files:

```bash
find /var/log -type f
```

Directories:

```bash
find /etc -type d
```

Symbolic links:

```bash
find /usr/local -type l
```

Broken symbolic links:

```bash
find /path -xtype l
```

### 12.3 Search by Size

Files larger than 1 GiB:

```bash
find /var -xdev -type f -size +1G -print
```

Files smaller than 1 MiB:

```bash
find /path -type f -size -1M -print
```

`-xdev` prevents crossing into other filesystems mounted below the search path.

### 12.4 Search by Time

Modified within the last 24 hours:

```bash
find /var/log -type f -mtime -1 -print
```

Modified more than 30 days ago:

```bash
find /var/log -type f -mtime +30 -print
```

Modified within the last 60 minutes:

```bash
find /var/log -type f -mmin -60 -print
```

### 12.5 Search by Owner or Group

```bash
find /home -user khalid -print
find /srv -group developers -print
```

Files with no valid owner:

```bash
find / -xdev -nouser -print 2>/dev/null
```

Files with no valid group:

```bash
find / -xdev -nogroup -print 2>/dev/null
```

### 12.6 Safe Actions

Display details:

```bash
find /var/log -type f -size +100M -ls
```

Run one command per result:

```bash
find /path -type f -name '*.conf' -exec ls -l -- {} \;
```

Pass multiple results per command:

```bash
find /path -type f -name '*.log' -exec du -h -- {} +
```

Never add `-delete` until you have tested the exact same selection with `-print` and confirmed the scope.

---

## 13. `locate` vs. `find`

`find` searches the live filesystem.

`locate` searches a previously built filename database and is often faster, but results may be outdated.

Examples:

```bash
locate sshd_config
sudo updatedb
```

On RHEL-family systems, `locate` may be provided by the `plocate` or `mlocate` package, depending on the release and repository.

Interview summary:

- Use `find` for accurate, current, attribute-based searches.
- Use `locate` for fast filename searches when its database is available and current.

---

## 14. Searching Inside Files with `grep`

Search for text:

```bash
grep 'PermitRootLogin' /etc/ssh/sshd_config
```

Ignore case:

```bash
grep -i 'error' application.log
```

Show line numbers:

```bash
grep -n 'error' application.log
```

Search recursively:

```bash
grep -Rni 'timeout' /etc/application/
```

Show lines that do not match:

```bash
grep -v '^#' configuration.conf
```

Ignore blank lines and comments:

```bash
grep -Ev '^[[:space:]]*(#|$)' configuration.conf
```

Use extended regular expressions:

```bash
grep -E 'error|warning|critical' application.log
```

---

## 15. Disk-Usage Investigation

### 15.1 Understand the Commands

| Command | Answers |
|---|---|
| `lsblk` | Which block devices and partitions exist? |
| `findmnt` | What is mounted, where, and with which options? |
| `df -hT` | How much filesystem capacity is used? |
| `df -i` | How many inodes are used? |
| `du -xsh PATH` | How much visible space does a directory tree use on one filesystem? |
| `lsof +L1` | Which deleted files are still open? |

### 15.2 Start at the Filesystem Level

```bash
df -hT
df -i
```

Identify:

- Full filesystem
- Filesystem type
- Mount point
- Capacity usage
- Inode usage

### 15.3 Find Large Directories

For the root filesystem only:

```bash
sudo du -xhd1 / 2>/dev/null | sort -h
```

For `/var`:

```bash
sudo du -xhd1 /var 2>/dev/null | sort -h
```

`-x` keeps `du` on one filesystem.

### 15.4 Find Large Files

Files over 1 GiB on the root filesystem:

```bash
sudo find / -xdev -type f -size +1G -ls 2>/dev/null
```

### 15.5 Check Deleted-but-Open Files

```bash
sudo lsof +L1
```

Alternative:

```bash
sudo lsof | grep '(deleted)'
```

A process may continue holding disk blocks after a log file has been deleted. In that case:

- `df` still reports the blocks as used.
- `du` cannot see the deleted filename.
- `lsof` can identify the process and open file descriptor.

The safe solution is usually to make the owning application close or reopen the file, commonly through an approved service reload or restart. Do not kill a production process without impact analysis and authorization.

---

## 16. Why `df` and `du` Can Disagree

`df` reports space allocated by the filesystem.

`du` walks visible directory entries and adds the blocks used by accessible files.

Differences can be caused by:

- Deleted files still open by processes
- Files hidden beneath a mount point
- Reserved filesystem blocks
- Filesystem metadata
- Permission-denied paths during `du`
- `du` crossing or not crossing mount boundaries
- Sparse files and different block-counting options

### Investigation Sequence

```bash
df -hT
sudo du -xsh /path
sudo lsof +L1
findmnt
```

Do not assume that deleting more visible files will solve the issue until you understand the difference.

---

## 17. Hidden Files Beneath a Mount Point

Suppose files were written into `/data` before another filesystem was mounted there. After mounting, the original files become hidden by the mounted filesystem but still consume space on the underlying filesystem.

Check the mount:

```bash
findmnt /data
```

Investigating hidden files may require a planned maintenance procedure, such as:

- Stopping applications that use the mount
- Unmounting safely, or
- Bind-mounting the underlying filesystem elsewhere

Do not unmount a production filesystem only to inspect it without checking active users, dependencies, and change approval.

---

## 18. Open Files and Processes

Show processes using a path:

```bash
sudo lsof /path/to/file
sudo lsof +D /path/to/directory
```

`lsof +D` can be expensive on a large directory tree.

Show processes using a filesystem:

```bash
sudo fuser -vm /mountpoint
```

Show processes using a specific file:

```bash
sudo fuser -v /path/to/file
```

These commands are helpful before:

- Unmounting storage
- Replacing application files
- Investigating deleted logs
- Performing maintenance

---

## 19. Hands-On Lab

### Lab Objective

Practice navigation, file types, inodes, links, searches, and disk-usage investigation in a safe directory.

### Step 1 — Create the Lab

```bash
mkdir -p ~/linux-engineer-prep/module-02/{config,logs,data,archive}
cd ~/linux-engineer-prep/module-02
```

Confirm:

```bash
pwd
find . -maxdepth 2 -print
```

### Step 2 — Create Sample Files

```bash
printf '%s\n' \
    'server_name=web01' \
    'environment=production' \
    'log_level=warning' > config/application.conf

printf '%s\n' \
    'INFO application started' \
    'WARNING disk usage reached 80 percent' \
    'ERROR database connection timed out' > logs/application.log

touch data/file-{01..10}.txt
```

### Step 3 — Inspect File Types and Metadata

```bash
file config/application.conf
stat config/application.conf
ls -li config/application.conf
```

### Step 4 — Create Links

```bash
ln config/application.conf config/application-hard.conf
ln -s application.conf config/application-symbolic.conf
```

Compare:

```bash
ls -li config/
readlink config/application-symbolic.conf
readlink -f config/application-symbolic.conf
```

Questions:

1. Which two names share the same inode?
2. Which link has its own inode?
3. What happens to each link if `application.conf` is removed?

### Step 5 — Create a Broken Symbolic Link

```bash
ln -s missing.conf config/broken.conf
find config -xtype l -ls
```

Remove only the broken link:

```bash
rm config/broken.conf
```

### Step 6 — Search by Name and Type

```bash
find . -type f -name '*.conf' -print
find . -type f -name '*.log' -print
find . -type l -ls
```

### Step 7 — Search Inside Files

```bash
grep -Rni 'warning\|error' logs/
grep -Ev '^[[:space:]]*(#|$)' config/application.conf
```

### Step 8 — Check Usage

```bash
du -sh .
du -h --max-depth=1 .
df -hT .
df -i .
```

### Step 9 — Archive a Copy Safely

```bash
cp -a config/application.conf \
    "archive/application.conf.$(date +%F-%H%M%S)"
```

Confirm:

```bash
ls -l archive/
```

### Step 10 — Practice Safe Removal

Create a temporary target:

```bash
mkdir -p data/to-remove
touch data/to-remove/test-{1..3}.txt
```

Inspect before removal:

```bash
pwd
ls -ld -- "$PWD/data/to-remove"
find "$PWD/data/to-remove" -maxdepth 1 -mindepth 1 -ls
du -sh -- "$PWD/data/to-remove"
```

Remove the exact lab target:

```bash
rm -r -- "$PWD/data/to-remove"
```

Verify:

```bash
test ! -e "$PWD/data/to-remove" && echo "Lab target removed"
```

### Lab Deliverables

Your lab should contain:

```text
module-02/
├── archive/
│   └── application.conf.DATE-TIME
├── config/
│   ├── application-hard.conf
│   ├── application-symbolic.conf -> application.conf
│   └── application.conf
├── data/
│   ├── file-01.txt
│   └── ...
└── logs/
    └── application.log
```

---

## 20. Production Troubleshooting Scenarios

### Scenario 1 — `/var` Is 100% Full

Start with:

```bash
df -hT /var
df -i /var
sudo du -xhd1 /var 2>/dev/null | sort -h
sudo find /var -xdev -type f -size +500M -ls 2>/dev/null
sudo lsof +L1
```

Investigate:

- Large logs
- Failed log rotation
- Application data growth
- Package caches
- Crash dumps
- Temporary files
- Deleted-but-open files
- Inode exhaustion

Do not blindly delete logs. Confirm retention requirements, application ownership, and the approved remediation.

### Scenario 2 — `df` Shows 95%, but `du` Shows Much Less

Likely causes include:

- Deleted-but-open files
- Hidden files beneath mount points
- Reserved blocks
- Permission or traversal differences

Check:

```bash
sudo lsof +L1
findmnt
sudo du -xsh /
df -hT /
```

### Scenario 3 — “No Space Left on Device” with Free Gigabytes

Check inode usage:

```bash
df -i
```

If inode usage is 100%, locate directories with huge file counts:

```bash
sudo du --inodes -x -d1 /var 2>/dev/null | sort -n
```

Then investigate the affected application and retention policy.

### Scenario 4 — Configuration Link Is Broken

Inspect:

```bash
ls -l /path/to/link
readlink /path/to/link
readlink -f /path/to/link
find /path -xtype l -ls
```

Determine whether:

- The target was moved or renamed
- A relative link resolves from the link’s directory
- The target filesystem is not mounted
- Deployment created the wrong path

### Scenario 5 — Filesystem Cannot Be Unmounted

Check:

```bash
findmnt /mountpoint
sudo fuser -vm /mountpoint
sudo lsof /mountpoint
```

Identify:

- Processes with open files
- Shells whose current directory is inside the mount
- Services using the filesystem
- Nested mounts

Do not use forced or lazy unmount options as a routine shortcut. Understand the dependencies and impact first.

---

## 21. Common Interview Questions and Answers

### 1. What is the difference between `/` and `/root`?

`/` is the top of the entire filesystem hierarchy. `/root` is the home directory of the root user.

### 2. What is normally stored in `/etc`?

System-wide configuration files, service configuration, user and authentication databases, network configuration, and other administrative settings.

### 3. What is the purpose of `/var`?

It contains variable data that changes while the system runs, including logs, caches, application state, queues, databases, and web or service data.

### 4. What is an inode?

An inode is a filesystem data structure containing file metadata and references to data blocks. A directory entry maps a filename to an inode number.

### 5. Does an inode contain the filename?

No. The filename is stored in a directory entry that points to the inode.

### 6. What is the difference between a hard link and a symbolic link?

A hard link is another directory entry for the same inode. A symbolic link is a separate file containing a path to another object.

### 7. Can a hard link cross filesystems?

No, because inode numbers are meaningful only within a particular filesystem. A symbolic link can reference a path on another filesystem.

### 8. What happens if the original name of a hard-linked file is deleted?

The data remains available through the other hard link because the inode still has a positive link count.

### 9. What happens if the target of a symbolic link is deleted?

The symbolic link remains but becomes broken because its stored target path no longer resolves.

### 10. What is the difference between `df` and `du`?

`df` reports allocated and available space from filesystem metadata. `du` walks visible directory entries and totals file usage.

### 11. Why can `df` show more used space than `du`?

Common reasons include deleted-but-open files, hidden files beneath a mount point, reserved blocks, filesystem metadata, or incomplete traversal by `du`.

### 12. How do you find deleted files still held open?

```bash
sudo lsof +L1
```

### 13. How can a filesystem run out of space when `df -h` shows free space?

Its inodes may be exhausted. Check:

```bash
df -i
```

### 14. How do you find files larger than 1 GiB without crossing filesystems?

```bash
find /search/path -xdev -type f -size +1G -ls
```

### 15. Why should the wildcard in `find -name '*.log'` be quoted?

Quoting prevents the shell from expanding the wildcard before `find` processes it.

### 16. What does `find -xdev` do?

It prevents `find` from descending into directories located on other filesystems.

### 17. What is the difference between `tail -f` and `tail -F`?

`tail -f` follows the open file. `tail -F` also retries by filename and is generally more resilient when a log is rotated or replaced.

### 18. What checks would you perform before deleting a large directory?

I would verify the exact path, inspect the contents and size, check whether it is a mount point, identify active processes, confirm ownership and retention requirements, confirm backup or recovery options, and obtain required authorization.

### 19. How would you investigate a full `/var` filesystem?

I would check both block and inode usage, identify large directories and files without crossing filesystems, check deleted-but-open files, examine logs and application growth, review retention and log rotation, and remediate through the approved incident or change process.

### 20. Why is `/proc` called a virtual filesystem?

Its contents are generated dynamically by the kernel and expose process and system information rather than representing ordinary files stored on disk.

---

## 22. Quick Knowledge Check

### Questions

1. What is the difference between `/` and `/root`?
2. Which directory normally contains system-wide configuration?
3. Which directory normally contains logs?
4. Which command shows inode numbers?
5. Does an inode store the filename?
6. Which link type shares the same inode as its target?
7. Which link type can cross filesystem boundaries?
8. Which command displays filesystem capacity?
9. Which command displays inode usage?
10. Which command identifies deleted-but-open files?
11. Why can `df` and `du` report different usage?
12. What does `find -xdev` prevent?
13. Which command displays mounted filesystems as a tree?
14. Why should wildcard patterns passed to `find` be quoted?
15. What should you do before using `find ... -delete`?

### Answer Key

1. `/` is the top of the filesystem tree; `/root` is the root user’s home directory.
2. `/etc`
3. `/var/log`
4. `ls -i` or `ls -li`
5. No. A directory entry maps the filename to the inode.
6. A hard link
7. A symbolic link
8. `df -hT`
9. `df -i`
10. `lsof +L1`
11. Causes include deleted-but-open files, hidden files beneath mounts, reserved blocks, filesystem metadata, or incomplete traversal.
12. Crossing into other filesystems
13. `findmnt`
14. To prevent the shell from expanding the wildcard before `find` receives it.
15. Test the exact selection with `-print`, review every target, and confirm authorization and recovery requirements.

---

## 23. Interview Practice Exercises

Answer each question aloud in 60–90 seconds.

### Exercise 1

> A production filesystem is 100% full. Explain your investigation.

Your response should cover:

- Business impact and affected service
- `df -hT` and `df -i`
- Mount point and filesystem identification
- Large-directory and large-file searches
- Deleted-but-open files
- Recent changes and application growth
- Retention and backup requirements
- Safe mitigation
- Validation and documentation

### Exercise 2

> `df` reports 90 GB used, but `du` finds only 40 GB. What could cause this?

Your response should mention:

- Deleted-but-open files
- Files hidden below mount points
- Reserved blocks and filesystem metadata
- Permissions or excluded mount traversal
- `lsof +L1`, `findmnt`, and controlled investigation

### Exercise 3

> An application reports “No space left on device,” but the filesystem has free capacity.

Your response should include:

- Inode exhaustion
- `df -i`
- High counts of small files
- Application caches, sessions, queues, or temporary files
- Retention and cleanup controls

---

## 24. Module Completion Checklist

Mark each item when you can complete it without assistance:

- [ ] I can explain the difference between `/` and `/root`.
- [ ] I can describe the purpose of important Linux directories.
- [ ] I understand modern RHEL’s unified `/usr` layout.
- [ ] I can use absolute and relative paths.
- [ ] I can recognize Linux file types from `ls -l`.
- [ ] I can explain what an inode stores.
- [ ] I can explain hard links and symbolic links.
- [ ] I can copy and move files while preserving data safely.
- [ ] I can verify an exact target before deleting it.
- [ ] I can search by name, type, size, owner, and modification time.
- [ ] I can search file content with `grep`.
- [ ] I can explain the difference between `df` and `du`.
- [ ] I can check both block capacity and inode usage.
- [ ] I can locate deleted-but-open files.
- [ ] I can investigate a full production filesystem methodically.
- [ ] I completed the hands-on lab.
- [ ] I answered the interview questions aloud.

---

## 25. Command Revision Sheet

```bash
pwd
cd /path
cd ..
cd ~
cd -
realpath file
ls -lah
ls -li
stat file
file file
touch file
mkdir directory
mkdir -p parent/child
cp source destination
cp -a source_directory destination_directory
mv old_name new_name
rm -i file
rmdir empty_directory
findmnt
findmnt --target /path
mountpoint /path
lsblk
df -hT
df -i
du -sh /path
du -xhd1 /path
find /path -xdev -type f -size +1G -ls
find /path -type f -mtime -1 -print
find /path -xtype l -ls
grep -Rni 'pattern' /path
ln original hard-link
ln -s target symbolic-link
readlink symbolic-link
readlink -f symbolic-link
sudo lsof +L1
sudo fuser -vm /mountpoint
```

---

## Next Module

**Module 03 — Users, Groups, sudo, and Password Policies**

Topics will include:

- Local user and group databases
- `useradd`, `usermod`, `userdel`, `groupadd`, and `passwd`
- Primary and supplementary groups
- UID and GID management
- Password aging and account locking
- `sudo` and least privilege
- Safe editing with `visudo`
- Login shells and home directories
- Enterprise user-management troubleshooting
- Interview scenarios and a practical lab
