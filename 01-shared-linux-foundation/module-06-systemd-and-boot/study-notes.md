# Linux Systems Engineer II Interview Preparation

## Module 06 — systemd Services and Linux Boot Process

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 75–90 minutes

> Perform recovery-mode, bootloader, target-isolation, and system-level unit experiments only on a disposable lab machine with console access. A mistake can make a server unavailable over SSH.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain the complete RHEL boot sequence.
- Describe BIOS, UEFI, GRUB, the kernel, initramfs, and systemd.
- Identify the running and default kernels.
- Explain why initramfs is needed.
- Identify systemd unit types and unit-file locations.
- Explain unit-file precedence.
- Manage service runtime and boot-time state.
- Explain active, enabled, disabled, static, masked, and failed states.
- Interpret dependency and ordering directives.
- Create a service unit and a drop-in override.
- Configure restart behavior and timeouts.
- Understand targets, rescue mode, and emergency mode.
- Use `journalctl` to investigate a service or boot.
- Analyze boot duration and critical dependencies.
- Troubleshoot failed services, restart loops, and emergency-mode boots.

---

## 2. The RHEL Boot Sequence

A simplified boot sequence is:

```text
Power on
   ↓
BIOS or UEFI firmware
   ↓
Bootloader — normally GRUB 2
   ↓
Linux kernel and initramfs
   ↓
Real root filesystem
   ↓
systemd as PID 1
   ↓
Units, targets, services, mounts, and sockets
   ↓
Login or application availability
```

Each stage has different failure symptoms and troubleshooting methods.

---

## 3. Stage 1 — BIOS or UEFI Firmware

Firmware:

- Initializes hardware.
- Performs basic hardware checks.
- Selects a boot device.
- Loads the next boot component.

### BIOS

Traditional BIOS commonly begins from boot code associated with a disk’s boot sector.

### UEFI

UEFI commonly loads an EFI executable from the EFI System Partition.

Determine the current boot mode:

```bash
if [[ -d /sys/firmware/efi ]]; then
    echo "UEFI boot"
else
    echo "Legacy BIOS boot"
fi
```

Inspect EFI variables when available:

```bash
sudo efibootmgr -v
```

The command may be unavailable or inappropriate inside some virtual machines, containers, or WSL environments.

---

## 4. Stage 2 — GRUB 2 Bootloader

GRUB:

- Presents the boot menu.
- Selects a kernel.
- Supplies kernel command-line arguments.
- Loads the kernel and initramfs into memory.
- Transfers control to the kernel.

Inspect kernel command line used for the current boot:

```bash
cat /proc/cmdline
```

List boot menu information:

```bash
sudo grubby --info=ALL
```

Display the default kernel:

```bash
sudo grubby --default-kernel
```

Display the running kernel:

```bash
uname -r
```

The default kernel and running kernel can differ if:

- A new kernel was installed but the server has not rebooted.
- Another boot entry was selected.
- The previous boot failed and an older entry was chosen.

### GRUB Configuration Safety

Do not manually edit generated GRUB configuration files as a routine procedure.

RHEL versions and BIOS/UEFI layouts differ. Prefer supported tools such as `grubby` and follow the procedure for the exact RHEL major version and boot mode.

Before changing bootloader configuration:

- Confirm console or out-of-band access.
- Record the current configuration.
- Confirm a known-good kernel remains available.
- Prepare rollback steps.
- Use change management.

---

## 5. Stage 3 — Kernel and initramfs

The kernel:

- Initializes CPU and memory management.
- Detects hardware.
- Loads required drivers.
- Initializes core subsystems.
- Uses the initramfs to reach the real root filesystem.
- Starts the first userspace process.

### What Is initramfs?

The initial RAM filesystem is a temporary early userspace environment.

It may contain:

- Storage drivers
- Filesystem drivers
- LVM tools
- RAID tools
- Encryption tools
- Device discovery utilities
- Scripts needed to locate and mount the real root filesystem

Without the required components, the kernel may be unable to access the root filesystem.

List initramfs images:

```bash
ls -lh /boot/initramfs-*
```

Inspect an image:

```bash
lsinitrd /boot/initramfs-$(uname -r).img
```

Rebuilding initramfs is normally performed with `dracut`, but it is a high-impact operation:

```bash
sudo dracut --force
```

Use it only when you understand the problem, target kernel, required drivers, and recovery plan.

### Early-Boot Failure Clues

Possible messages include:

- Unable to find root device
- Unknown filesystem
- LVM volume not found
- Encrypted device unavailable
- Dracut emergency shell

Investigate storage identity, kernel arguments, initramfs contents, LVM, RAID, encryption, and device availability.

---

## 6. Stage 4 — systemd as PID 1

The kernel starts the initial userspace process.

On modern RHEL:

```bash
ps -p 1 -o pid,ppid,comm,args
```

Expected command:

```text
systemd
```

systemd:

- Starts and supervises services.
- Mounts filesystems.
- Activates sockets and devices.
- Manages targets and dependencies.
- Tracks processes using cgroups.
- Starts timers.
- Integrates with the journal.
- Manages shutdown and reboot.

Check the systemd version:

```bash
systemctl --version
```

---

## 7. What Is a systemd Unit?

A unit is an object managed by systemd.

Common unit types:

| Unit Type | Suffix | Purpose |
|---|---|---|
| Service | `.service` | Daemon or application process |
| Socket | `.socket` | Socket-based activation |
| Target | `.target` | Grouping and synchronization point |
| Timer | `.timer` | Time-based activation |
| Mount | `.mount` | Filesystem mount |
| Automount | `.automount` | On-demand mount |
| Path | `.path` | Path-based activation |
| Device | `.device` | Kernel device |
| Swap | `.swap` | Swap area |
| Slice | `.slice` | Resource-management hierarchy |
| Scope | `.scope` | Externally created process group |

List loaded unit files:

```bash
systemctl list-units
```

All loaded units:

```bash
systemctl list-units --all
```

Installed unit files:

```bash
systemctl list-unit-files
```

---

## 8. Unit-File Locations and Precedence

Important system unit locations:

| Location | Purpose |
|---|---|
| `/etc/systemd/system/` | Administrator-created units and overrides |
| `/run/systemd/system/` | Runtime-generated units |
| `/usr/lib/systemd/system/` | Vendor or package-provided units |

General precedence:

```text
/etc/systemd/system
        ↓ overrides
/run/systemd/system
        ↓ overrides
/usr/lib/systemd/system
```

For user units:

```text
~/.config/systemd/user/
```

### Best Practice

Do not directly edit package-provided files under:

```text
/usr/lib/systemd/system/
```

A package update may replace them.

Use:

```bash
sudo systemctl edit SERVICE
```

This creates a drop-in override under `/etc/systemd/system/`.

Display the effective unit and drop-ins:

```bash
systemctl cat SERVICE
```

---

## 9. Service Runtime Operations

Start:

```bash
sudo systemctl start SERVICE
```

Stop:

```bash
sudo systemctl stop SERVICE
```

Restart:

```bash
sudo systemctl restart SERVICE
```

Reload configuration without a complete restart, when supported:

```bash
sudo systemctl reload SERVICE
```

Reload if supported, otherwise restart:

```bash
sudo systemctl reload-or-restart SERVICE
```

Status:

```bash
systemctl status SERVICE
```

Check active state for scripts:

```bash
systemctl is-active SERVICE
```

### Restart vs. Reload

- `restart` stops and starts the service, usually causing interruption.
- `reload` asks the running service to reread configuration, if supported.

Always validate configuration before either action when the application provides a validation command.

---

## 10. Boot-Time Enablement

Enable at boot:

```bash
sudo systemctl enable SERVICE
```

Enable and start now:

```bash
sudo systemctl enable --now SERVICE
```

Disable at boot:

```bash
sudo systemctl disable SERVICE
```

Disable and stop now:

```bash
sudo systemctl disable --now SERVICE
```

Check:

```bash
systemctl is-enabled SERVICE
```

### Important Difference

| State | Question Answered |
|---|---|
| Active | Is it running now? |
| Enabled | Is it configured to start through boot dependencies? |

A service can be:

- Active but disabled
- Inactive but enabled
- Active and enabled
- Inactive and disabled

---

## 11. Common Enablement States

| State | Meaning |
|---|---|
| `enabled` | Has enablement links or equivalent boot integration |
| `disabled` | Not enabled for automatic startup |
| `static` | Has no normal `[Install]` enablement rule; started as a dependency or manually |
| `indirect` | Enabled through another unit or alias mechanism |
| `masked` | Linked to `/dev/null`; cannot be started normally |
| `generated` | Created dynamically by a generator |
| `transient` | Created at runtime rather than stored as a normal unit file |

Exact states can vary with systemd version and unit design.

---

## 12. Masking a Service

Mask:

```bash
sudo systemctl mask SERVICE
```

Unmask:

```bash
sudo systemctl unmask SERVICE
```

Masking is stronger than disabling:

- Disabled: can still be started manually or as a dependency.
- Masked: normal activation is blocked because the unit resolves to `/dev/null`.

Before masking:

- Identify dependent services.
- Check application and customer impact.
- Follow change management.

View reverse dependencies:

```bash
systemctl list-dependencies --reverse SERVICE
```

---

## 13. Reading `systemctl status`

```bash
systemctl status SERVICE
```

Important fields:

- Loaded unit-file path
- Enablement state
- Active state
- Start time
- Main PID
- Process status
- Cgroup
- Recent journal messages
- Exit code or signal

Do not stop at the final error line. Continue with:

```bash
journalctl -u SERVICE
systemctl cat SERVICE
systemctl show SERVICE
```

---

## 14. Unit File Structure

A common service unit:

```ini
[Unit]
Description=Example Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=example
Group=example
WorkingDirectory=/opt/example
ExecStart=/opt/example/bin/application
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

### `[Unit]`

Contains:

- Description
- Documentation
- Dependency relationships
- Ordering rules
- Conditions

### `[Service]`

Contains:

- Service type
- Command
- User and group
- Working directory
- Environment
- Restart behavior
- Timeouts
- Resource and security controls

### `[Install]`

Defines how enablement creates relationships such as:

```ini
WantedBy=multi-user.target
```

The `[Install]` section does not start the service by itself.

---

## 15. Important Service Directives

| Directive | Purpose |
|---|---|
| `Type=` | How systemd determines startup behavior |
| `ExecStart=` | Main startup command |
| `ExecStartPre=` | Command before the main start |
| `ExecStartPost=` | Command after startup |
| `ExecReload=` | Reload command |
| `ExecStop=` | Explicit stop command when needed |
| `User=` | Service account |
| `Group=` | Service group |
| `WorkingDirectory=` | Current directory for the process |
| `Environment=` | Environment value |
| `EnvironmentFile=` | File containing environment values |
| `Restart=` | Restart policy |
| `RestartSec=` | Delay before restart |
| `TimeoutStartSec=` | Startup timeout |
| `TimeoutStopSec=` | Shutdown timeout |
| `KillSignal=` | Signal used for termination |
| `LimitNOFILE=` | Open-file limit |
| `MemoryMax=` | Cgroup memory limit |
| `CPUQuota=` | CPU usage control |

Use absolute executable paths for clarity and predictable behavior.

---

## 16. Service Types

Common `Type=` values:

| Type | Meaning |
|---|---|
| `simple` | Main process is the `ExecStart` process; startup is considered immediate |
| `exec` | Similar to simple, but startup success waits until program execution succeeds |
| `forking` | Program forks and parent exits; traditional daemon style |
| `oneshot` | One-time task expected to exit |
| `notify` | Service sends a readiness notification |
| `dbus` | Readiness associated with acquiring a D-Bus name |
| `idle` | Start execution is delayed until queued jobs are dispatched |

For a new foreground-running daemon, `simple`, `exec`, or `notify` is commonly preferable to unnecessary self-daemonization.

---

## 17. Dependencies vs. Ordering

These concepts are related but different.

### Dependency Directives

```ini
Wants=network-online.target
Requires=database.service
```

- `Wants=` is a weaker dependency.
- `Requires=` is stronger, but does not automatically define every desired runtime-failure behavior.

### Ordering Directives

```ini
After=network-online.target
Before=application.service
```

- `After=` and `Before=` control ordering.
- They do not automatically pull another unit into the transaction.

### Strong Interview Point

> `After=` does not mean “start this dependency.” It only defines order if both units are being started.

To request both activation and ordering, a unit commonly uses both:

```ini
Wants=network-online.target
After=network-online.target
```

Inspect:

```bash
systemctl list-dependencies SERVICE
systemctl list-dependencies --reverse SERVICE
systemctl show SERVICE -p Wants -p Requires -p After -p Before
```

---

## 18. Reloading the systemd Manager

After creating or editing a unit file:

```bash
sudo systemctl daemon-reload
```

This tells the systemd manager to reread unit definitions.

It does not automatically restart the service.

Typical sequence:

```bash
sudo systemctl daemon-reload
sudo systemctl restart SERVICE
systemctl status SERVICE
```

For a user unit:

```bash
systemctl --user daemon-reload
systemctl --user restart SERVICE
```

---

## 19. Drop-In Overrides

Create a system override:

```bash
sudo systemctl edit SERVICE
```

Typical location:

```text
/etc/systemd/system/SERVICE.d/override.conf
```

Example:

```ini
[Service]
Restart=on-failure
RestartSec=10s
```

Apply:

```bash
sudo systemctl daemon-reload
sudo systemctl restart SERVICE
```

Inspect:

```bash
systemctl cat SERVICE
systemctl show SERVICE -p Restart -p RestartUSec
```

Remove local changes carefully:

```bash
sudo systemctl revert SERVICE
```

Review what `revert` will remove before using it on a production service.

---

## 20. Replacing List-Type Directives

Some directives can contain multiple entries.

To replace an existing command such as `ExecStart=`, first reset it:

```ini
[Service]
ExecStart=
ExecStart=/new/absolute/command
```

Without the empty assignment, the override may add another value or fail validation depending on the directive.

Inspect the complete effective unit:

```bash
systemctl cat SERVICE
```

Validate unit syntax:

```bash
systemd-analyze verify /path/to/unit.service
```

Validation cannot guarantee that the application itself will start successfully.

---

## 21. Restart Policies

Common values:

| Policy | Behavior |
|---|---|
| `no` | Do not restart automatically |
| `on-success` | Restart after clean exit |
| `on-failure` | Restart after unsuccessful exit or abnormal termination |
| `on-abnormal` | Restart after abnormal termination |
| `on-abort` | Restart after uncaught signal conditions |
| `on-watchdog` | Restart after watchdog timeout |
| `always` | Restart regardless of exit reason |

Example:

```ini
[Service]
Restart=on-failure
RestartSec=5s
```

### Restart Loop Protection

systemd can rate-limit repeated starts.

Relevant directives include:

```ini
[Unit]
StartLimitIntervalSec=60
StartLimitBurst=5
```

Inspect restart count:

```bash
systemctl show SERVICE -p NRestarts
```

Clear a failed/rate-limited state after correcting the root cause:

```bash
sudo systemctl reset-failed SERVICE
```

Do not repeatedly reset and restart a broken service without investigating its failure.

---

## 22. Service Timeouts and Signals

Example:

```ini
[Service]
TimeoutStartSec=90s
TimeoutStopSec=30s
KillSignal=SIGTERM
```

During stop, systemd normally:

1. Sends the configured termination signal.
2. Waits for the stop timeout.
3. May forcibly terminate remaining processes according to unit settings.

Applications should handle graceful shutdown and complete cleanup within the approved timeout.

If a service is force-killed during every stop, investigate:

- Shutdown handler
- Dependencies
- Storage or network blocking
- Timeout sizing
- Application defects

---

## 23. Environment Variables

Direct definition:

```ini
[Service]
Environment="APP_MODE=production"
Environment="PORT=8080"
```

Environment file:

```ini
[Service]
EnvironmentFile=/etc/example/application.env
```

Important:

- Protect files containing secrets.
- Environment values may be visible through process inspection or privileged interfaces.
- systemd environment parsing is not identical to a shell script.
- Shell expansions and pipelines are not automatically interpreted by `ExecStart=`.

If shell syntax is genuinely required:

```ini
ExecStart=/usr/bin/bash -c 'command'
```

Use this deliberately because it adds quoting, security, and error-handling complexity.

---

## 24. systemd Targets

Targets group units and represent system states or synchronization points.

Common targets:

| Target | Purpose |
|---|---|
| `multi-user.target` | Multi-user, non-graphical system |
| `graphical.target` | Graphical environment plus multi-user services |
| `rescue.target` | Single-user recovery with more services and mounts |
| `emergency.target` | Minimal emergency shell |
| `reboot.target` | Reboot |
| `poweroff.target` | Power off |

Display default:

```bash
systemctl get-default
```

Set default:

```bash
sudo systemctl set-default multi-user.target
```

List target dependencies:

```bash
systemctl list-dependencies multi-user.target
```

---

## 25. Rescue vs. Emergency Mode

### Rescue Mode

Generally provides:

- Single-user recovery environment
- More initialized services than emergency mode
- Local filesystems mounted
- A root shell after required authentication

### Emergency Mode

Generally provides:

- Very minimal environment
- Root filesystem mounted with limited assumptions
- Fewer services and dependencies
- Low-level repair access

### High-Risk Commands

```bash
sudo systemctl isolate rescue.target
sudo systemctl isolate emergency.target
```

Isolation stops units not required by the target. This can terminate networking and your SSH session.

Use only with:

- Approved maintenance
- Console or out-of-band access
- Recovery plan
- Customer-impact communication

---

## 26. The systemd Journal

The journal collects structured logs from:

- Kernel
- systemd units
- Standard output and error of services
- Syslog integrations
- Audit-related sources in some configurations

### Current Boot

```bash
journalctl -b
```

### Previous Boot

```bash
journalctl -b -1
```

Previous-boot logs require persistent journal storage or another retained log source.

### Specific Service

```bash
journalctl -u SERVICE
```

Current boot and service:

```bash
journalctl -b -u SERVICE
```

Follow:

```bash
journalctl -f -u SERVICE
```

Recent time:

```bash
journalctl -u SERVICE --since "30 minutes ago"
```

### Priority

Errors and more severe:

```bash
journalctl -p err
```

Current boot:

```bash
journalctl -b -p err
```

### Kernel

```bash
journalctl -k
journalctl -k -b
```

### Detailed Service Failure

```bash
journalctl -xeu SERVICE
```

`-x` can add catalog explanations when available. Treat generated explanatory text as guidance, not proof of the root cause.

---

## 27. Journal Persistence

Common journal storage locations:

```text
/run/log/journal/   → volatile
/var/log/journal/   → persistent
```

Inspect configuration:

```bash
grep -Ev '^[[:space:]]*(#|$)' /etc/systemd/journald.conf
```

Check disk usage:

```bash
journalctl --disk-usage
```

Retention changes affect troubleshooting and compliance. Do not delete or vacuum production logs without understanding organizational retention requirements.

---

## 28. Boot Performance Analysis

Overall:

```bash
systemd-analyze
```

Units by activation time:

```bash
systemd-analyze blame
```

Critical dependency chain:

```bash
systemd-analyze critical-chain
```

Specific unit:

```bash
systemd-analyze critical-chain SERVICE
```

### Interpretation Warning

`systemd-analyze blame` shows how long units remained activating. It does not automatically prove that the first-listed unit delayed the entire boot because units start in parallel.

Use the critical chain, logs, dependencies, storage, network, and service behavior together.

---

## 29. Failed Unit Investigation

List:

```bash
systemctl --failed
```

Inspect:

```bash
systemctl status SERVICE
journalctl -b -u SERVICE
systemctl cat SERVICE
systemctl show SERVICE
```

Check configuration using the application’s own validator.

Examples:

```bash
sudo sshd -t
sudo nginx -t
sudo apachectl configtest
```

Use only the validator appropriate to the installed application.

After correcting:

```bash
sudo systemctl reset-failed SERVICE
sudo systemctl start SERVICE
systemctl status SERVICE
```

---

## 30. Common Reasons a Service Fails

- Configuration syntax error
- Missing file or directory
- Wrong ownership or permissions
- SELinux denial
- Port already in use
- Dependency unavailable
- Incorrect environment variable
- Missing library or package
- Invalid service account
- Read-only filesystem
- Resource limit
- Timeout
- Application crash
- Incorrect unit override

Useful commands:

```bash
systemctl status SERVICE
journalctl -xeu SERVICE
sudo ss -tulpn
namei -l /path/used/by/service
ls -lZ /path/used/by/service
sudo ausearch -m AVC,USER_AVC -ts recent
```

---

## 31. Boot Failure and Emergency Mode

Common causes:

- Invalid `/etc/fstab` entry
- Missing disk or LVM volume
- Filesystem corruption
- Incorrect UUID
- Failed encrypted-volume unlock
- Broken initramfs
- Kernel or driver issue
- Critical unit dependency failure
- SELinux relabeling or policy issue

Inspect filesystems:

```bash
findmnt
lsblk -f
blkid
cat /etc/fstab
```

Verify fstab structure and mount relationships:

```bash
findmnt --verify
```

Testing all fstab mounts with `mount -a` can contact remote storage or expose configuration problems. Use it only when the impact is understood.

### `/etc/fstab` Improvement Options

Depending on requirements:

- Correct UUID or device identity
- Use `_netdev` for appropriate network-dependent filesystems
- Use `nofail` only when boot should continue without that mount
- Configure systemd automount behavior
- Correct timeouts

Do not add `nofail` to a business-critical mount simply to hide a failure.

---

## 32. Kernel and Boot History

Current kernel:

```bash
uname -r
```

Installed kernel packages:

```bash
rpm -q kernel
```

Boot history:

```bash
journalctl --list-boots
```

Previous boot errors:

```bash
journalctl -b -1 -p err
```

Reboot history:

```bash
last -x | head
```

Correlate:

- Patch and change records
- Reboot time
- Selected kernel
- Hardware or cloud events
- Application recovery

---

## 33. Hands-On Lab — User-Level systemd Service

### Why a User Service?

This lab avoids changing `/etc/systemd/system` and avoids running a custom process as root.

Requirements:

- systemd user manager is available.
- Run from a normal user account.
- Do not run the lab as root.

### Task 1 — Confirm systemd

```bash
ps -p 1 -o pid,comm,args
systemctl --version
systemctl --user status
```

If the user manager is not available in your environment, perform the reading and investigation tasks but do not force the lab onto a non-systemd environment.

### Task 2 — Create Directories

```bash
mkdir -p ~/linux-engineer-prep/module-06
mkdir -p ~/.config/systemd/user
cd ~/linux-engineer-prep/module-06
```

### Task 3 — Create the Worker Script

```bash
vim demo-worker.sh
```

Add:

```bash
#!/usr/bin/env bash

set -u

interval="${INTERVAL:-10}"

handle_term() {
    echo "Module 06 worker received termination request"
    exit 0
}

trap handle_term TERM INT

echo "Module 06 worker starting with interval=${interval}s"

while true; do
    echo "Module 06 heartbeat: $(date --iso-8601=seconds)"
    sleep "$interval"
done
```

Make executable and validate:

```bash
chmod u+x demo-worker.sh
bash -n demo-worker.sh
```

### Task 4 — Create the User Unit

```bash
vim ~/.config/systemd/user/module06-demo.service
```

Add the following, replacing `YOUR_USERNAME` with your actual username:

```ini
[Unit]
Description=Module 06 User Service Lab

[Service]
Type=simple
ExecStart=/home/YOUR_USERNAME/linux-engineer-prep/module-06/demo-worker.sh
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=default.target
```

Confirm your home directory:

```bash
echo "$HOME"
```

If your home directory is not `/home/YOUR_USERNAME`, use the correct absolute path.

### Task 5 — Validate the Unit

```bash
systemd-analyze --user verify ~/.config/systemd/user/module06-demo.service
```

No output commonly means no validation error was found.

### Task 6 — Reload and Start

```bash
systemctl --user daemon-reload
systemctl --user start module06-demo.service
```

Check:

```bash
systemctl --user status module06-demo.service
systemctl --user is-active module06-demo.service
```

### Task 7 — Inspect Logs

```bash
journalctl --user -u module06-demo.service
```

Follow:

```bash
journalctl --user -f -u module06-demo.service
```

Press `Ctrl+C` to stop following the journal. This does not stop the service.

### Task 8 — Inspect PID and Cgroup

```bash
systemctl --user show module06-demo.service \
  -p MainPID \
  -p ActiveState \
  -p SubState \
  -p ControlGroup \
  -p NRestarts
```

Capture PID:

```bash
main_pid="$(
    systemctl --user show module06-demo.service \
      --property=MainPID \
      --value
)"
```

Inspect:

```bash
ps -p "$main_pid" -o pid,ppid,user,stat,etime,cmd
cat "/proc/$main_pid/cgroup"
```

### Task 9 — Enable the User Service

```bash
systemctl --user enable module06-demo.service
systemctl --user is-enabled module06-demo.service
```

User-service startup behavior after logout or reboot depends on whether the user manager starts and whether lingering is enabled. Do not enable lingering on a managed system without policy approval.

### Task 10 — Create an Override

```bash
systemctl --user edit module06-demo.service
```

Add:

```ini
[Service]
Environment="INTERVAL=5"
```

Apply:

```bash
systemctl --user daemon-reload
systemctl --user restart module06-demo.service
```

Verify:

```bash
systemctl --user cat module06-demo.service
journalctl --user -u module06-demo.service -n 20
```

The restart should show a new startup message with a 5-second interval.

### Task 11 — Observe Graceful Stop

```bash
systemctl --user stop module06-demo.service
journalctl --user -u module06-demo.service -n 10
```

Confirm:

```bash
systemctl --user is-active module06-demo.service
```

Expected:

```text
inactive
```

### Task 12 — Clean Up

Disable:

```bash
systemctl --user disable module06-demo.service
```

Remove only the lab unit and override:

```bash
rm -f ~/.config/systemd/user/module06-demo.service
rm -f ~/.config/systemd/user/module06-demo.service.d/override.conf
rmdir ~/.config/systemd/user/module06-demo.service.d 2>/dev/null || true
```

Reload and clear state:

```bash
systemctl --user daemon-reload
systemctl --user reset-failed
```

Keep `demo-worker.sh` as your lab deliverable.

### Task 13 — Read-Only Boot Investigation

```bash
systemctl get-default
systemctl --failed
journalctl --list-boots
journalctl -b -p err
systemd-analyze
systemd-analyze critical-chain
cat /proc/cmdline
uname -r
```

### Lab Deliverables

```text
module-06/
└── demo-worker.sh
```

You should also be able to demonstrate:

- Unit validation
- Manager reload
- Start and stop
- Enable and disable
- Journal inspection
- PID and cgroup inspection
- Drop-in override
- Graceful termination

---

## 34. Production Troubleshooting Scenarios

### Scenario 1 — Service Is Enabled but Not Running

Explain:

- Enabled describes boot-time activation.
- Active describes current runtime state.

Investigate:

```bash
systemctl is-enabled SERVICE
systemctl is-active SERVICE
systemctl status SERVICE
journalctl -b -u SERVICE
```

### Scenario 2 — Service Starts Manually but Not After Reboot

Check:

```bash
systemctl is-enabled SERVICE
systemctl list-dependencies multi-user.target
journalctl -b -u SERVICE
systemctl cat SERVICE
```

Possible causes:

- Not enabled
- Wrong target relationship
- Dependency unavailable during boot
- Ordering problem
- Network not ready
- Mount unavailable
- Environment differs from interactive shell

### Scenario 3 — Service Enters a Restart Loop

Check:

```bash
systemctl status SERVICE
journalctl -u SERVICE --since "15 minutes ago"
systemctl show SERVICE -p Restart -p RestartUSec -p NRestarts
```

Stop the loop through the approved incident process if it is causing harm, then correct the application or configuration failure.

### Scenario 4 — `start request repeated too quickly`

systemd rate limiting has been reached.

Investigate the actual start failure first:

```bash
journalctl -u SERVICE
systemctl status SERVICE
```

After correcting:

```bash
sudo systemctl reset-failed SERVICE
sudo systemctl start SERVICE
```

### Scenario 5 — Service Works in Shell but Fails in systemd

Compare:

- User and group
- Working directory
- Environment variables
- PATH and executable path
- File permissions and SELinux
- Resource limits
- Shell syntax
- Required mounts and network dependencies

Inspect:

```bash
systemctl cat SERVICE
systemctl show SERVICE
journalctl -xeu SERVICE
```

### Scenario 6 — Server Boots into Emergency Mode

Check console messages and:

```bash
journalctl -xb
cat /etc/fstab
findmnt --verify
lsblk -f
blkid
```

Common root cause: invalid or unavailable fstab storage.

Correct only after verifying the intended device, UUID, filesystem, and business requirement.

### Scenario 7 — Boot Became Slow After a Change

Use:

```bash
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
journalctl -b
```

Correlate with:

- Change record
- Storage and network readiness
- Timeouts
- Failed dependencies
- Application startup
- Cloud initialization

### Scenario 8 — Service Cannot Bind Its Port

Check:

```bash
systemctl status SERVICE
journalctl -u SERVICE
sudo ss -tulpn
```

Determine whether:

- Another process owns the port
- A stale instance remains
- The service is configured for the wrong address
- Privilege or SELinux policy blocks binding

---

## 35. Common Interview Questions and Answers

### 1. Explain the Linux boot sequence.

Firmware initializes hardware, GRUB loads the kernel and initramfs, the kernel initializes the system and mounts the real root through initramfs, then starts systemd as PID 1. systemd activates targets, mounts, sockets, services, and the login or application environment.

### 2. What is initramfs?

It is a temporary early userspace filesystem containing tools and drivers required to locate and mount the real root filesystem.

### 3. What is PID 1 on modern RHEL?

Normally `systemd`.

### 4. What is a systemd unit?

An object managed by systemd, such as a service, socket, target, timer, mount, device, or path.

### 5. Where are system unit files stored?

Common locations are `/usr/lib/systemd/system`, `/run/systemd/system`, and `/etc/systemd/system`, with administrator configuration under `/etc` taking precedence.

### 6. Why should you not edit `/usr/lib/systemd/system/SERVICE` directly?

It is package-managed and may be overwritten by updates. Use a drop-in override under `/etc/systemd/system`.

### 7. What is the difference between `start` and `enable`?

`start` changes the current runtime state. `enable` configures boot-time activation relationships.

### 8. Can a service be active and disabled?

Yes. It may have been started manually but not configured for boot.

### 9. What is the difference between disabled and masked?

A disabled unit can still be started manually or by a dependency. A masked unit is blocked from normal activation.

### 10. What does `systemctl daemon-reload` do?

It tells the systemd manager to reread unit definitions. It does not restart services automatically.

### 11. What is the difference between restart and reload?

Restart stops and starts the service. Reload asks the running service to reread configuration if it supports that operation.

### 12. What is the difference between `Wants=` and `After=`?

`Wants=` adds a weak activation dependency. `After=` controls ordering if both units participate in the transaction.

### 13. Does `After=network.target` guarantee the network is usable?

No. Ordering after a target does not necessarily guarantee usable addresses, routes, DNS, or external connectivity. Use the correct readiness design for the application.

### 14. What is a static unit?

A unit without ordinary enablement instructions. It is commonly started as a dependency or manually.

### 15. How do you view the effective unit including overrides?

```bash
systemctl cat SERVICE
```

### 16. How do you investigate a failed service?

Use `systemctl status`, `journalctl -u`, inspect the effective unit, run the application’s configuration validator, and check dependencies, permissions, SELinux, ports, environment, and recent changes.

### 17. What is `rescue.target`?

A recovery-oriented single-user state with more services and mounts than emergency mode.

### 18. What is `emergency.target`?

A minimal emergency environment for low-level repair.

### 19. Why is `systemctl isolate emergency.target` dangerous over SSH?

It may stop networking and other units not required by the target, disconnecting the session.

### 20. How do you view logs from the previous boot?

```bash
journalctl -b -1
```

This requires retained logs.

### 21. How do you identify the slowest boot dependency chain?

```bash
systemd-analyze critical-chain
```

### 22. Why is `systemd-analyze blame` not proof of the boot bottleneck?

Units start in parallel. A long activation time does not automatically mean the unit delayed the complete boot.

### 23. How do you clear a failed state?

```bash
systemctl reset-failed SERVICE
```

Correct the root cause first.

### 24. How would you troubleshoot a server booting into emergency mode?

I would use console access, review the current boot journal, inspect fstab, block devices, UUIDs, LVM, and mount verification, identify the critical failed unit, correct the configuration or storage condition, test carefully, and reboot only after preparing rollback.

---

## 36. Quick Knowledge Check

### Questions

1. Which component normally loads the kernel?
2. What is the purpose of initramfs?
3. Which process normally has PID 1?
4. Which directory contains administrator system units and overrides?
5. Which directory commonly contains vendor unit files?
6. Does `systemctl enable` necessarily start a service immediately?
7. Can a disabled service be running?
8. What is stronger than disabling a unit?
9. Which command reloads unit definitions?
10. Does `daemon-reload` restart the service?
11. Which directive controls ordering?
12. Does `After=` pull another unit into the transaction?
13. Which command displays the effective unit and drop-ins?
14. Which command lists failed units?
15. Which command displays logs for the current boot?
16. Which command displays logs for the previous boot?
17. Which command displays the boot critical chain?
18. What is the difference between rescue and emergency mode?
19. Which file is a common cause of emergency-mode boot?
20. Why should vendor unit files not be edited directly?

### Answer Key

1. GRUB or another bootloader
2. It supplies early userspace tools and drivers needed to reach the real root filesystem.
3. `systemd`
4. `/etc/systemd/system`
5. `/usr/lib/systemd/system`
6. No. Use `enable --now` to enable and start.
7. Yes.
8. Masking
9. `systemctl daemon-reload`
10. No.
11. `After=` or `Before=`
12. No.
13. `systemctl cat SERVICE`
14. `systemctl --failed`
15. `journalctl -b`
16. `journalctl -b -1`
17. `systemd-analyze critical-chain`
18. Rescue provides more initialized services; emergency is a more minimal repair environment.
19. `/etc/fstab`
20. Package updates may overwrite them; use an administrator drop-in override.

---

## 37. Interview Practice Exercises

Answer each question aloud in 60–90 seconds.

### Exercise 1

> A service is enabled but shows inactive after reboot.

Include:

- Enabled vs. active
- Current boot journal
- Unit dependencies and ordering
- Environment differences
- Required network or mounts
- Configuration validation
- Recent changes

### Exercise 2

> A service is continuously restarting and generating thousands of log entries.

Include:

- Customer impact
- Stop harmful restart loop through approved process
- Inspect exit status and journal
- Check `Restart=` and rate limits
- Correct root cause
- Reset failed state
- Validate recovery

### Exercise 3

> The server enters emergency mode after storage maintenance.

Include:

- Console access
- `/etc/fstab`
- UUID and `lsblk -f`
- `findmnt --verify`
- LVM or storage availability
- Critical vs. optional mount decision
- Test and rollback

### Exercise 4

> A service works when started manually but fails under systemd.

Include:

- Service user
- Working directory
- Environment and PATH
- Absolute executable
- Permissions and SELinux
- Limits
- Shell syntax
- Mount and network dependencies

---

## 38. Engineer I vs. Engineer II Expectations

| Skill Area | Engineer I | Engineer II |
|---|---|---|
| Service management | Starts, stops, and checks units | Designs reliable unit behavior |
| Logs | Reads service journal | Correlates boot, kernel, dependency, and application logs |
| Unit changes | Applies approved overrides | Reviews dependencies, timeouts, restart, security, and rollback |
| Boot issues | Collects evidence and escalates | Leads recovery and root cause analysis |
| Performance | Runs boot-analysis commands | Interprets critical chain and parallel activation |
| Recovery mode | Understands targets | Uses console recovery safely |
| Reliability | Responds to failures | Improves restart policy, limits, monitoring, and documentation |

---

## 39. Module Completion Checklist

- [ ] I can explain the complete RHEL boot sequence.
- [ ] I can explain the purpose of initramfs.
- [ ] I can identify the running and default kernels.
- [ ] I can list common systemd unit types.
- [ ] I understand unit-file precedence.
- [ ] I can start, stop, restart, reload, enable, and disable services.
- [ ] I understand active versus enabled.
- [ ] I understand disabled versus masked.
- [ ] I can explain dependencies versus ordering.
- [ ] I can use `systemctl cat`, `show`, and `list-dependencies`.
- [ ] I can create and validate a unit.
- [ ] I can create a drop-in override.
- [ ] I understand restart policies and rate limiting.
- [ ] I can query the current and previous boot journals.
- [ ] I can analyze boot timing and the critical chain.
- [ ] I understand rescue and emergency targets.
- [ ] I can investigate an emergency-mode boot.
- [ ] I completed the user-service lab.
- [ ] I answered the interview questions aloud.

---

## 40. Command Revision Sheet

```bash
ps -p 1 -o pid,ppid,comm,args
cat /proc/cmdline
uname -r
rpm -q kernel
sudo grubby --default-kernel
sudo grubby --info=ALL
ls -lh /boot/initramfs-*
lsinitrd /boot/initramfs-$(uname -r).img
systemctl --version
systemctl list-units
systemctl list-units --all
systemctl list-unit-files
systemctl status SERVICE
systemctl start SERVICE
systemctl stop SERVICE
systemctl restart SERVICE
systemctl reload SERVICE
systemctl reload-or-restart SERVICE
systemctl enable SERVICE
systemctl enable --now SERVICE
systemctl disable SERVICE
systemctl disable --now SERVICE
systemctl is-active SERVICE
systemctl is-enabled SERVICE
systemctl mask SERVICE
systemctl unmask SERVICE
systemctl cat SERVICE
systemctl show SERVICE
systemctl list-dependencies SERVICE
systemctl list-dependencies --reverse SERVICE
systemctl daemon-reload
systemctl reset-failed SERVICE
systemctl --failed
systemctl get-default
systemctl set-default multi-user.target
systemd-analyze verify /path/to/unit.service
systemd-analyze
systemd-analyze blame
systemd-analyze critical-chain
journalctl -u SERVICE
journalctl -xeu SERVICE
journalctl -b
journalctl -b -1
journalctl -b -p err
journalctl -k
journalctl --list-boots
journalctl --disk-usage
findmnt
findmnt --verify
lsblk -f
blkid
last -x
```

---

## Next Module

**Module 07 — RPM, DNF, Repositories, and Software Management**

Topics will include:

- RPM packages and metadata
- Installing, querying, verifying, and removing packages
- DNF repositories and module streams
- Dependency resolution
- Package history and rollback considerations
- Security updates
- Kernel package management
- Repository troubleshooting
- Production patching scenarios
- Hands-on lab and interview questions

