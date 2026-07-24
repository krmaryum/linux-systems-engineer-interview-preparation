# Linux Systems Engineer II Interview Preparation

## Module 04 — Linux Permissions, ACLs, SUID, SGID, and Sticky Bit

**Target role:** Linux Systems Engineer II  
**Primary platform:** Red Hat Enterprise Linux (RHEL)  
**Recommended study time:** 75–90 minutes  
**Practice environment:** A disposable RHEL, AlmaLinux, Rocky Linux, or CentOS Stream virtual machine

> Complete the practical work only in the lab directory created in this module. Do not recursively change permissions or ownership on system or production directories.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Read and explain Linux ownership and permission strings.
- Distinguish permissions for users, groups, and others.
- Use symbolic and octal permission notation.
- Explain how permissions behave differently on files and directories.
- Change ownership safely with `chown` and `chgrp`.
- Calculate and troubleshoot default permissions using `umask`.
- Configure and inspect POSIX Access Control Lists.
- Explain the ACL mask and default ACL inheritance.
- Explain SUID, SGID, and sticky-bit behavior.
- Build a secure shared-team directory.
- Audit dangerous permissions and special bits.
- Troubleshoot access failures involving DAC permissions, ACLs, mount options, NFS, and SELinux.
- Answer senior Linux permission interview questions.

---

## 2. Linux Discretionary Access Control

Traditional Linux permissions are part of **Discretionary Access Control**, commonly abbreviated as DAC.

Every filesystem object normally has:

- An owning user
- An owning group
- Permission bits for the owner
- Permission bits for the group class
- Permission bits for everyone else

Display:

```bash
ls -l file_name
```

Example:

```text
-rw-r----- 1 khalid linuxadmins 2048 Jul 25 10:30 report.txt
```

Breakdown:

```text
-  rw-  r--  ---  1  khalid  linuxadmins  2048  Jul 25 10:30  report.txt
│   │    │    │
│   │    │    └── permissions for others
│   │    └─────── permissions for the group class
│   └──────────── permissions for the owner
└──────────────── file type
```

The effective access may also be affected by:

- POSIX ACLs
- SELinux
- Filesystem mount options
- NFS export rules and identity mapping
- Application-level security
- Read-only storage

Passing the traditional mode-bit check does not guarantee that every other security layer will allow access.

---

## 3. Permission Classes

| Class | Symbol | Meaning |
|---|---|---|
| User/owner | `u` | The file’s owning user |
| Group | `g` | The owning group and, with ACLs, the group class |
| Others | `o` | Users who do not match the owner or applicable group entries |
| All | `a` | User, group, and others |

Display owner and group:

```bash
stat -c '%U %G %A %a %n' file_name
```

Example:

```text
khalid linuxadmins -rw-r----- 640 report.txt
```

---

## 4. Read, Write, and Execute

### 4.1 Permissions on Regular Files

| Permission | Symbol | Effect on a Regular File |
|---|---|---|
| Read | `r` | Read the file’s contents |
| Write | `w` | Modify or truncate the file’s contents |
| Execute | `x` | Run the file as a program or script when other requirements are met |

Important:

- Write permission on a file does not automatically grant permission to delete it.
- Deleting or renaming a file is controlled mainly by the parent directory.
- Execute permission alone does not make invalid content executable.
- A script also needs a valid interpreter and shebang when executed directly.

### 4.2 Permissions on Directories

| Permission | Symbol | Effect on a Directory |
|---|---|---|
| Read | `r` | List the names stored in the directory |
| Write | `w` | Create, delete, or rename entries, normally with execute permission |
| Execute | `x` | Traverse/search the directory and access known entries |

### 4.3 Directory Permission Examples

#### Read without Execute

A user may see filenames but cannot normally access file metadata or contents through the directory.

#### Execute without Read

A user may access a known filename if permissions on the object allow it, but cannot list the directory normally.

#### Write and Execute

A user may create, rename, and delete directory entries. This can allow deletion of a file even if the user cannot modify the file’s content.

### Essential Interview Statement

> File deletion is primarily controlled by write and execute permissions on the parent directory, not by write permission on the file itself.

---

## 5. Symbolic Permission Notation

General format:

```text
chmod WHO OPERATION PERMISSIONS TARGET
```

Operations:

| Symbol | Meaning |
|---|---|
| `+` | Add permissions |
| `-` | Remove permissions |
| `=` | Set exact permissions for the selected class |

Examples:

```bash
chmod u+x script.sh
chmod g+w report.txt
chmod o-r secret.txt
chmod u=rw,g=r,o= file.txt
chmod a+r README.md
```

Remove all permissions for others:

```bash
chmod o= confidential.txt
```

Copy permissions from one class to another:

```bash
chmod g=u file.txt
```

---

## 6. Octal Permission Notation

Permission values:

| Permission | Value |
|---|---:|
| Read | `4` |
| Write | `2` |
| Execute | `1` |

Add the values for each class:

| Value | Symbolic Form | Meaning |
|---:|---|---|
| `0` | `---` | No permission |
| `1` | `--x` | Execute |
| `2` | `-w-` | Write |
| `3` | `-wx` | Write and execute |
| `4` | `r--` | Read |
| `5` | `r-x` | Read and execute |
| `6` | `rw-` | Read and write |
| `7` | `rwx` | Read, write, and execute |

### Common Modes

| Mode | Symbolic Form | Typical Use |
|---:|---|---|
| `600` | `rw-------` | Private file |
| `640` | `rw-r-----` | Owner writes, group reads |
| `644` | `rw-r--r--` | Common non-secret file |
| `700` | `rwx------` | Private directory or executable |
| `750` | `rwxr-x---` | Owner full, group read/traverse |
| `755` | `rwxr-xr-x` | Common public directory or executable |
| `770` | `rwxrwx---` | Shared group directory |

Examples:

```bash
chmod 640 report.txt
chmod 750 admin-script.sh
chmod 700 private-directory
```

### Avoid Careless `777`

```bash
chmod 777 target
```

This grants read, write, and execute to everyone. It is rarely an appropriate fix for a production access problem and can create serious security and integrity risks.

Investigate the required owner, group, ACL, service identity, and SELinux policy instead.

---

## 7. Ownership Management

### 7.1 Change Owner

```bash
sudo chown ali report.txt
```

### 7.2 Change Owner and Group

```bash
sudo chown ali:linuxadmins report.txt
```

### 7.3 Change Only the Group

```bash
sudo chgrp linuxadmins report.txt
```

or:

```bash
sudo chown :linuxadmins report.txt
```

### 7.4 Recursive Changes

```bash
sudo chown -R ali:linuxadmins /exact/lab/path
```

Recursive ownership changes are high risk. Before using them:

- Verify the exact path.
- Check whether it contains mount points.
- Inspect representative files.
- Confirm whether mixed ownership is intentional.
- Record the original state or backup metadata.
- Test on a limited scope.

### 7.5 Avoid Following Unexpected Links

When changing trees, understand how the command treats symbolic links and command-line arguments. Do not run bulk ownership changes on a directory tree that you have not inspected.

---

## 8. How Linux Selects Permission Classes

For traditional permissions, Linux does not simply choose the most generous matching class.

A simplified evaluation is:

1. If the process UID matches the file owner, use the owner permissions.
2. Otherwise, if a process group matches the file’s group class, use the applicable group permissions.
3. Otherwise, use the other permissions.

Example:

```text
-r-----r-- 1 ali developers file.txt
```

If user `ali` owns the file, the owner bits apply. The system does not fall through to the more permissive `other` read bit if the owner bits deny the requested action.

ACLs add named users, named groups, and a mask, but the same principle remains: access is evaluated through defined classes rather than by choosing whichever entry is most permissive.

---

## 9. Understanding `umask`

`umask` removes permission bits from the maximum permissions requested during file or directory creation.

Display:

```bash
umask
umask -S
```

Typical maximum starting modes:

- Regular files: `666`
- Directories: `777`

Regular files do not normally start with execute permission merely because the umask permits it.

### 9.1 Common Example: `umask 022`

```text
File:      666 with mask 022 → 644
Directory: 777 with mask 022 → 755
```

### 9.2 More Restrictive Example: `umask 027`

```text
File:      666 with mask 027 → 640
Directory: 777 with mask 027 → 750
```

### 9.3 Private Example: `umask 077`

```text
File:      666 with mask 077 → 600
Directory: 777 with mask 077 → 700
```

Set for the current shell:

```bash
umask 027
```

### Important Detail

The common “subtraction” explanation is a shortcut. Technically, the umask clears specified permission bits. Bitwise calculation gives the reliable result.

### 9.4 Where `umask` May Be Configured

Possible locations include:

- `/etc/profile`
- `/etc/bashrc`
- User shell startup files
- `/etc/login.defs`
- PAM configuration
- Application startup scripts
- systemd unit setting `UMask=`

A service started by systemd may not use the same umask as an interactive shell.

Inspect a unit:

```bash
systemctl cat SERVICE_NAME
systemctl show SERVICE_NAME -p UMask
```

---

## 10. Access Control Lists

Traditional mode bits allow one owner, one owning group, and others.

POSIX ACLs allow additional named users and groups without changing the main owner or group.

Common tools:

```bash
getfacl
setfacl
```

On RHEL-family systems, these tools are commonly provided by the `acl` package.

### 10.1 View an ACL

```bash
getfacl report.txt
```

Example:

```text
# file: report.txt
# owner: ali
# group: developers
user::rw-
user:sara:r--
group::r--
mask::r--
other::---
```

### 10.2 Add a Named User ACL

```bash
setfacl -m u:sara:r-- report.txt
```

### 10.3 Add a Named Group ACL

```bash
setfacl -m g:auditors:r-- report.txt
```

### 10.4 Remove One ACL Entry

```bash
setfacl -x u:sara report.txt
```

### 10.5 Remove Extended ACL Entries

```bash
setfacl -b report.txt
```

This removes extended ACL entries. Review the current ACL first.

### 10.6 ACL Indicator in `ls`

```bash
ls -l report.txt
```

A `+` after the permission string commonly indicates an extended ACL:

```text
-rw-r-----+ 1 ali developers 1024 Jul 25 11:00 report.txt
```

Use `getfacl` for the complete effective policy.

---

## 11. The ACL Mask

The ACL mask limits the effective permissions of:

- Named user entries
- The owning group entry
- Named group entries

The mask does not limit:

- The file owner entry
- The other entry

Example:

```text
user:sara:rwx
mask::r-x
```

Effective access for `sara` is:

```text
r-x
```

Even though the named entry says `rwx`, the mask removes effective write permission.

Display:

```bash
getfacl file_name
```

Example output may annotate:

```text
user:sara:rwx                 #effective:r-x
mask::r-x
```

Set the mask:

```bash
setfacl -m m::r-x file_name
```

### Essential Troubleshooting Point

When a named ACL entry appears correct but access still fails, inspect the ACL mask.

---

## 12. Default ACLs and Inheritance

Default ACLs apply to directories and provide inherited ACL entries for newly created children.

### 12.1 Set a Default Group ACL

```bash
setfacl -m d:g:projectteam:rwx /srv/project
```

### 12.2 Set Access and Default ACLs Together

```bash
setfacl -m g:projectteam:rwx /srv/project
setfacl -m d:g:projectteam:rwx /srv/project
```

The access ACL controls the current directory.

The default ACL controls inheritance by newly created files and subdirectories.

### 12.3 Inspect

```bash
getfacl /srv/project
```

### 12.4 Remove Default ACLs

```bash
setfacl -k /srv/project
```

### Important Limitations

- Existing files do not automatically receive a newly added default ACL.
- New object permissions are influenced by the application’s requested mode and ACL inheritance.
- Some tools may preserve, replace, or omit ACLs depending on their options.
- Confirm the actual result with `getfacl`.

---

## 13. Backing Up and Restoring ACLs

Back up ACL metadata:

```bash
getfacl -R /exact/path > acl-backup.txt
```

Restore:

```bash
setfacl --restore=acl-backup.txt
```

For production use:

- Store the backup in a protected location.
- Inspect the generated paths.
- Test restoration on a safe scope.
- Coordinate with file backup and SELinux-context restoration.

An ACL backup does not replace a content backup.

---

## 14. Special Permission Bits

Three special permission bits exist:

| Special Bit | Numeric Value | Common Symbol |
|---|---:|---|
| SUID | `4` | `s` in the owner execute position |
| SGID | `2` | `s` in the group execute position |
| Sticky bit | `1` | `t` in the other execute position |

They can be represented as a leading octal digit.

Examples:

```text
4755 → SUID + 755
2750 → SGID + 750
1777 → sticky bit + 777
3770 → SGID + sticky bit + 770
```

---

## 15. SUID

SUID stands for **Set User ID**.

On an executable binary, SUID causes the process to run with the effective UID of the file owner rather than only the invoking user’s UID.

Example:

```bash
ls -l /usr/bin/passwd
```

Typical mode:

```text
-rwsr-xr-x
```

The `s` appears in the owner execute position.

Set SUID:

```bash
chmod u+s executable
```

or:

```bash
chmod 4755 executable
```

Remove:

```bash
chmod u-s executable
```

### Security Considerations

SUID-root programs require careful security review because a vulnerability may provide privilege escalation.

Linux normally does not honor SUID on interpreted shell scripts. Do not use SUID scripts as a privilege-delegation design.

Filesystem mount options such as `nosuid` can prevent SUID and SGID execution effects.

---

## 16. SGID

SGID stands for **Set Group ID**.

### 16.1 SGID on an Executable

The process runs with the executable file’s effective group ID.

Set:

```bash
chmod g+s executable
```

or:

```bash
chmod 2755 executable
```

### 16.2 SGID on a Directory

New files and subdirectories normally inherit the directory’s group instead of the creator’s primary group.

This is useful for shared-team directories.

Example:

```bash
sudo chgrp projectteam /srv/project
sudo chmod 2770 /srv/project
```

Result:

```text
drwxrws---
```

The `s` appears in the group execute position.

### Important Limitation

SGID inheritance controls the group owner. It does not automatically guarantee that new files are group-writable. Use an appropriate umask or default ACL for collaborative write access.

---

## 17. Sticky Bit

The sticky bit is most useful on shared writable directories.

Without the sticky bit, users with write and execute permission on a directory may delete or rename other users’ entries.

With the sticky bit, deletion and renaming are generally restricted to:

- The file owner
- The directory owner
- Root or a sufficiently privileged process

Example:

```bash
ls -ld /tmp
```

Typical mode:

```text
drwxrwxrwt
```

Set:

```bash
chmod +t shared-directory
```

or:

```bash
chmod 1777 shared-directory
```

Remove:

```bash
chmod -t shared-directory
```

---

## 18. Lowercase vs. Uppercase Special-Bit Symbols

| Display | Meaning |
|---|---|
| `s` | SUID or SGID set and execute bit also set |
| `S` | SUID or SGID set but execute bit not set |
| `t` | Sticky bit set and other execute bit also set |
| `T` | Sticky bit set but other execute bit not set |

Examples:

```text
-rwsr-xr-x  → SUID and owner execute are set
-rwSr--r--  → SUID set, owner execute missing
drwxrwxrwt  → sticky bit and other execute are set
drwxrwxrwT  → sticky bit set, other execute missing
```

An uppercase special-bit character often indicates an unusual or ineffective permission combination that deserves review.

---

## 19. Building a Secure Shared Directory

### Requirement

Members of `projectteam` must:

- Create and edit shared files
- Inherit the correct group
- Receive consistent group access
- Prevent access by unrelated users

### Recommended Design

```bash
sudo groupadd projectteam
sudo mkdir -p /srv/project
sudo chown root:projectteam /srv/project
sudo chmod 2770 /srv/project
sudo setfacl -m d:u::rwx,d:g::rwx,d:m::rwx,d:o::--- /srv/project
```

Verify:

```bash
ls -ld /srv/project
getfacl /srv/project
```

### Why Both SGID and Default ACL?

- SGID helps new objects inherit group ownership.
- Default ACLs provide consistent inherited access permissions.
- The ACL mask defines the maximum effective group-class access.

The exact policy should match application behavior and organizational requirements.

---

## 20. Auditing Dangerous Permissions

### 20.1 Find SUID and SGID Files

On the root filesystem:

```bash
sudo find / -xdev -type f -perm /6000 -ls 2>/dev/null
```

This finds files with SUID, SGID, or both.

SUID only:

```bash
sudo find / -xdev -type f -perm -4000 -ls 2>/dev/null
```

SGID only:

```bash
sudo find / -xdev -type f -perm -2000 -ls 2>/dev/null
```

### 20.2 Find World-Writable Files

```bash
sudo find / -xdev -type f -perm -0002 -ls 2>/dev/null
```

### 20.3 Find World-Writable Directories Without Sticky Bit

```bash
sudo find / -xdev -type d -perm -0002 ! -perm -1000 -ls 2>/dev/null
```

### 20.4 Review, Do Not Blindly Change

Some special permissions are legitimate. Before changing:

- Identify the owning package.
- Compare with a known-good baseline.
- Review vulnerability-management guidance.
- Confirm application requirements.
- Use change management.

Check package ownership:

```bash
rpm -qf /path/to/file
```

Verify package-managed file attributes:

```bash
rpm -V PACKAGE_NAME
```

---

## 21. Permissions, Mount Options, and SELinux

Traditional permissions are not the only decision point.

### 21.1 Mount Options

Inspect:

```bash
findmnt -no TARGET,SOURCE,FSTYPE,OPTIONS /path
```

Important options:

| Option | Effect |
|---|---|
| `ro` | Read-only filesystem |
| `noexec` | Prevent direct execution from the mount |
| `nosuid` | Ignore SUID and SGID privilege effects |
| `nodev` | Do not interpret device files on the mount |

### 21.2 SELinux

Check mode:

```bash
getenforce
```

Inspect labels:

```bash
ls -lZ /path
```

Search recent denials:

```bash
sudo ausearch -m AVC,USER_AVC -ts recent
```

Do not disable SELinux as the first response to a permission problem. Identify and correct the label or policy issue.

### 21.3 NFS

NFS access can also depend on:

- Numeric UID/GID consistency
- Export options
- `root_squash`
- NFSv4 ACLs
- Server-side permissions
- Client and server identity mapping

An apparent permission problem on the client may originate from the NFS server or identity service.

---

## 22. Permission Troubleshooting Method

When a user reports `Permission denied`, collect:

```bash
id USERNAME
namei -l /complete/path/to/object
ls -ld /complete/path/to/object
getfacl /complete/path/to/object
findmnt -T /complete/path/to/object
ls -lZ /complete/path/to/object
```

### Why `namei -l` Is Valuable

Every parent directory in the path normally requires execute/traverse permission.

```bash
namei -l /srv/project/reports/report.txt
```

A correct file mode cannot compensate for a missing execute permission on a parent directory.

### Troubleshooting Order

1. Confirm the exact user, process, and access operation.
2. Resolve identity and groups with `id` and `getent`.
3. Inspect every parent-directory component.
4. Inspect owner, group, and mode.
5. Inspect ACL entries and mask.
6. Inspect mount options and filesystem state.
7. Inspect SELinux context and denials.
8. For NFS, inspect server-side and identity-mapping controls.
9. Review recent changes.
10. Apply the smallest approved correction and validate.

---

## 23. Hands-On Lab

### Lab Safety

Perform this lab only inside:

```text
~/linux-engineer-prep/module-04
```

ACL exercises require the `getfacl` and `setfacl` commands.

### Step 1 — Create the Lab Directory

```bash
mkdir -p ~/linux-engineer-prep/module-04/{files,shared,acl-lab,special}
cd ~/linux-engineer-prep/module-04
```

Verify:

```bash
pwd
find . -maxdepth 2 -type d -print
```

### Step 2 — Practice File Permissions

```bash
printf '%s\n' 'Linux Systems Engineer II' > files/report.txt
chmod 640 files/report.txt
stat -c '%A %a %U %G %n' files/report.txt
```

Expected mode:

```text
-rw-r----- 640
```

Change symbolically:

```bash
chmod g+w files/report.txt
chmod o-rwx files/report.txt
stat -c '%A %a %n' files/report.txt
```

### Step 3 — Practice Directory Permissions

```bash
mkdir files/private
chmod 700 files/private
stat -c '%A %a %n' files/private
```

Explain:

- Owner can list, create, delete, and traverse.
- Group and others have no access.

### Step 4 — Test `umask`

Run in a subshell so your original shell’s umask is preserved:

```bash
(
    umask 027
    touch files/umask-file.txt
    mkdir files/umask-directory
    stat -c '%A %a %n' files/umask-file.txt files/umask-directory
)
```

Expected typical results:

```text
640 for the file
750 for the directory
```

### Step 5 — Create ACL Entries

Choose a harmless existing lab identity to demonstrate a named-user ACL. The `nobody` account commonly exists on RHEL:

```bash
acl_user="nobody"
getent passwd "$acl_user"
```

Create a file:

```bash
printf '%s\n' 'ACL practice' > acl-lab/acl-report.txt
chmod 600 acl-lab/acl-report.txt
```

If the identity does not exist, stop this step or use a dedicated test user that you created for the lab. Do not select an unknown production account.

Add the named-user ACL:

```bash
setfacl -m "u:${acl_user}:rw-" acl-lab/acl-report.txt
getfacl acl-lab/acl-report.txt
```

The ACL can be inspected even if parent home-directory permissions prevent that identity from traversing the complete path. Effective access always requires permission through every directory component.

### Step 6 — Observe the ACL Mask

Set a named entry and then restrict the mask:

```bash
setfacl -m "u:${acl_user}:rwx,m::r--" acl-lab/acl-report.txt
getfacl acl-lab/acl-report.txt
```

Observe the `#effective:` annotation.

Restore:

```bash
setfacl -m m::rw- acl-lab/acl-report.txt
getfacl acl-lab/acl-report.txt
```

### Step 7 — Practice Default ACLs

```bash
setfacl -m d:u::rwx,d:g::r-x,d:o::--- acl-lab
touch acl-lab/inherited-file.txt
mkdir acl-lab/inherited-directory
getfacl acl-lab
getfacl acl-lab/inherited-file.txt
getfacl acl-lab/inherited-directory
```

Compare the access ACLs inherited by the new objects.

### Step 8 — Practice SGID on a Directory

Use your current group:

```bash
lab_group="$(id -gn)"
chgrp "$lab_group" shared
chmod 2770 shared
touch shared/team-file.txt
ls -ld shared
ls -l shared/team-file.txt
```

Confirm that the new file inherits the directory’s group.

### Step 9 — Practice the Sticky Bit

```bash
chmod 1777 special
ls -ld special
```

Expected:

```text
drwxrwxrwt
```

The complete cross-user deletion test requires two separate lab users. The sticky bit prevents one ordinary user from deleting another user’s entry in this shared writable directory.

### Step 10 — Recognize Special Bits

Create a harmless lab file:

```bash
printf '#!/usr/bin/env bash\necho "lab only"\n' > special/demo.sh
chmod 755 special/demo.sh
chmod u+s special/demo.sh
ls -l special/demo.sh
```

Observe the SUID display, but understand that Linux normally ignores SUID on interpreted scripts.

Remove it:

```bash
chmod u-s special/demo.sh
```

### Step 11 — Audit the Lab

```bash
find . -type f -perm /6000 -ls
find . -type d -perm -1000 -ls
find . -type d -perm -2000 -ls
find . -type f -perm -0002 -ls
```

### Step 12 — Back Up ACL Metadata

```bash
getfacl -R acl-lab > acl-lab-backup.txt
less acl-lab-backup.txt
```

### Lab Deliverables

```text
module-04/
├── acl-lab/
│   ├── acl-report.txt
│   ├── inherited-directory/
│   └── inherited-file.txt
├── acl-lab-backup.txt
├── files/
│   ├── private/
│   ├── report.txt
│   ├── umask-directory/
│   └── umask-file.txt
├── shared/
│   └── team-file.txt
└── special/
    └── demo.sh
```

---

## 24. Production Troubleshooting Scenarios

### Scenario 1 — Correct File Mode but `Permission denied`

Check:

```bash
id USERNAME
namei -l /complete/path/to/file
getfacl /complete/path/to/file
findmnt -T /complete/path/to/file
ls -lZ /complete/path/to/file
```

Possible causes:

- Missing execute permission on a parent directory
- ACL mask restriction
- Incorrect group membership in the current session
- SELinux denial
- Read-only or `noexec` mount
- NFS identity mismatch
- Application running as a different service account

### Scenario 2 — Shared Files Have the Wrong Group

Check:

```bash
ls -ld /shared/path
stat -c '%A %a %U %G %n' /shared/path
getfacl /shared/path
```

Possible correction:

- Set the correct owning group.
- Enable SGID on the directory.
- Use a default ACL.
- Review the creating service’s umask.

Do not recursively change all ownership until you understand which objects should be shared.

### Scenario 3 — ACL Says `rwx`, but User Cannot Write

Check:

```bash
getfacl /path/to/object
```

Look for:

```text
mask::r-x
```

The ACL mask may reduce the named user’s effective permission.

### Scenario 4 — Script Has Execute Permission but Will Not Run

Check:

```bash
ls -l script.sh
file script.sh
head -1 script.sh
findmnt -T script.sh
ls -lZ script.sh
```

Possible causes:

- Invalid or missing shebang
- Interpreter missing
- `noexec` mount option
- SELinux denial
- Windows CRLF line endings
- Parent directory not traversable
- Incorrect architecture for a binary

### Scenario 5 — World-Writable Directory Is a Security Finding

Determine:

- Is public write access actually required?
- Is the sticky bit set?
- Who owns the directory?
- What service uses it?
- Can a group or ACL replace world write?

Use:

```bash
stat -c '%A %a %U %G %n' /path
getfacl /path
```

### Scenario 6 — Unexpected SUID File Found

Check:

```bash
ls -l /path/to/file
stat /path/to/file
rpm -qf /path/to/file
findmnt -T /path/to/file
```

Then:

- Compare with package metadata.
- Review change and security records.
- Hash and investigate the file if unauthorized modification is suspected.
- Do not execute an unknown SUID file.
- Follow incident-response procedures.

---

## 25. Common Interview Questions and Answers

### 1. What do `r`, `w`, and `x` mean on a regular file?

They mean read content, modify content, and execute the file as a program when other execution requirements are satisfied.

### 2. What do `r`, `w`, and `x` mean on a directory?

They mean list names, modify directory entries, and traverse/search the directory.

### 3. Can a user delete a read-only file?

Possibly. Deletion is controlled mainly by write and execute permission on the parent directory, plus sticky-bit and other security controls.

### 4. What does mode `750` mean?

The owner has `rwx`, the group has `r-x`, and others have no permission.

### 5. Why is `chmod 777` usually a bad fix?

It grants everyone full traditional access, hides the real ownership or policy problem, and increases security and integrity risks.

### 6. What is the difference between `chown` and `chmod`?

`chown` changes ownership. `chmod` changes permission and special-mode bits.

### 7. What is `umask`?

It is a mask that clears permission bits from the mode requested when new files and directories are created.

### 8. What are typical results of `umask 027`?

Files commonly receive `640`, and directories commonly receive `750`, assuming the application requests the standard maximum modes.

### 9. Why do new regular files normally not receive execute permission?

Applications commonly request a maximum file mode of `666`. Umask removes permissions; it does not add execute permission.

### 10. What problem do ACLs solve?

They allow access for additional named users and groups beyond the single traditional owner and owning group.

### 11. What does the ACL mask do?

It limits effective permissions for named users, the owning group, and named groups.

### 12. What is a default ACL?

It is an ACL on a directory used to generate inherited access ACLs for newly created child objects.

### 13. What does SUID do?

On an executable binary, it causes the process to use the file owner’s effective UID.

### 14. Does SUID work reliably on shell scripts?

No. Linux normally ignores SUID on interpreted scripts for security reasons.

### 15. What does SGID do on a directory?

It causes new child objects to inherit the directory’s group ownership.

### 16. Does SGID automatically make new files group-writable?

No. Group-write access also depends on the requested creation mode, umask, and ACLs.

### 17. What does the sticky bit do on a directory?

In a shared writable directory, it restricts deletion and renaming so users generally cannot remove entries owned by other users.

### 18. What is the difference between lowercase `s` and uppercase `S`?

Lowercase `s` means the special bit and execute bit are both set. Uppercase `S` means the special bit is set but the corresponding execute bit is not.

### 19. How do you find SUID and SGID files?

```bash
find / -xdev -type f -perm /6000 -ls
```

### 20. How would you troubleshoot `Permission denied`?

I would confirm the executing identity, inspect every directory in the path, owner and mode, ACL entries and mask, mount options, SELinux labels and denials, NFS controls when applicable, and recent changes before applying the smallest correction.

---

## 26. Quick Knowledge Check

### Questions

1. What does `640` mean on a file?
2. What permission is required to traverse a directory?
3. Which permissions normally allow creating and deleting directory entries?
4. Is file write permission required to delete a file?
5. What modes commonly result from `umask 027`?
6. Which command displays the complete ACL?
7. Which ACL entry can reduce a named user’s effective access?
8. What does a default ACL affect?
9. What is the leading octal value for SUID?
10. What is the leading octal value for SGID?
11. What is the leading octal value for the sticky bit?
12. What does SGID do on a directory?
13. What does the sticky bit protect in a shared directory?
14. Which command helps inspect every component of a path?
15. Can SELinux deny access even when mode bits allow it?

### Answer Key

1. Owner read/write, group read, and no access for others.
2. Execute (`x`)
3. Write and execute on the parent directory
4. No. Parent-directory permissions normally control deletion.
5. Files `640` and directories `750`, under typical creation requests.
6. `getfacl`
7. The ACL mask
8. Newly created child files and directories
9. `4`
10. `2`
11. `1`
12. New children inherit the directory’s group ownership.
13. It generally stops users from deleting or renaming entries owned by other users.
14. `namei -l`
15. Yes.

---

## 27. Interview Practice Exercises

Answer each question aloud in 60–90 seconds.

### Exercise 1

> A file has mode `777`, but the application still receives `Permission denied`. Explain your investigation.

Your response should cover:

- Actual service identity
- Parent-directory traversal
- ACLs and mask
- Read-only or `noexec` mount
- SELinux
- NFS or storage controls
- Application logs
- Avoiding further permission broadening

### Exercise 2

> Design a directory where five developers can collaborate, new files retain the team group, and outsiders have no access.

Your response should cover:

- Dedicated group
- Correct ownership
- SGID directory
- Mode such as `2770`
- Default ACL for inherited group access
- Appropriate umask
- Validation using separate accounts

### Exercise 3

> Security reports an unknown SUID-root binary. What do you do?

Your response should cover:

- Do not execute it
- Record path, owner, mode, timestamps, and hash
- Determine package ownership
- Compare with a baseline
- Check recent changes and audit records
- Contain and escalate through incident response

### Exercise 4

> A named ACL grants a user `rwx`, but the user has only read access.

Your response should immediately consider the ACL mask and verify with `getfacl`.

---

## 28. Module Completion Checklist

Mark each item when you can complete it without assistance:

- [ ] I can read a complete `ls -l` permission string.
- [ ] I can explain permissions on files and directories.
- [ ] I can calculate octal modes.
- [ ] I can use symbolic `chmod` notation.
- [ ] I can change owner and group safely.
- [ ] I understand why recursive ownership changes are risky.
- [ ] I can calculate typical results from `umask`.
- [ ] I can explain why services may use a different umask.
- [ ] I can create, inspect, and remove ACL entries.
- [ ] I understand the ACL mask.
- [ ] I can configure a default ACL.
- [ ] I can explain SUID, SGID, and sticky bit.
- [ ] I can build a secure shared-team directory.
- [ ] I can audit SUID, SGID, and world-writable paths.
- [ ] I can troubleshoot permissions across DAC, ACL, mount, NFS, and SELinux layers.
- [ ] I completed the hands-on lab.
- [ ] I answered the interview questions aloud.

---

## 29. Command Revision Sheet

```bash
ls -l
ls -ld DIRECTORY
stat FILE
stat -c '%A %a %U %G %n' FILE
chmod u+x FILE
chmod g+w FILE
chmod o= FILE
chmod 640 FILE
chmod 750 DIRECTORY
chown USER FILE
chown USER:GROUP FILE
chgrp GROUP FILE
umask
umask -S
umask 027
getfacl FILE
setfacl -m u:USER:r-- FILE
setfacl -m g:GROUP:rwx DIRECTORY
setfacl -x u:USER FILE
setfacl -b FILE
setfacl -m d:g:GROUP:rwx DIRECTORY
setfacl -k DIRECTORY
getfacl -R DIRECTORY > acl-backup.txt
setfacl --restore=acl-backup.txt
chmod u+s EXECUTABLE
chmod g+s DIRECTORY
chmod +t DIRECTORY
chmod 4755 EXECUTABLE
chmod 2770 DIRECTORY
chmod 1777 DIRECTORY
namei -l /complete/path
findmnt -T /complete/path
ls -lZ /complete/path
getenforce
sudo ausearch -m AVC,USER_AVC -ts recent
sudo find / -xdev -type f -perm /6000 -ls
sudo find / -xdev -type f -perm -0002 -ls
sudo find / -xdev -type d -perm -0002 ! -perm -1000 -ls
```

---

## Next Module

**Module 05 — Processes, Jobs, Signals, and Resource Usage**

Topics will include:

- Process IDs and parent-child relationships
- Process states
- `ps`, `top`, `pgrep`, and `pidof`
- Foreground and background jobs
- Signals and safe process termination
- `nice` and `renice`
- CPU and memory investigation
- Zombie and orphan processes
- `/proc` process inspection
- Production troubleshooting scenarios
- Interview questions and a practical lab
