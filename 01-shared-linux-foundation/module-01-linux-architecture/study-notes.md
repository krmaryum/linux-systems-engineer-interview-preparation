# Linux Systems Engineer II Interview Preparation

## Module 01 — Linux Architecture and System Identification

**Target role:** Linux Systems Engineer II  
**Primary platform:** Red Hat Enterprise Linux (RHEL)  
**Recommended study time:** 45–60 minutes  
**Practice environment:** RHEL, AlmaLinux, Rocky Linux, CentOS Stream, or an AWS EC2 Linux instance

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain the basic architecture of a Linux system.
- Describe the responsibilities of the Linux kernel.
- Explain the relationship between the kernel, shell, services, and hardware.
- Identify the installed Linux distribution and running kernel.
- Gather CPU, memory, storage, networking, and uptime information.
- Determine whether a server is physical or virtual.
- Identify failed services and serious boot errors.
- Perform an initial health assessment without immediately restarting the server.
- Answer common Linux system-identification interview questions.

---

## 2. Linux Architecture

A Linux system can be understood as several connected layers:

```text
Users and Applications
          ↓
Shell and System Utilities
          ↓
System Services and Libraries
          ↓
Linux Kernel
          ↓
Physical or Virtual Hardware
```

### 2.1 Hardware

Hardware includes:

- CPU
- RAM
- Local disks
- Storage controllers
- Network interfaces
- Physical or virtual devices

Linux may run directly on physical hardware, inside a virtual machine, or as an AWS EC2 instance.

### 2.2 Linux Kernel

The kernel is the core of the operating system. It communicates with hardware and manages system resources.

Important kernel responsibilities include:

- Process creation and CPU scheduling
- Memory management
- Device and driver management
- Filesystem access
- Network communication
- Security and access control
- System calls used by applications

Check the running kernel version:

```bash
uname -r
```

Display detailed kernel and architecture information:

```bash
uname -a
```

### 2.3 System Libraries

Applications use system libraries to request services from the kernel. A common Linux system library is the GNU C Library, also known as `glibc`.

Check the installed glibc version:

```bash
ldd --version
```

### 2.4 Shell

The shell interprets commands and starts programs. Bash is a commonly used shell on Red Hat systems.

Display the user’s configured login shell:

```bash
echo "$SHELL"
```

Display the shell running in the current session:

```bash
ps -p $$ -o pid,comm,args
```

These results can differ. For example, the configured login shell may be Bash while the current command is running inside another shell.

### 2.5 systemd

On modern RHEL systems, `systemd` is normally the first userspace process started by the kernel. It has process ID 1 and manages services, targets, mounts, timers, and other system units.

Check process ID 1:

```bash
ps -p 1 -o pid,comm,args
```

Check the systemd version:

```bash
systemctl --version
```

---

## 3. Distribution Version vs. Kernel Version

The Linux distribution version and kernel version are related but are not the same.

Display distribution information:

```bash
cat /etc/os-release
```

On Red Hat systems:

```bash
cat /etc/redhat-release
```

Display the running kernel:

```bash
uname -r
```

Example:

```text
Red Hat Enterprise Linux release 9.6 (Plow)
5.14.0-570.el9.x86_64
```

- `Red Hat Enterprise Linux release 9.6` is the distribution release.
- `5.14.0-570.el9.x86_64` is the running kernel version and build.
- `x86_64` identifies the 64-bit x86 architecture.

An updated kernel package may be installed on disk while the server continues running an older kernel until it is rebooted.

Check the running kernel:

```bash
uname -r
```

List installed kernel packages:

```bash
rpm -q kernel
```

This comparison is important during patching and vulnerability-management work.

---

## 4. Essential System-Identification Commands

| Purpose | Command |
|---|---|
| Distribution information | `cat /etc/os-release` |
| Red Hat release | `cat /etc/redhat-release` |
| Running kernel | `uname -r` |
| Detailed kernel information | `uname -a` |
| CPU architecture | `uname -m` |
| Host information | `hostnamectl` |
| CPU details | `lscpu` |
| Memory usage | `free -h` |
| Memory details | `cat /proc/meminfo` |
| Block devices | `lsblk` |
| Filesystem usage and types | `df -hT` |
| Mounted filesystems | `findmnt` |
| Network interfaces | `ip -br address` |
| Routing table | `ip route` |
| Listening sockets | `ss -tulpn` |
| System uptime and load | `uptime` |
| Logged-in users | `who` |
| Current user | `whoami` |
| User and group identity | `id` |
| Running processes | `ps aux` |
| Failed systemd units | `systemctl --failed` |
| High-priority boot errors | `journalctl -p err -b` |
| Virtualization type | `systemd-detect-virt` |

---

## 5. Reading Important System Information

### 5.1 Hostname

Display complete hostname information:

```bash
hostnamectl
```

Display only the hostname:

```bash
hostname
```

Display the fully qualified domain name, if configured:

```bash
hostname -f
```

### 5.2 CPU

```bash
lscpu
```

Important fields include:

- Architecture
- CPU count
- Core count
- Threads per core
- Vendor
- Model name
- Virtualization support

Display the number of processing units available to the current process:

```bash
nproc
```

### 5.3 Memory

```bash
free -h
```

Important fields:

- `total` — installed or available memory
- `used` — memory currently in use
- `free` — completely unused memory
- `buff/cache` — memory used for buffers and filesystem cache
- `available` — estimated memory available for new applications
- `swap` — disk-backed virtual memory

For a quick health assessment, the `available` value is normally more useful than the `free` value because Linux intentionally uses unused RAM for caching.

### 5.4 Storage

Display block devices:

```bash
lsblk
```

Display filesystems, usage, and filesystem types:

```bash
df -hT
```

Display mount relationships:

```bash
findmnt
```

### 5.5 Networking

Display interfaces and IP addresses in a compact format:

```bash
ip -br address
```

Display the routing table:

```bash
ip route
```

Display listening TCP and UDP sockets:

```bash
sudo ss -tulpn
```

### 5.6 Uptime and Load Average

```bash
uptime
```

Example:

```text
18:20:01 up 14 days, 3:10, 2 users, load average: 0.35, 0.42, 0.39
```

The three load-average values represent approximately:

1. The last 1 minute
2. The last 5 minutes
3. The last 15 minutes

Load average represents tasks that are running or waiting for CPU, plus certain tasks in uninterruptible sleep, often caused by disk or storage I/O.

A load average of `4.00` is not automatically a problem. It must be compared with:

- The number of logical CPUs
- CPU utilization
- I/O wait
- Application response time
- Normal workload baselines

---

## 6. Physical, Virtual, and Cloud Systems

Detect virtualization:

```bash
systemd-detect-virt
```

Possible results include:

```text
kvm
vmware
microsoft
amazon
none
```

Check hardware or virtual-machine information:

```bash
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name
```

Additional useful command:

```bash
sudo dmidecode -t system
```

On cloud instances, you may also inspect the instance metadata service. However, metadata access must follow the cloud provider’s security requirements. On AWS, prefer IMDSv2 rather than unauthenticated IMDSv1 requests.

---

## 7. Initial Linux Health Check

When connecting to a production Linux server, start with safe, read-only checks:

```bash
date
hostnamectl
uptime
free -h
df -hT
lsblk
ip -br address
ip route
systemctl --failed
journalctl -p err -b
```

Then check resource-heavy processes:

```bash
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
```

For an interactive view:

```bash
top
```

Do not restart a production server or service before:

- Confirming the business impact
- Collecting evidence
- Checking monitoring and logs
- Reviewing recent changes
- Following the organization’s incident and change-management procedures

---

## 8. Hands-On Lab — Create a System Information Report

### Lab Objective

Create a reusable Bash script that collects basic system-identification and health information.

### Step 1 — Create the Lab Directory

```bash
mkdir -p ~/linux-engineer-prep/module-01
cd ~/linux-engineer-prep/module-01
```

### Step 2 — Create the Script

```bash
vim system_report.sh
```

Add the following content:

```bash
#!/usr/bin/env bash

# Linux Systems Engineer II - Module 01
# Purpose: Collect system identification and basic health information.

report_file="system-report-$(hostname -s)-$(date +%F-%H%M%S).txt"

{
    echo "LINUX SYSTEM IDENTIFICATION REPORT"
    echo "=================================="
    echo "Generated: $(date)"
    echo

    echo "1. HOST INFORMATION"
    hostnamectl
    echo

    echo "2. OPERATING SYSTEM"
    cat /etc/os-release
    echo

    echo "3. RUNNING KERNEL"
    uname -a
    echo

    echo "4. CPU INFORMATION"
    lscpu
    echo

    echo "5. MEMORY USAGE"
    free -h
    echo

    echo "6. BLOCK DEVICES"
    lsblk
    echo

    echo "7. FILESYSTEM USAGE"
    df -hT
    echo

    echo "8. NETWORK INTERFACES"
    ip -br address
    echo

    echo "9. ROUTING TABLE"
    ip route
    echo

    echo "10. UPTIME AND LOAD"
    uptime
    echo

    echo "11. FAILED SYSTEMD UNITS"
    systemctl --failed --no-pager
    echo

    echo "12. HIGH-PRIORITY BOOT ERRORS"
    journalctl -p err -b --no-pager
} > "$report_file" 2>&1

printf 'Report created: %s\n' "$report_file"
```

### Step 3 — Validate the Script

```bash
bash -n system_report.sh
```

No output normally means that Bash did not detect a syntax error.

### Step 4 — Make It Executable

```bash
chmod u+x system_report.sh
```

### Step 5 — Run It

```bash
./system_report.sh
```

Some commands may return limited information when the script is executed without elevated privileges. Do not run the entire script with `sudo` unless your environment and policy require it.

### Step 6 — Review the Report

```bash
ls -lh system-report-*.txt
less system-report-*.txt
```

### Step 7 — Check the Exit Status

Immediately after running a command:

```bash
echo $?
```

- `0` normally means success.
- A non-zero value normally means an error or special condition.

### Lab Deliverables

Your directory should contain:

```text
module-01/
├── system_report.sh
└── system-report-HOSTNAME-DATE-TIME.txt
```

---

## 9. Tier III Troubleshooting Scenario

### Scenario

A customer reports:

> The Linux server is very slow, and the application is taking too long to respond.

### Step 1 — Confirm the Impact

Ask:

- When did the problem begin?
- Is the entire server slow or only one application?
- Is the problem continuous or intermittent?
- How many users or services are affected?
- Did monitoring generate an alert?
- Were any recent patches, deployments, or configuration changes made?

### Step 2 — Collect Initial Evidence

```bash
date
uptime
free -h
df -hT
top
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
systemctl --failed
journalctl -p err -b
```

Depending on the symptoms, continue with:

```bash
vmstat 1 5
iostat -xz 1 5
ss -s
```

The `iostat` command is commonly provided by the `sysstat` package.

### Step 3 — Correlate the Evidence

Investigate whether the problem is related to:

- CPU saturation
- Memory pressure or swapping
- Disk capacity
- Disk latency or high I/O wait
- Failed or restarting services
- Network connectivity
- Application errors
- A recent change
- Storage or virtualization problems

### Step 4 — Mitigate Safely

Follow the incident and change process. If a restart is required, record:

- Why it is needed
- What evidence supports it
- Expected customer impact
- Required approval
- Validation and rollback steps

### Step 5 — Document the Root Cause

A useful root cause analysis should include:

- Incident summary
- Timeline
- Business and technical impact
- Evidence collected
- Root cause
- Immediate mitigation
- Permanent corrective action
- Prevention and monitoring improvements
- Owner and target completion date

### Strong Interview Response

> I would first confirm the impact, affected scope, and timeline. I would review monitoring, recent changes, system load, memory, disk, network, service status, and logs. I would preserve evidence before making changes. If mitigation required a restart or configuration change, I would follow the change process, validate service recovery, communicate the result, and document the root cause and preventive actions.

---

## 10. Common Interview Questions and Answers

### 1. What is the Linux kernel?

The kernel is the core of the operating system. It manages CPU scheduling, memory, processes, devices, filesystems, networking, and security while providing system-call interfaces to applications.

### 2. How do you identify the installed Red Hat version?

```bash
cat /etc/redhat-release
cat /etc/os-release
```

### 3. How do you identify the running kernel?

```bash
uname -r
```

### 4. Why can the installed kernel differ from the running kernel?

A newer kernel package may have been installed during patching, but the system continues using the old kernel until the server is rebooted into the new one.

### 5. What is PID 1 on a modern RHEL system?

It is normally `systemd`, the first userspace process. It manages services and other system units.

### 6. How do you check whether a server is physical or virtual?

```bash
systemd-detect-virt
sudo dmidecode -s system-manufacturer
sudo dmidecode -s system-product-name
```

### 7. What does load average represent?

It represents the average number of tasks running or waiting for CPU, plus certain tasks waiting in uninterruptible sleep, typically for I/O. The values cover approximately 1, 5, and 15 minutes.

### 8. Why is low `free` memory not always a problem?

Linux uses otherwise unused memory for buffers and filesystem cache. The `available` value from `free -h` gives a more practical estimate of memory that can be used by applications without heavy swapping.

### 9. What is the difference between `df` and `du`?

- `df` reports filesystem-level capacity and usage.
- `du` calculates space used by visible files and directories.

Their results can differ because of deleted-but-open files, mount points, reserved blocks, or filesystem metadata.

### 10. What would you check first if a server were reported as slow?

I would confirm the impact and timeline, review monitoring and recent changes, and collect evidence about load, CPU, memory, swap, disk capacity, disk latency, network status, services, and logs before making changes.

### 11. Why should you not immediately reboot a production server?

A reboot can hide the root cause, destroy useful evidence, interrupt customers, and violate change procedures. It should be an evidence-based, approved mitigation with validation and rollback planning.

### 12. How do you identify failed services?

```bash
systemctl --failed
```

For a specific service:

```bash
systemctl status service_name
journalctl -u service_name
```

---

## 11. Quick Knowledge Check

### Questions

1. Which command displays the running kernel version?
2. Which file provides standard Linux distribution information?
3. Which process normally has PID 1 on RHEL 8 and RHEL 9?
4. Which command displays memory values in a human-readable format?
5. Which command lists failed systemd units?
6. Which command provides a compact view of interfaces and IP addresses?
7. Does a load average of `4.00` always indicate a performance problem?
8. Which command helps determine whether Linux is running in a virtual machine?
9. Why might an installed kernel not be the currently running kernel?
10. What should you do before restarting a slow production server?

### Answer Key

1. `uname -r`
2. `/etc/os-release`
3. `systemd`
4. `free -h`
5. `systemctl --failed`
6. `ip -br address`
7. No. Compare it with CPU count, I/O state, application performance, and the normal baseline.
8. `systemd-detect-virt`
9. The newer kernel was installed, but the server has not yet rebooted into it.
10. Confirm the impact, collect evidence, check monitoring and recent changes, and follow incident and change-management procedures.

---

## 12. Interview Practice Exercise

Answer the following aloud in 60–90 seconds:

> You receive an alert that a production RHEL server has a high load average. Explain how you would investigate it.

Your answer should cover:

- Alert validation
- Customer and business impact
- CPU count and load trend
- CPU utilization and I/O wait
- Memory and swap
- Disk capacity and latency
- Resource-heavy processes
- Service status and logs
- Recent changes
- Safe mitigation
- Communication, validation, and documentation

---

## 13. Module Completion Checklist

Mark each item when you can perform it without assistance:

- [ ] I can explain the main layers of Linux architecture.
- [ ] I can explain the responsibilities of the kernel.
- [ ] I can identify the RHEL release.
- [ ] I can identify the running and installed kernels.
- [ ] I can gather CPU, memory, storage, and network information.
- [ ] I can explain the 1-, 5-, and 15-minute load averages.
- [ ] I can determine whether a server is physical or virtual.
- [ ] I can identify failed services and serious boot errors.
- [ ] I can create and run the system-report script.
- [ ] I can explain my first response to a slow production server.
- [ ] I understand why a restart should not be the first troubleshooting action.
- [ ] I can answer the Module 01 interview questions aloud.

---

## 14. Command Revision Sheet

```bash
cat /etc/os-release
cat /etc/redhat-release
uname -r
uname -a
uname -m
hostnamectl
lscpu
nproc
free -h
lsblk
df -hT
findmnt
ip -br address
ip route
sudo ss -tulpn
uptime
who
whoami
id
ps -p 1 -o pid,comm,args
systemctl --failed
journalctl -p err -b
systemd-detect-virt
sudo dmidecode -t system
```

---

## Next Module

**Module 02 — Linux Filesystem Hierarchy and File Management**

Topics will include:

- Important directories under `/`
- Absolute and relative paths
- File types and inode concepts
- Links
- Finding files
- Copying, moving, and deleting safely
- Disk usage investigation
- Deleted-but-open files
- Production troubleshooting scenarios

