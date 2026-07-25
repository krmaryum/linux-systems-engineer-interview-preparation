# Linux Systems Engineer II Interview Preparation

## Module 07 — RPM, DNF, Repositories, and Software Management

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 75–90 minutes

> Perform installation, removal, upgrade, repository, module-stream, and RPM-database exercises only on an approved lab system. Package changes can restart services, replace configuration, change dependencies, or require a reboot.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain RPM and DNF responsibilities.
- Read an RPM package’s name, version, release, and architecture.
- Query installed and uninstalled package files.
- Identify which package owns a file or provides a capability.
- Inspect package dependencies and scriptlets.
- Verify GPG signatures and installed-file integrity.
- Install local RPM files with dependency resolution.
- Configure, enable, disable, and troubleshoot repositories.
- Use DNF transaction history safely.
- Explain DNF groups and module streams.
- Identify security advisories and security updates.
- Plan kernel updates without removing the running kernel.
- Explain `.rpmnew` and `.rpmsave` configuration handling.
- Build an enterprise patch plan with validation and rollback.
- Troubleshoot repository, dependency, lock, and database problems.

---

## 2. RPM and DNF

### RPM

RPM can mean:

- The RPM package format
- The RPM Package Manager
- The local RPM database and command tools

RPM manages:

- Package metadata
- Installed files
- Ownership
- Dependencies recorded by packages
- Scripts executed during package transactions
- Package signatures
- File verification data

### DNF

DNF is the higher-level package manager used on modern RHEL-family systems.

DNF:

- Uses configured repositories.
- Resolves dependencies.
- Downloads required packages.
- Invokes RPM transactions.
- Records transaction history.
- Handles advisory and repository metadata.

### Essential Difference

> RPM understands individual packages and the local package database. DNF adds repository access, dependency solving, transaction planning, and history.

---

## 3. RPM Package Naming

A common RPM filename:

```text
httpd-2.4.62-1.el9.x86_64.rpm
```

Breakdown:

| Component | Example | Meaning |
|---|---|---|
| Name | `httpd` | Package name |
| Version | `2.4.62` | Upstream software version |
| Release | `1.el9` | Distribution package release |
| Architecture | `x86_64` | Target architecture |
| Extension | `.rpm` | RPM package |

The common identity abbreviation is:

```text
NEVRA
```

It represents:

- Name
- Epoch
- Version
- Release
- Architecture

Display installed NEVRA:

```bash
rpm -q --qf '%{NAME}-%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' PACKAGE
```

The epoch is used only when package-version ordering requires it and is often zero.

---

## 4. The RPM Database

The RPM database records installed package metadata.

Do not manually edit it.

Query all installed packages:

```bash
rpm -qa
```

Count:

```bash
rpm -qa | wc -l
```

Sort:

```bash
rpm -qa | sort
```

The database format and internal location can vary by RHEL release. Use RPM commands rather than manipulating internal database files.

---

## 5. Essential RPM Queries

### Is a Package Installed?

```bash
rpm -q bash
```

### Package Information

```bash
rpm -qi bash
```

### List Package Files

```bash
rpm -ql bash
```

### Configuration Files

```bash
rpm -qc openssh-server
```

### Documentation Files

```bash
rpm -qd bash
```

### Package Changelog

```bash
rpm -q --changelog PACKAGE
```

### Package Dependencies

Requirements:

```bash
rpm -qR PACKAGE
```

Capabilities provided:

```bash
rpm -q --provides PACKAGE
```

### Package Scriptlets

```bash
rpm -q --scripts PACKAGE
```

Scriptlets may run:

- Before installation
- After installation
- Before removal
- After removal
- During triggers

This is important when evaluating change impact.

---

## 6. Which Package Owns a File?

```bash
rpm -qf /usr/bin/ls
```

Example result:

```text
coreutils-...
```

If the file is not owned by an installed RPM, investigate whether it is:

- Locally compiled software
- A custom script
- An extracted binary
- A third-party installation
- A suspicious unauthorized file

### Find a Package That Provides a Missing File

Using DNF:

```bash
dnf provides '*/semanage'
```

or:

```bash
dnf provides /usr/bin/example
```

This searches enabled repository metadata.

---

## 7. Querying an RPM File Before Installation

Use `-p` to query a package file:

```bash
rpm -qip package.rpm
rpm -qlp package.rpm
rpm -qRp package.rpm
rpm -qp --scripts package.rpm
```

| Command | Meaning |
|---|---|
| `rpm -qip` | Package-file information |
| `rpm -qlp` | Files in package |
| `rpm -qRp` | Requirements |
| `rpm -qp --scripts` | Scriptlets |

Inspecting metadata does not prove that a package is trusted. Verify its signature and source.

---

## 8. Package Signature Verification

Check a downloaded RPM:

```bash
rpm -K package.rpm
```

Alternative:

```bash
rpm --checksig package.rpm
```

Trusted repositories commonly use GPG signatures.

Repository configuration should normally contain:

```ini
gpgcheck=1
```

The repository or system also needs the expected trusted signing key.

List imported RPM keys:

```bash
rpm -qa 'gpg-pubkey*'
```

### Security Principles

- Download only from approved sources.
- Verify TLS and repository configuration.
- Keep GPG checking enabled.
- Validate the expected signing identity.
- Do not import an unknown key merely to silence an error.
- Record third-party repository ownership and lifecycle.

---

## 9. Verifying Installed Package Files

Verify one package:

```bash
rpm -V PACKAGE
```

No output commonly means no tracked difference was found.

Verify all packages:

```bash
sudo rpm -Va
```

This can produce substantial output and may include expected local configuration changes.

Common verification indicators:

| Indicator | Meaning |
|---|---|
| `S` | Size differs |
| `M` | Mode or permissions differ |
| `5` | Digest differs |
| `D` | Device major/minor differs |
| `L` | Symbolic-link target differs |
| `U` | User ownership differs |
| `G` | Group ownership differs |
| `T` | Modification time differs |
| `P` | Capabilities differ |

Example:

```text
S.5....T.  c /etc/example.conf
```

The `c` indicates a configuration file.

### Important Limitation

`rpm -V` compares with package metadata. It does not:

- Prove that the package itself was trustworthy.
- Detect every compromise.
- Replace file-integrity monitoring.
- Automatically determine whether a change was authorized.

---

## 10. Direct RPM Installation

Install:

```bash
sudo rpm -ivh package.rpm
```

Upgrade or install:

```bash
sudo rpm -Uvh package.rpm
```

Freshen only if already installed:

```bash
sudo rpm -Fvh package.rpm
```

Remove:

```bash
sudo rpm -e PACKAGE
```

### Why Direct RPM Is Usually Not Preferred

RPM reports missing dependencies but does not normally fetch them automatically.

Prefer:

```bash
sudo dnf install ./package.rpm
```

DNF can resolve required packages through enabled repositories.

### Dangerous Bypass Options

Avoid using options such as:

```text
--nodeps
--force
```

They can produce an inconsistent or unsupported system. Use only within an approved vendor recovery procedure when the consequences are fully understood.

---

## 11. DNF Basics

Check version:

```bash
dnf --version
```

List enabled repositories:

```bash
dnf repolist
```

Include disabled repositories:

```bash
dnf repolist --all
```

List installed packages:

```bash
dnf list installed
```

Search:

```bash
dnf search keyword
```

Package information:

```bash
dnf info PACKAGE
```

List available updates:

```bash
dnf check-update
```

`dnf check-update` can use a special non-zero exit code when updates are available. Do not assume every non-zero result means command failure.

---

## 12. Installing and Removing with DNF

Install:

```bash
sudo dnf install PACKAGE
```

Install a local package:

```bash
sudo dnf install ./package.rpm
```

Remove:

```bash
sudo dnf remove PACKAGE
```

Reinstall:

```bash
sudo dnf reinstall PACKAGE
```

Upgrade one package:

```bash
sudo dnf upgrade PACKAGE
```

Upgrade the system:

```bash
sudo dnf upgrade
```

Downgrade where an older repository version is available:

```bash
sudo dnf downgrade PACKAGE
```

### Preview a Transaction

```bash
sudo dnf install PACKAGE --assumeno
sudo dnf upgrade --assumeno
```

Review:

- Packages installed
- Packages upgraded
- Packages removed
- Dependencies
- Download size
- Repository source

Never approve a production transaction without reading the complete plan.

---

## 13. DNF Repository Configuration

Repository files are commonly stored in:

```text
/etc/yum.repos.d/*.repo
```

Example:

```ini
[example-repo]
name=Approved Example Repository
baseurl=https://repo.example.com/rhel/9/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-example
```

Important fields:

| Field | Meaning |
|---|---|
| `[repo-id]` | Unique repository identifier |
| `name` | Human-readable name |
| `baseurl` | Repository location |
| `mirrorlist` | URL providing mirrors |
| `metalink` | Metadata-based mirror selection |
| `enabled` | Default enabled state |
| `gpgcheck` | Package signature checking |
| `repo_gpgcheck` | Repository-metadata signature checking when supported/configured |
| `gpgkey` | Trusted key location |

### Protect Repository Credentials

Do not commit:

- Repository passwords
- Client certificates
- Subscription credentials
- Tokens
- Internal repository URLs when prohibited

Use the organization’s secret-management and repository tooling.

---

## 14. Temporarily Enable or Disable a Repository

Disable for one command:

```bash
dnf --disablerepo=REPO_ID list available
```

Enable for one command:

```bash
dnf --enablerepo=REPO_ID list available
```

Use only one repository for troubleshooting:

```bash
dnf --disablerepo='*' --enablerepo=REPO_ID list available
```

Preview carefully. Shell quoting prevents wildcard expansion.

Persistent repository management may use:

```bash
dnf config-manager --set-enabled REPO_ID
dnf config-manager --set-disabled REPO_ID
```

The `config-manager` command may require an additional plugin package, depending on the RHEL release.

---

## 15. RHEL Subscription Repositories

On registered Red Hat Enterprise Linux systems, repository access may be managed through:

```bash
subscription-manager status
subscription-manager identity
subscription-manager repos --list-enabled
```

Availability and subscription behavior depend on:

- RHEL version
- Subscription model
- Simple Content Access configuration
- Satellite or other lifecycle-management systems
- Organization policy

Do not unregister or change subscriptions without authorization.

---

## 16. Repository Metadata and Cache

Refresh:

```bash
sudo dnf makecache --refresh
```

Display cache information:

```bash
dnf repolist -v
```

Clean cached metadata and packages:

```bash
sudo dnf clean all
```

Cleaning the cache is not a universal fix. It removes local data and forces new downloads.

Use when evidence indicates:

- Stale metadata
- Corrupted cache
- Repository metadata recently changed

---

## 17. DNF Groups

List groups:

```bash
dnf group list
```

Information:

```bash
dnf group info "Development Tools"
```

Install:

```bash
sudo dnf group install "Development Tools"
```

Group names and availability depend on enabled repositories and the RHEL release.

Review the package set before installing a large group on a production server.

---

## 18. DNF Module Streams

Some RHEL releases and repositories use module streams to provide different application versions.

List:

```bash
dnf module list
```

Information:

```bash
dnf module info MODULE
```

Enable a stream:

```bash
sudo dnf module enable MODULE:STREAM
```

Reset:

```bash
sudo dnf module reset MODULE
```

Install:

```bash
sudo dnf module install MODULE:STREAM
```

### High-Impact Warning

Changing streams can alter:

- Application versions
- Dependency sets
- Compatibility
- Database formats
- Supported upgrade paths

Follow the vendor-supported migration procedure. Module commands and available streams vary by RHEL major version and repository content.

---

## 19. DNF History

List transactions:

```bash
dnf history
```

Details:

```bash
dnf history info TRANSACTION_ID
```

Undo:

```bash
sudo dnf history undo TRANSACTION_ID
```

Rollback to an earlier transaction point:

```bash
sudo dnf history rollback TRANSACTION_ID
```

### Rollback Limitations

DNF history undo or rollback is not a complete system rollback.

It may fail or be insufficient because:

- Older packages are no longer available.
- Application data was migrated.
- Database schemas changed.
- Configuration files changed.
- Services wrote new state.
- Kernel or boot behavior changed.
- Multiple dependent systems were modified.

For critical systems, use:

- Tested backups
- VM or storage snapshots when appropriate
- Application rollback
- Configuration management
- Database rollback procedures
- Documented change reversal

---

## 20. Security Advisories

List security updates:

```bash
dnf updateinfo list security
```

Details:

```bash
dnf updateinfo info --security
```

Apply security updates:

```bash
sudo dnf upgrade --security
```

Specific advisory:

```bash
sudo dnf upgrade --advisory=ADVISORY_ID
```

Advisory capabilities depend on repository metadata.

### Vulnerability Management Is More Than Installation

A complete process includes:

- Asset inventory
- Exposure analysis
- Severity and exploitability
- Business criticality
- Compatibility testing
- Approved maintenance window
- Backup and rollback
- Installation
- Reboot decision
- Functional validation
- Monitoring
- Evidence and reporting

---

## 21. Package Update vs. Security Remediation

Installing a package update does not always complete remediation.

Additional actions may include:

- Restarting the affected service
- Rebooting into a new kernel
- Restarting long-running processes using old libraries
- Updating containers or immutable images
- Confirming the vulnerable package is no longer loaded
- Running a vulnerability rescan

Check for restart recommendations when the appropriate DNF plugin is installed:

```bash
dnf needs-restarting
dnf needs-restarting -r
```

Exact plugin availability and output vary by RHEL version.

---

## 22. Kernel Package Management

Kernel packages are commonly install-only packages. New kernels are installed alongside older kernels rather than replacing the running one immediately.

Running kernel:

```bash
uname -r
```

Installed kernels:

```bash
rpm -q kernel
```

Default kernel:

```bash
sudo grubby --default-kernel
```

Boot entries:

```bash
sudo grubby --info=ALL
```

### Critical Safety Rules

- Never remove the running kernel.
- Keep at least one known-good fallback kernel.
- Confirm `/boot` has capacity before patching.
- Confirm initramfs creation succeeded.
- Confirm the expected boot entry.
- Reboot only in an approved window.
- Validate the running kernel after reboot.

After reboot:

```bash
uname -r
systemctl --failed
journalctl -b -p err
```

---

## 23. `/boot` Capacity Before Kernel Updates

Check:

```bash
df -hT /boot
ls -lh /boot
rpm -q kernel
```

A full `/boot` can cause:

- Kernel installation failure
- Initramfs creation failure
- Incomplete boot artifacts
- Boot failure

Do not manually delete arbitrary files from `/boot`.

Remove old kernels only through the supported package manager after confirming:

- They are not running.
- They are not the required fallback.
- The change is authorized.

---

## 24. Configuration Files During Upgrades

RPM may preserve configuration changes using files such as:

```text
.rpmnew
.rpmsave
```

### `.rpmnew`

The new package-provided configuration is stored separately while the existing modified configuration remains active.

### `.rpmsave`

The previous configuration is saved while another version becomes active.

Search:

```bash
sudo find /etc -type f \( -name '*.rpmnew' -o -name '*.rpmsave' \) -print
```

Do not blindly replace current configuration.

Compare:

```bash
diff -u existing.conf existing.conf.rpmnew
```

Merge required changes, validate application syntax, and test through change management.

---

## 25. Excluding or Locking Package Versions

DNF can exclude packages through configuration or command options.

Example preview:

```bash
dnf upgrade --exclude=PACKAGE --assumeno
```

Version locking may be available through a plugin:

```bash
dnf versionlock list
```

### Risks

Holding packages can:

- Leave vulnerabilities unpatched
- Block dependencies
- Produce unsupported combinations
- Complicate future upgrades

Every exclusion or lock should have:

- Documented reason
- Owner
- Expiration or review date
- Compensating controls
- Removal plan

---

## 26. Package and Repository Logs

Common logs include:

```text
/var/log/dnf.log
/var/log/dnf.rpm.log
/var/log/yum.log
```

Availability varies by release and configuration.

Review:

```bash
sudo less /var/log/dnf.log
journalctl --since "1 hour ago" | grep -Ei 'dnf|rpm'
```

Also use:

```bash
dnf history
dnf history info TRANSACTION_ID
```

---

## 27. Repository Troubleshooting Method

### Step 1 — Identify the Exact Error

Examples:

- Cannot resolve host
- Connection timeout
- TLS certificate failure
- GPG verification failure
- Metadata download failure
- Repository not found
- Authentication failure

### Step 2 — Inspect Enabled Repositories

```bash
dnf repolist
dnf repolist -v
```

### Step 3 — Inspect Repository Files

```bash
grep -RniE '^\[|^name=|^baseurl=|^mirrorlist=|^metalink=|^enabled=|^gpgcheck=' \
  /etc/yum.repos.d/
```

Be careful not to expose credentials embedded in URLs.

### Step 4 — Check Network Foundations

```bash
ip route
getent hosts REPOSITORY_HOST
timedatectl
```

Correct time is important for TLS certificate validation.

### Step 5 — Refresh Metadata

```bash
sudo dnf makecache --refresh
```

### Step 6 — Isolate One Repository

```bash
dnf --disablerepo='*' --enablerepo=REPO_ID makecache
```

### Step 7 — Check Proxy and Certificates

Review:

- Organizational proxy
- CA trust
- Repository credentials
- Subscription status
- Satellite or mirror health

Do not disable TLS or GPG verification merely to make the command succeed.

---

## 28. Dependency Problems

DNF may report:

- Conflicting requests
- Nothing provides a required capability
- Package excluded
- Modular filtering
- Multilib version conflict
- Protected package

Investigate:

```bash
dnf info PACKAGE
dnf repoquery PACKAGE
dnf repoquery --requires PACKAGE
dnf module list
dnf repolist
```

Potential causes:

- Required repository disabled
- Unsupported third-party repository
- Version lock or exclusion
- Mixed release packages
- Module stream conflict
- Incorrect architecture
- Incomplete mirror synchronization

Do not bypass dependency protection without understanding the system-wide impact.

---

## 29. Locked Package Manager

Only one RPM transaction should modify the database at a time.

If DNF reports another process:

```bash
ps -ef | grep -E '[d]nf|[r]pm'
systemctl list-timers --all | grep -Ei 'dnf|update'
```

Determine whether:

- Another administrator is patching.
- Automation is running.
- A transaction is active.
- A process is genuinely stuck.

Do not delete lock files or kill package processes blindly. Interrupting a transaction can damage consistency.

---

## 30. RPM Database Problems

Symptoms may include:

- Query failures
- Database errors
- Inconsistent installed-package records
- Interrupted transaction aftermath

Start with read-only evidence:

```bash
rpm -qa >/dev/null
dnf check
journalctl --since "1 hour ago" | grep -Ei 'rpm|dnf'
```

Database recovery tools and internal formats differ by release.

`rpm --rebuilddb` is not a routine first step. Before any repair:

- Stop active package operations.
- Take an appropriate backup or snapshot.
- Record errors.
- Follow Red Hat or vendor guidance for the exact release.
- Validate packages and DNF afterward.

---

## 31. Production Patching Workflow

### Before the Change

1. Confirm scope and approved systems.
2. Review advisories and required packages.
3. Check repositories and subscription status.
4. Review dependencies and transaction preview.
5. Check disk space, especially `/`, `/var`, and `/boot`.
6. Check current kernel and service health.
7. Confirm backups and rollback.
8. Confirm cluster or load-balancer procedure.
9. Communicate maintenance impact.

Useful commands:

```bash
df -hT
df -i
uname -r
rpm -q kernel
systemctl --failed
dnf check-update
dnf upgrade --assumeno
```

### During the Change

1. Remove or drain the node from traffic if required.
2. Apply the approved package set.
3. Capture transaction output and ID.
4. Review warnings and failures.
5. Reboot only when approved and required.

### After the Change

1. Confirm boot and kernel.
2. Check failed services.
3. Validate applications and ports.
4. Review logs.
5. Return node to service.
6. Monitor.
7. Update ticket, evidence, and vulnerability status.

```bash
uname -r
systemctl --failed
journalctl -b -p err
sudo ss -tulpn
dnf history
```

---

## 32. Hands-On Lab

### Lab Safety

Use a disposable RHEL-family practice system with working repositories.

The lab uses `tree` as an example. If `tree` is already installed, choose another small, non-critical package and record that choice. Do not remove any package that existed before the lab.

### Task 1 — Identify the Platform

```bash
cat /etc/redhat-release
uname -r
dnf --version
rpm --version
```

### Task 2 — Create a Lab Directory

```bash
mkdir -p ~/linux-engineer-prep/module-07
cd ~/linux-engineer-prep/module-07
```

### Task 3 — Create Package Inventory

```bash
rpm -qa | sort > installed-packages-before.txt
dnf repolist --all > repositories.txt
```

Review:

```bash
wc -l installed-packages-before.txt
less repositories.txt
```

### Task 4 — Query an Installed Package

```bash
rpm -qi bash
rpm -ql bash | head
rpm -qc bash
rpm -qR bash | head
rpm -q --scripts bash
```

### Task 5 — Identify File Ownership

```bash
rpm -qf /usr/bin/bash
rpm -qf /usr/bin/systemctl
```

Find which repository package provides a command:

```bash
dnf provides '*/semanage'
```

### Task 6 — Verify a Package

```bash
rpm -V bash
```

No output commonly means no tracked differences.

Do not modify Bash package files to force a verification difference.

### Task 7 — Check Lab Package State

```bash
lab_package="tree"
printf '%s\n' "$lab_package" > lab-package-name.txt

if rpm -q "$lab_package" >/dev/null 2>&1; then
    echo "$lab_package was already installed. Choose another small lab package."
    printf '%s\n' 'preexisting' > lab-package-state.txt
else
    echo "$lab_package was not installed before the lab."
    printf '%s\n' 'absent' > lab-package-state.txt
fi
```

If you choose another package, update `lab-package-name.txt` and rerun this check. Do not continue to installation until `lab-package-state.txt` contains `absent`.

### Task 8 — Inspect and Preview

```bash
lab_package="$(< lab-package-name.txt)"
dnf info "$lab_package"
sudo dnf install "$lab_package" --assumeno
```

Read the complete transaction plan.

### Task 9 — Install

```bash
lab_package="$(< lab-package-name.txt)"
sudo dnf install "$lab_package"
```

Verify:

```bash
rpm -q "$lab_package"
dnf info "$lab_package"
command -v tree
```

### Task 10 — Inspect the Transaction

```bash
dnf history
```

Record the latest transaction ID:

```bash
dnf history info last > lab-install-transaction.txt
less lab-install-transaction.txt
```

### Task 11 — Inspect Package Files

```bash
rpm -ql "$lab_package"
rpm -qi "$lab_package"
rpm -V "$lab_package"
```

### Task 12 — Security Advisory Review

```bash
dnf updateinfo list security > security-updates.txt
dnf updateinfo info --security > security-advisories.txt
```

These files may be empty if no security updates are available or advisory metadata is unavailable.

### Task 13 — Kernel and Reboot Review

```bash
uname -r > running-kernel.txt
rpm -q kernel > installed-kernels.txt
df -hT /boot > boot-capacity.txt
```

If available:

```bash
dnf needs-restarting -r > reboot-advice.txt
```

Do not reboot merely because this is a lab module.

### Task 14 — Remove Only the Lab-Installed Package

Reload the recorded package name and confirm that it was absent before the lab:

```bash
lab_package="$(< lab-package-name.txt)"
lab_package_state="$(< lab-package-state.txt)"

if [[ "$lab_package_state" != "absent" ]]; then
    echo "Cleanup skipped: $lab_package existed before the lab."
else
    sudo dnf remove "$lab_package" --assumeno
fi
```

Review dependencies proposed for removal.

If the preview is correct, remove only the package that the lab installed:

```bash
if [[ "$lab_package_state" == "absent" ]]; then
    sudo dnf remove "$lab_package"
fi
```

Verify:

```bash
rpm -q "$lab_package"
dnf history info last > lab-remove-transaction.txt
```

Expected query result:

```text
package tree is not installed
```

### Task 15 — Compare Inventory

```bash
rpm -qa | sort > installed-packages-after.txt
diff -u installed-packages-before.txt installed-packages-after.txt
```

Expected: no difference if the lab package and its newly installed dependencies were completely returned to the original state. Review any differences rather than assuming cleanup was complete.

### Lab Deliverables

```text
module-07/
├── boot-capacity.txt
├── installed-kernels.txt
├── installed-packages-after.txt
├── installed-packages-before.txt
├── lab-package-name.txt
├── lab-package-state.txt
├── lab-install-transaction.txt
├── lab-remove-transaction.txt
├── repositories.txt
├── running-kernel.txt
├── security-advisories.txt
└── security-updates.txt
```

---

## 33. Production Troubleshooting Scenarios

### Scenario 1 — Package Installation Reports Missing Dependencies

Check:

```bash
dnf repolist
dnf info PACKAGE
dnf repoquery --requires PACKAGE
dnf module list
```

Investigate disabled repositories, module filtering, third-party conflicts, architecture, version locks, and mirror synchronization.

### Scenario 2 — Repository Metadata Cannot Be Downloaded

Check:

```bash
dnf repolist -v
ip route
getent hosts REPOSITORY_HOST
timedatectl
sudo dnf makecache --refresh
```

Then investigate proxy, TLS, CA trust, authentication, subscription, Satellite, and repository health.

### Scenario 3 — GPG Signature Check Fails

Do not disable GPG checking.

Verify:

- Repository source
- Package origin
- Expected signing key
- Repository configuration
- Whether metadata or package was altered
- Organizational security guidance

### Scenario 4 — `/boot` Is Full During Patching

Stop and assess:

```bash
df -hT /boot
ls -lh /boot
uname -r
rpm -q kernel
```

Do not delete the running or only known-good fallback kernel.

### Scenario 5 — Package Updated but Vulnerability Remains

Check:

- Running process still uses an old library
- Service restart required
- New kernel not running
- Vulnerable container image still deployed
- Advisory not applicable as expected
- Scanner cache or detection logic

### Scenario 6 — DNF Transaction Is Locked

Identify the active process and owner. Do not kill it or remove locks until confirming whether a real transaction is running.

### Scenario 7 — Service Fails After Package Upgrade

Check:

```bash
dnf history info last
systemctl status SERVICE
journalctl -u SERVICE
sudo find /etc -type f \( -name '*.rpmnew' -o -name '*.rpmsave' \) -print
```

Review configuration compatibility, dependency versions, SELinux, permissions, and application migration notes.

### Scenario 8 — `dnf history undo` Cannot Restore Service

Explain that package rollback does not reverse application data, schemas, configuration, or external dependencies. Use the complete application and infrastructure rollback plan.

---

## 34. Common Interview Questions and Answers

### 1. What is the difference between RPM and DNF?

RPM manages individual packages and the local RPM database. DNF uses repositories, resolves dependencies, downloads packages, plans transactions, and records history.

### 2. How do you check whether a package is installed?

```bash
rpm -q PACKAGE
```

### 3. How do you list files installed by a package?

```bash
rpm -ql PACKAGE
```

### 4. How do you find which package owns a file?

```bash
rpm -qf /path/to/file
```

### 5. How do you find which package provides a missing command?

```bash
dnf provides '*/command'
```

### 6. How do you inspect an RPM before installing it?

Use `rpm -qip`, `rpm -qlp`, `rpm -qRp`, `rpm -qp --scripts`, and signature verification.

### 7. Why use `dnf install ./package.rpm` instead of `rpm -ivh`?

DNF can resolve and install dependencies from repositories.

### 8. Why are `--nodeps` and `--force` dangerous?

They bypass protections and can leave inconsistent packages, broken dependencies, overwritten files, or an unsupported system.

### 9. What does `rpm -V PACKAGE` do?

It compares installed files and metadata with the RPM database’s expected values.

### 10. What does no output from `rpm -V` commonly mean?

No tracked differences were found.

### 11. Where are repository files commonly stored?

```text
/etc/yum.repos.d/
```

### 12. Why should `gpgcheck=1` remain enabled?

It helps verify that packages carry a signature from a trusted signing key.

### 13. How do you preview a DNF transaction?

```bash
dnf upgrade --assumeno
```

### 14. Is DNF history undo a complete system rollback?

No. It cannot reliably reverse application data, schema, configuration, or external system changes.

### 15. What are `.rpmnew` and `.rpmsave`?

They preserve alternate versions of configuration files during package transactions so changes can be reviewed and merged.

### 16. How do you list security advisories?

```bash
dnf updateinfo list security
```

### 17. Does installing a new kernel immediately change the running kernel?

No. The server must boot into the new kernel.

### 18. What should you check before a kernel update?

Current and installed kernels, `/boot` capacity, repository health, backup and rollback, fallback kernel, maintenance window, and application validation plan.

### 19. Why keep an older kernel?

It provides a known-good fallback if the new kernel has a boot, driver, or application compatibility problem.

### 20. How do you troubleshoot a repository failure?

I identify the exact error, inspect enabled repositories and configuration, verify routing, DNS, time, proxy, TLS, credentials, subscription, and repository health, isolate one repository, and keep GPG and TLS protections enabled.

### 21. How would you patch a production server?

I review advisories and dependencies, test, check capacity and health, confirm backup and rollback, drain traffic if required, apply approved updates, reboot if necessary, validate kernel, services and application, monitor, and record evidence.

---

## 35. Quick Knowledge Check

### Questions

1. What does RPM manage?
2. What additional function does DNF provide?
3. What does NEVRA represent?
4. Which command lists all installed packages?
5. Which command lists package configuration files?
6. Which command identifies the package owning `/usr/bin/ls`?
7. Which option lets RPM query a package file?
8. Which command verifies an RPM signature?
9. What does `rpm -V` compare?
10. Why is direct RPM installation less convenient?
11. Where are repository configuration files commonly stored?
12. Which setting enables package signature checking?
13. Which command previews an upgrade without approving it?
14. Is DNF rollback equivalent to a VM snapshot restore?
15. What does `.rpmnew` normally indicate?
16. Which command lists security updates?
17. Does a kernel update change the running kernel immediately?
18. What directory capacity should be checked before kernel updates?
19. Should you remove the currently running kernel?
20. What should you do first when DNF reports an active transaction?

### Answer Key

1. Individual packages, installed files, metadata, dependencies, scripts, and the local RPM database
2. Repository access, dependency solving, downloads, transaction planning, and history
3. Name, Epoch, Version, Release, and Architecture
4. `rpm -qa`
5. `rpm -qc PACKAGE`
6. `rpm -qf /usr/bin/ls`
7. `-p`
8. `rpm -K package.rpm`
9. Installed files and metadata against recorded package expectations
10. It does not normally download missing dependencies.
11. `/etc/yum.repos.d/`
12. `gpgcheck=1`
13. `dnf upgrade --assumeno`
14. No.
15. A new vendor configuration was saved separately while the current modified configuration was preserved.
16. `dnf updateinfo list security`
17. No.
18. `/boot`
19. No.
20. Identify the process and determine whether a legitimate transaction is running.

---

## 36. Interview Practice Exercises

### Exercise 1

> A critical vulnerability requires patching 100 production RHEL servers.

Cover:

- Inventory and advisory applicability
- Testing and phased rollout
- Maintenance and load-balancer draining
- Capacity and repository checks
- Backup and rollback
- Kernel and reboot handling
- Functional validation
- Monitoring and evidence

### Exercise 2

> DNF reports a package conflict after enabling a third-party repository.

Cover:

- Repository provenance
- Package versions and architecture
- Module streams
- Dependency and transaction preview
- Vendor support
- Avoiding force and nodeps
- Removing or correcting the unsupported source

### Exercise 3

> A server does not boot after a kernel update.

Cover:

- Console access
- Boot known-good kernel
- Capture boot and kernel logs
- Confirm initramfs and drivers
- Validate `/boot`
- Roll back through approved package procedure
- Determine root cause before retry

### Exercise 4

> `rpm -V` reports a digest and ownership change on a security-sensitive binary.

Cover:

- Preserve evidence
- Compare package metadata and known-good source
- Review authorized changes
- Check package signature and transaction history
- Treat unexplained modification as a potential incident
- Do not simply reinstall before evidence is collected

---

## 37. Engineer I vs. Engineer II Expectations

| Skill Area | Engineer I | Engineer II |
|---|---|---|
| RPM queries | Identifies packages and files | Investigates verification and provenance |
| DNF | Installs approved packages | Reviews dependencies and transaction risk |
| Repositories | Lists and refreshes | Troubleshoots TLS, GPG, subscription, proxy, and lifecycle |
| Security updates | Applies assigned updates | Plans risk-based remediation and validation |
| Kernels | Installs and verifies | Plans fallback, reboot, compatibility, and recovery |
| Rollback | Follows documented steps | Designs complete application and infrastructure rollback |
| Incidents | Collects package evidence | Leads package-integrity and patch-failure RCA |

---

## 38. Module Completion Checklist

- [ ] I can explain RPM versus DNF.
- [ ] I can read package NEVRA.
- [ ] I can query package information, files, configuration, dependencies, and scripts.
- [ ] I can identify the package that owns a file.
- [ ] I can inspect an RPM before installation.
- [ ] I can verify package signatures.
- [ ] I can interpret common `rpm -V` indicators.
- [ ] I understand why DNF is preferred for dependency resolution.
- [ ] I can list and inspect repositories.
- [ ] I can preview a DNF transaction.
- [ ] I understand DNF history limitations.
- [ ] I can explain module-stream risk.
- [ ] I can identify security advisories.
- [ ] I understand service restart and reboot requirements.
- [ ] I can safely plan a kernel update.
- [ ] I can troubleshoot repository failures without disabling security.
- [ ] I completed the hands-on lab.
- [ ] I answered the interview questions aloud.

---

## 39. Command Revision Sheet

```bash
rpm --version
rpm -qa
rpm -q PACKAGE
rpm -qi PACKAGE
rpm -ql PACKAGE
rpm -qc PACKAGE
rpm -qd PACKAGE
rpm -qR PACKAGE
rpm -q --provides PACKAGE
rpm -q --scripts PACKAGE
rpm -qf /path/to/file
rpm -qip package.rpm
rpm -qlp package.rpm
rpm -qRp package.rpm
rpm -qp --scripts package.rpm
rpm -K package.rpm
rpm -V PACKAGE
sudo rpm -Va
dnf --version
dnf repolist
dnf repolist --all
dnf repolist -v
dnf list installed
dnf search KEYWORD
dnf info PACKAGE
dnf provides '*/command'
dnf repoquery PACKAGE
dnf repoquery --requires PACKAGE
sudo dnf install PACKAGE
sudo dnf install ./package.rpm
sudo dnf remove PACKAGE
sudo dnf reinstall PACKAGE
sudo dnf upgrade PACKAGE
sudo dnf upgrade
sudo dnf downgrade PACKAGE
sudo dnf upgrade --assumeno
sudo dnf makecache --refresh
sudo dnf clean all
dnf group list
dnf module list
dnf history
dnf history info TRANSACTION_ID
dnf updateinfo list security
dnf updateinfo info --security
sudo dnf upgrade --security
dnf needs-restarting
dnf needs-restarting -r
uname -r
rpm -q kernel
sudo grubby --default-kernel
sudo grubby --info=ALL
df -hT /boot
subscription-manager status
subscription-manager repos --list-enabled
```

---

## Next Module

**Module 08 — Partitions, Filesystems, Mounts, and Swap**

Topics will include:

- Block devices and partitions
- GPT and MBR
- `lsblk`, `blkid`, and `fdisk`
- Filesystem creation and labels
- Mounting and `/etc/fstab`
- UUIDs and persistent mounts
- XFS and ext4
- Filesystem capacity and inode usage
- Swap creation and management
- Safe storage expansion
- Boot and mount troubleshooting
- Practical lab and interview questions
