# Linux Systems Engineer II Interview Preparation

## Module 05 — Processes, Jobs, Signals, and Resource Usage

**Track:** Shared Linux Foundation  
**Level:** Linux Systems Engineer I and II  
**Primary platform:** Red Hat Enterprise Linux  
**Recommended study time:** 75–90 minutes

> Run the practical exercises only on a personal lab system. Never terminate, reprioritize, trace, or stress an unknown production process without identifying its owner, business function, dependencies, and impact.

---

## 1. Module Objectives

After completing this module, you should be able to:

- Explain what a Linux process is.
- Describe PID, PPID, UID, GID, process groups, and sessions.
- Explain how processes are created and terminated.
- Identify processes and parent-child relationships.
- Read important `ps` and `top` fields.
- Explain running, sleeping, blocked, stopped, and zombie states.
- Manage foreground and background shell jobs.
- Use `nohup` and `disown` appropriately.
- List and send Linux signals.
- Terminate a process using a safe escalation sequence.
- Adjust CPU scheduling priority with `nice` and `renice`.
- Inspect CPU, memory, I/O, threads, and load.
- Use `/proc` for detailed process investigation.
- Diagnose zombie, blocked, high-CPU, high-memory, and OOM conditions.
- Explain how systemd and cgroups organize service processes.

---

## 2. What Is a Process?

A **program** is executable code stored on disk.

A **process** is a running instance of a program with:

- A process ID
- Memory mappings
- Open files
- Environment variables
- Security credentials
- CPU scheduling information
- One or more threads
- A current working directory
- A parent process

Multiple processes can run the same program.

Example:

```bash
pgrep -a sshd
```

The `sshd` program may have a main server process and additional child processes for active sessions.

### Program vs. Process

| Program | Process |
|---|---|
| Stored executable code | Running instance |
| Passive file | Active execution context |
| No PID | Has a PID |
| May start many instances | Represents one running instance |

---

## 3. Process Identifiers

### 3.1 PID

PID means **Process ID**.

Display the current shell’s PID:

```bash
echo $$
```

Display process details:

```bash
ps -p $$ -o pid,ppid,user,stat,cmd
```

### 3.2 PPID

PPID means **Parent Process ID**.

Every process has a parent relationship, although adoption and re-parenting can change the reported parent.

```bash
ps -o pid,ppid,cmd -p $$
```

### 3.3 PID 1

On modern RHEL systems, PID 1 is normally `systemd`.

```bash
ps -p 1 -o pid,ppid,user,stat,cmd
```

PID 1:

- Starts and supervises system services.
- Adopts certain orphaned descendants.
- Reaps terminated child processes assigned to it.
- Manages units, cgroups, targets, mounts, sockets, and timers.

### 3.4 User and Group Identity

A process has real and effective user and group credentials.

Inspect:

```bash
ps -p PID -o pid,user,group,euser,egroup,cmd
```

- Real identity commonly represents who started the process.
- Effective identity is commonly used for permission checks.
- SUID and SGID executables can alter effective identity.

### 3.5 Threads

A process can contain multiple threads that share much of the process address space.

Display threads:

```bash
ps -L -p PID
```

With useful fields:

```bash
ps -L -p PID -o pid,tid,psr,stat,%cpu,comm
```

In Linux, each thread has a task ID. Tools may display the main process ID, thread ID, or both.

---

## 4. Process Creation and Lifecycle

A simplified lifecycle is:

```text
Parent process
      ↓
Create child
      ↓
Child executes a program
      ↓
Process runs or waits
      ↓
Process exits
      ↓
Parent collects exit status
```

Common concepts:

- `fork()` creates a child process.
- `exec()` replaces a process image with another program.
- `wait()` or a related call collects a child’s termination status.
- `exit()` terminates a process and provides an exit status.

Shell example:

```bash
bash -c 'exit 7'
echo $?
```

The shell displays:

```text
7
```

The exit status is not the same as a signal number, although shells use conventions such as `128 + signal_number` when a process ends because of a signal.

---

## 5. Listing Processes with `ps`

`ps` produces a snapshot of process information.

### 5.1 Common Formats

Unix-style:

```bash
ps -ef
```

BSD-style:

```bash
ps aux
```

Current terminal:

```bash
ps
```

Process tree:

```bash
ps -ef --forest
```

Custom fields:

```bash
ps -eo pid,ppid,user,stat,ni,pri,psr,%cpu,%mem,rss,etime,cmd
```

Sort by CPU:

```bash
ps -eo pid,ppid,user,stat,ni,%cpu,%mem,etime,cmd \
  --sort=-%cpu | head
```

Sort by memory:

```bash
ps -eo pid,ppid,user,stat,%cpu,%mem,rss,etime,cmd \
  --sort=-rss | head
```

### 5.2 Important `ps` Fields

| Field | Meaning |
|---|---|
| `PID` | Process ID |
| `PPID` | Parent process ID |
| `USER` | Process owner |
| `UID` | Numeric or named user identity |
| `STAT` | Process state and flags |
| `NI` | Nice value |
| `PRI` | Scheduler priority displayed by the tool |
| `PSR` | CPU on which the task last ran |
| `%CPU` | CPU utilization calculated by the tool |
| `%MEM` | Percentage of physical memory |
| `VSZ` | Virtual memory size |
| `RSS` | Resident physical memory |
| `ELAPSED` or `ETIME` | Time since process start |
| `TIME` | Accumulated CPU time |
| `TTY` | Controlling terminal |
| `CMD` or `COMMAND` | Command information |

### Important Interpretation Point

`ps %CPU` and `top %CPU` may use different sampling and display methods. A single snapshot is not enough to prove a sustained performance problem.

---

## 6. Finding Specific Processes

### 6.1 `pgrep`

Find PIDs:

```bash
pgrep sshd
```

Show PID and command:

```bash
pgrep -a sshd
```

Match the exact process name:

```bash
pgrep -x sshd
```

Find processes for a user:

```bash
pgrep -u USERNAME -a
```

Find children of a parent:

```bash
pgrep -P PARENT_PID -a
```

### 6.2 `pidof`

```bash
pidof sshd
```

`pidof` returns PIDs for a named program. `pgrep` offers more flexible filters.

### 6.3 `pstree`

```bash
pstree -p
```

Show a user’s process tree:

```bash
pstree -p USERNAME
```

Show ancestors of a process:

```bash
pstree -sp PID
```

### Safer Matching

Before sending a signal:

```bash
pgrep -x -a PROCESS_NAME
ps -fp PID
```

Avoid broad name matching that could affect unrelated processes.

---

## 7. Linux Process States

The main state is normally the first character in the `STAT` field.

| State | Name | Meaning |
|---|---|---|
| `R` | Running/runnable | Running on a CPU or waiting in a run queue |
| `S` | Interruptible sleep | Waiting for an event; can respond to signals |
| `D` | Uninterruptible sleep | Usually waiting inside a kernel operation, often I/O |
| `T` | Stopped/traced | Stopped by job control, a signal, or a debugger |
| `Z` | Zombie | Exited, but parent has not collected the exit status |
| `I` | Idle kernel thread | Idle kernel task on systems that display this state |
| `X` | Dead | Rarely observed transient state |

Display state:

```bash
ps -eo pid,ppid,user,stat,wchan:30,cmd
```

`WCHAN` can show the kernel function in which a sleeping task is waiting.

### Additional `STAT` Flags

| Flag | Meaning |
|---|---|
| `<` | High-priority task |
| `N` | Low-priority/niced task |
| `L` | Pages locked in memory |
| `s` | Session leader |
| `l` | Multithreaded |
| `+` | In the foreground process group |

Example:

```text
Ssl
```

This can indicate an interruptible sleeping session leader that is multithreaded.

---

## 8. Understanding `D` State

`D` commonly means **uninterruptible sleep**.

Possible causes:

- Slow or unavailable storage
- NFS server problems
- SAN path failures
- Block-device issues
- Kernel driver problems
- Filesystem operations

Even `SIGKILL` may not take effect until the task returns from the blocking kernel operation.

Investigate:

```bash
ps -eo state,pid,ppid,wchan:40,cmd | awk '$1 ~ /^D/'
vmstat 1 5
iostat -xz 1 5
dmesg -T
journalctl -k
```

Do not assume that the process itself is the root cause. The underlying storage, network filesystem, or kernel path may be responsible.

---

## 9. Interactive Monitoring with `top`

Start:

```bash
top
```

Useful keys:

| Key | Action |
|---|---|
| `P` | Sort by CPU usage |
| `M` | Sort by memory usage |
| `1` | Toggle individual CPU display |
| `H` | Toggle thread display |
| `c` | Toggle command name/full command line |
| `f` | Select fields |
| `r` | Renice a process |
| `k` | Send a signal |
| `q` | Quit |

### CPU Summary

Common fields:

| Field | Meaning |
|---|---|
| `us` | User-space CPU time |
| `sy` | Kernel/system CPU time |
| `ni` | CPU time for niced tasks |
| `id` | Idle CPU time |
| `wa` | Time waiting for I/O completion |
| `hi` | Hardware interrupt time |
| `si` | Software interrupt time |
| `st` | Steal time taken by the hypervisor |

High `st` on a virtual machine can indicate that the hypervisor is not scheduling the VM as much as requested.

High `wa` can suggest I/O delay, but it must be correlated with storage metrics and workload behavior.

---

## 10. Load Average

Display:

```bash
uptime
cat /proc/loadavg
```

The three values represent approximate averages over:

- 1 minute
- 5 minutes
- 15 minutes

Linux load average includes:

- Runnable tasks
- Tasks in certain uninterruptible states

It is not simply CPU percentage.

Compare load with:

- Number of logical CPUs
- CPU utilization
- Run queue
- I/O wait
- `D`-state tasks
- Normal system baseline
- Application latency

Display CPU count:

```bash
nproc
lscpu
```

### Trend Interpretation

Example:

```text
8.00 4.00 2.00
```

The recent 1-minute load is higher than the longer averages, suggesting the load is increasing.

Example:

```text
2.00 4.00 8.00
```

The recent load is lower, suggesting the earlier load is decreasing.

These are clues, not complete diagnoses.

---

## 11. Memory Metrics

### 11.1 System Memory

```bash
free -h
```

Important fields:

| Field | Meaning |
|---|---|
| `total` | Total memory |
| `used` | Memory currently classified as used |
| `free` | Completely unused memory |
| `buff/cache` | Buffers and filesystem cache |
| `available` | Estimated memory available without heavy swapping |
| `swap` | Disk-backed virtual memory |

Low `free` memory alone is not necessarily a problem because Linux uses RAM for caching.

Pay attention to:

- `available`
- Swap activity
- OOM events
- Application growth
- Memory-pressure trends

### 11.2 Process Memory

```bash
ps -p PID -o pid,user,%mem,vsz,rss,etime,cmd
```

| Field | Meaning |
|---|---|
| `VSZ` | Total virtual address space |
| `RSS` | Resident memory currently in physical RAM |
| `%MEM` | RSS as a percentage of physical RAM |

A large VSZ does not necessarily mean the same amount of physical RAM is being consumed.

### 11.3 Detailed Memory

```bash
cat /proc/PID/status
cat /proc/PID/smaps_rollup
```

Access may be restricted by ownership, kernel settings, or security policy.

---

## 12. `vmstat`, `pidstat`, and `sar`

### 12.1 `vmstat`

```bash
vmstat 1 5
```

The first line often represents averages since boot. Later lines represent the requested intervals.

Important columns:

| Column | Meaning |
|---|---|
| `r` | Runnable tasks |
| `b` | Tasks blocked in uninterruptible sleep |
| `si` | Swap-in rate |
| `so` | Swap-out rate |
| `bi` | Blocks received from storage |
| `bo` | Blocks sent to storage |
| `us` | User CPU |
| `sy` | System CPU |
| `id` | Idle CPU |
| `wa` | I/O wait |
| `st` | Steal time |

### 12.2 `pidstat`

```bash
pidstat 1 5
```

Specific PID:

```bash
pidstat -p PID 1 5
```

Memory:

```bash
pidstat -r -p PID 1 5
```

I/O:

```bash
pidstat -d -p PID 1 5
```

Threads:

```bash
pidstat -t -p PID 1 5
```

`pidstat` is commonly provided by the `sysstat` package.

### 12.3 `sar`

Historical CPU activity:

```bash
sar -u
```

Memory:

```bash
sar -r
```

Run queue and load:

```bash
sar -q
```

Historical data must already be collected by the sysstat service or timers.

---

## 13. Foreground and Background Jobs

Shell job control applies to jobs started from the current interactive shell.

### 13.1 Start in the Background

```bash
sleep 300 &
```

The shell may display:

```text
[1] 12345
```

- `1` is the shell job number.
- `12345` is a process ID.

### 13.2 List Shell Jobs

```bash
jobs
jobs -l
```

### 13.3 Stop the Foreground Job

Press:

```text
Ctrl+Z
```

This normally sends `SIGTSTP` to the foreground process group.

### 13.4 Continue in the Background

```bash
bg %1
```

### 13.5 Bring to the Foreground

```bash
fg %1
```

### 13.6 Terminate a Shell Job

```bash
kill -TERM %1
```

### Important Difference

- A **job number** such as `%1` is meaningful to the current shell.
- A **PID** is a system-wide process identifier.

Another terminal will not share the same shell job table.

---

## 14. `nohup`, `disown`, and Persistent Sessions

### 14.1 `nohup`

```bash
nohup long-command > long-command.log 2>&1 &
```

`nohup`:

- Configures the command to ignore `SIGHUP`.
- Redirects output when needed.
- Does not automatically place the command in the background; `&` does that.

### 14.2 `disown`

Start:

```bash
long-command &
```

Remove the job from the shell’s job table:

```bash
disown %1
```

Options and hangup behavior can vary by shell.

### 14.3 Better Options for Important Work

For important or long-running operations, consider:

- A properly configured systemd service
- A systemd transient unit
- `tmux`
- `screen`
- A batch or orchestration system

Production services should not depend on an administrator keeping an interactive terminal open.

---

## 15. Linux Signals

A signal is an asynchronous notification sent to a process or thread.

List signals:

```bash
kill -l
```

Common signals:

| Name | Common Number | Purpose |
|---|---:|---|
| `SIGHUP` | 1 | Terminal hangup; often used by applications to reload |
| `SIGINT` | 2 | Interrupt, commonly from `Ctrl+C` |
| `SIGQUIT` | 3 | Quit, commonly with diagnostic/core behavior |
| `SIGKILL` | 9 | Immediate forced termination |
| `SIGUSR1` | 10 | Application-defined |
| `SIGUSR2` | 12 | Application-defined |
| `SIGTERM` | 15 | Request graceful termination |
| `SIGCHLD` | 17 | Child changed state |
| `SIGCONT` | 18 | Continue a stopped process |
| `SIGSTOP` | 19 | Stop process unconditionally |
| `SIGTSTP` | 20 | Terminal stop, commonly from `Ctrl+Z` |

Signal numbers can vary across Unix-like platforms. Prefer signal names in scripts and documentation when possible.

### 15.1 Send a Signal

Graceful termination:

```bash
kill -TERM PID
```

Equivalent common form:

```bash
kill -15 PID
```

Reload only if the application documents `SIGHUP` for that purpose:

```bash
kill -HUP PID
```

Continue:

```bash
kill -CONT PID
```

Check whether a process exists and whether you have permission to signal it:

```bash
kill -0 PID
```

`kill -0` sends no actual signal.

---

## 16. `SIGTERM` vs. `SIGKILL`

### `SIGTERM`

```bash
kill -TERM PID
```

The process can:

- Catch the signal
- Perform cleanup
- Flush buffers
- Close files
- Remove temporary state
- Shut down gracefully

### `SIGKILL`

```bash
kill -KILL PID
```

The process cannot catch, block, or ignore `SIGKILL`.

Risks include:

- Incomplete transactions
- Unflushed data
- Stale lock files
- Partial writes
- Difficult recovery
- Loss of diagnostic evidence

### Safe Production Sequence

1. Confirm the exact process and service.
2. Determine customer and business impact.
3. Review service status, logs, parent-child relationships, and recent changes.
4. Use the application’s supported shutdown method.
5. For a systemd service, normally use:

   ```bash
   sudo systemctl stop SERVICE
   ```

6. If manually signaling is appropriate, send `SIGTERM`.
7. Wait a reasonable, application-specific period.
8. Verify whether the process exited.
9. Use `SIGKILL` only as an authorized last resort.
10. Validate service and data integrity afterward.

---

## 17. Signaling by Name

### `pkill`

Exact name:

```bash
pkill -TERM -x process_name
```

Preview first:

```bash
pgrep -a -x process_name
```

Signal a specific user’s matching process:

```bash
pkill -TERM -u USERNAME -x process_name
```

### Important Warning

Name-based matching can affect multiple processes. Always preview the match and understand whether multiple instances are expected.

For production services, prefer the service manager or application control tool over broad `pkill` use.

---

## 18. Process Priority

Linux uses scheduling policies and priorities to decide which runnable task receives CPU time.

For normal time-sharing processes, the **nice value** typically ranges from:

```text
-20 to 19
```

| Nice Value | Relative Meaning |
|---:|---|
| `-20` | Highest normal scheduling preference |
| `0` | Common default |
| `19` | Lowest normal scheduling preference |

Lower numeric nice value means greater CPU scheduling preference.

### 18.1 Start a Process with a Nice Value

```bash
nice -n 10 command
```

### 18.2 Change an Existing Process

```bash
renice 10 -p PID
```

Display:

```bash
ps -p PID -o pid,ni,pri,stat,%cpu,cmd
```

### Permission Rules

An ordinary user can normally:

- Increase the nice value of their own process.
- Give their process less CPU preference.

Reducing the nice value, which increases scheduling preference, normally requires appropriate privilege.

### Important Limitation

`nice` does not create a hard CPU limit or reservation. For enforceable service-level resource controls, use cgroups or systemd resource-control settings.

---

## 19. I/O Priority

`ionice` controls I/O scheduling class and priority where supported.

Display:

```bash
ionice -p PID
```

Start a command with idle I/O priority:

```bash
ionice -c 3 command
```

I/O-priority behavior depends on the kernel, storage stack, and I/O scheduler. Do not assume it will solve an underlying storage bottleneck.

---

## 20. Process Information in `/proc`

Every process normally has a directory:

```text
/proc/PID/
```

Useful entries:

| Path | Purpose |
|---|---|
| `/proc/PID/status` | Human-readable state, identity, memory, and capability fields |
| `/proc/PID/stat` | Machine-oriented process statistics |
| `/proc/PID/cmdline` | Command-line arguments separated by NUL bytes |
| `/proc/PID/environ` | Environment variables; may contain sensitive information |
| `/proc/PID/fd/` | Open file descriptors |
| `/proc/PID/cwd` | Current working directory link |
| `/proc/PID/exe` | Executable link |
| `/proc/PID/limits` | Resource limits |
| `/proc/PID/io` | Process I/O counters |
| `/proc/PID/smaps_rollup` | Aggregated memory-map information |
| `/proc/PID/task/` | Threads/tasks |
| `/proc/PID/cgroup` | Cgroup membership |

Examples:

```bash
cat /proc/PID/status
tr '\0' ' ' < /proc/PID/cmdline
readlink -f /proc/PID/exe
readlink -f /proc/PID/cwd
ls -l /proc/PID/fd
cat /proc/PID/limits
cat /proc/PID/cgroup
```

### Security Warning

Environment variables and command arguments can contain credentials or tokens. Avoid exposing them in tickets, chat, screenshots, or shared logs.

---

## 21. Open Files and Network Connections

List open files:

```bash
sudo lsof -p PID
```

Open network sockets:

```bash
sudo ss -tulpn
```

Sockets for a specific process may be correlated using:

```bash
sudo lsof -Pan -p PID -i
```

Deleted-but-open files:

```bash
sudo lsof +L1
```

Open file descriptors can explain:

- Why a filesystem remains busy
- Why deleted files still consume space
- Which configuration, log, socket, or library a process uses

---

## 22. Zombie Processes

A zombie process:

- Has already exited.
- Retains a small process-table entry.
- Waits for its parent to collect the exit status.
- Commonly displays state `Z`.

Find:

```bash
ps -eo pid,ppid,state,etime,cmd | awk '$3 == "Z"'
```

or:

```bash
ps -el | awk '$2 == "Z"'
```

### Can You Kill a Zombie?

No useful running execution remains to kill.

The parent must call a wait function to reap it.

Investigate:

```bash
ps -o pid,ppid,state,cmd -p ZOMBIE_PID
ps -fp PARENT_PID
pstree -sp ZOMBIE_PID
```

Possible remediation:

- Correct the parent application.
- Restart the parent through an approved procedure.
- Update or patch defective software.

One transient zombie is not normally a resource crisis. A growing number can exhaust process identifiers or indicate an application defect.

---

## 23. Orphan Processes

An orphan is a running child whose original parent has exited.

The process is normally adopted by PID 1 or another configured subreaper.

An orphan is not the same as a zombie:

| Orphan | Zombie |
|---|---|
| Still running | Already exited |
| Parent exited first | Parent has not collected status |
| Can perform work | No longer performs work |
| Adopted by a reaper | Waiting to be reaped |

Daemons historically used controlled parent-child behavior to detach from terminals. Modern services should usually be supervised by systemd.

---

## 24. Out-of-Memory Events

When the system cannot satisfy memory demands, the kernel may invoke the OOM killer and terminate a selected process.

Search:

```bash
journalctl -k | grep -Ei 'out of memory|oom|killed process'
dmesg -T | grep -Ei 'out of memory|oom|killed process'
```

Inspect process OOM scoring:

```bash
cat /proc/PID/oom_score
cat /proc/PID/oom_score_adj
```

Possible causes:

- Memory leak
- Workload growth
- Incorrect application sizing
- Insufficient memory or swap
- Too many processes
- Cgroup memory limit
- Sudden memory spike

Investigate systemd unit memory:

```bash
systemctl status SERVICE
systemctl show SERVICE -p MemoryCurrent -p MemoryMax
```

Do not merely restart repeatedly. Collect evidence, restore service safely, and address the underlying capacity, application, or limit problem.

---

## 25. systemd and Control Groups

systemd commonly places services in Linux control groups, or cgroups.

View hierarchy:

```bash
systemd-cgls
```

View resource usage:

```bash
systemd-cgtop
```

Inspect a service:

```bash
systemctl status SERVICE
systemctl show SERVICE \
  -p MainPID \
  -p ControlGroup \
  -p CPUUsageNSec \
  -p MemoryCurrent \
  -p MemoryMax \
  -p TasksCurrent \
  -p TasksMax
```

Benefits:

- Groups all service processes together.
- Supports resource accounting.
- Supports CPU, memory, and task limits.
- Allows systemd to stop the complete unit rather than only one PID.

This is one reason to manage services through systemd instead of manually killing individual child processes.

---

## 26. Resource Limits

Display shell limits:

```bash
ulimit -a
```

Display a process’s limits:

```bash
cat /proc/PID/limits
```

Common limits include:

- Maximum open files
- Maximum processes
- Stack size
- Core file size
- Locked memory

For systemd services:

```bash
systemctl show SERVICE -p LimitNOFILE -p LimitNPROC
```

An application failure such as “Too many open files” may require:

- Confirming file-descriptor usage
- Checking for a leak
- Reviewing current limits
- Adjusting an appropriate systemd or security-limits policy
- Restarting through change management when necessary

Raising a limit without investigating usage can hide an application defect.

---

## 27. Safe High-CPU Investigation

### Step 1 — Confirm Impact and Timing

Ask:

- Which application or customer is affected?
- When did the alert begin?
- Is the condition sustained or temporary?
- Did a deployment or change occur?

### Step 2 — Check System-Level Evidence

```bash
uptime
top
vmstat 1 5
mpstat -P ALL 1 5
```

### Step 3 — Identify Processes

```bash
ps -eo pid,ppid,user,stat,ni,psr,%cpu,%mem,etime,cmd \
  --sort=-%cpu | head -20
```

### Step 4 — Inspect the Process

```bash
ps -fp PID
pstree -sp PID
cat /proc/PID/status
cat /proc/PID/cgroup
sudo lsof -p PID
```

### Step 5 — Determine Whether One Thread Is Responsible

```bash
top -H -p PID
ps -L -p PID -o pid,tid,psr,stat,%cpu,comm --sort=-%cpu
```

### Step 6 — Correlate

Review:

- Application logs
- Request rate
- Scheduled jobs
- Recent deployments
- Dependency failures
- CPU steal time
- Cgroup limits
- Normal baseline

Do not terminate the process merely because it appears at the top of the list.

---

## 28. Safe High-Memory Investigation

System view:

```bash
free -h
vmstat 1 5
```

Largest RSS:

```bash
ps -eo pid,ppid,user,%mem,rss,vsz,etime,cmd \
  --sort=-rss | head -20
```

Process details:

```bash
cat /proc/PID/status
cat /proc/PID/smaps_rollup
cat /proc/PID/limits
```

Check:

- Available memory
- Swap activity, not only swap allocation
- Memory trend
- Process start time
- Cgroup memory limits
- OOM records
- Application workload and cache behavior

A large RSS can be valid for a database or cache. Compare with expected sizing and historical behavior.

---

## 29. Hands-On Lab

### Lab Safety

Use only your own processes. Do not substitute system-service PIDs in the signal exercises.

Create the lab directory:

```bash
mkdir -p ~/linux-engineer-prep/module-05
cd ~/linux-engineer-prep/module-05
```

### Task 1 — Inspect Your Shell

```bash
echo "Current shell PID: $$"
ps -p $$ -o pid,ppid,user,group,stat,ni,pri,etime,cmd
pstree -sp $$
```

Record:

- PID
- PPID
- State
- Nice value
- Parent chain

### Task 2 — Create a Background Process

```bash
sleep 300 &
lab_pid=$!
echo "Lab PID: $lab_pid"
```

Inspect:

```bash
jobs -l
ps -p "$lab_pid" -o pid,ppid,user,stat,ni,%cpu,%mem,etime,cmd
```

`$!` contains the PID of the most recent background pipeline started by the current shell.

### Task 3 — Stop and Continue the Process

Stop:

```bash
kill -STOP "$lab_pid"
```

Verify:

```bash
ps -p "$lab_pid" -o pid,ppid,stat,cmd
```

Continue:

```bash
kill -CONT "$lab_pid"
```

Verify:

```bash
ps -p "$lab_pid" -o pid,ppid,stat,cmd
```

### Task 4 — Terminate Gracefully

```bash
kill -TERM "$lab_pid"
wait "$lab_pid" 2>/dev/null || true
```

Verify:

```bash
ps -p "$lab_pid"
```

No process row is expected.

### Task 5 — Practice Interactive Job Control

Start:

```bash
sleep 300
```

Press:

```text
Ctrl+Z
```

Then:

```bash
jobs -l
bg %1
jobs -l
fg %1
```

After returning it to the foreground, press:

```text
Ctrl+C
```

This normally sends `SIGINT`.

### Task 6 — Practice `nice` and `renice`

Start:

```bash
nice -n 10 sleep 300 &
nice_pid=$!
```

Inspect:

```bash
ps -p "$nice_pid" -o pid,ni,pri,stat,cmd
```

Give it lower scheduling preference:

```bash
renice 15 -p "$nice_pid"
```

Verify and clean up:

```bash
ps -p "$nice_pid" -o pid,ni,pri,stat,cmd
kill -TERM "$nice_pid"
wait "$nice_pid" 2>/dev/null || true
```

### Task 7 — Inspect `/proc`

Create:

```bash
sleep 300 &
proc_pid=$!
```

Inspect:

```bash
cat "/proc/$proc_pid/status"
tr '\0' ' ' < "/proc/$proc_pid/cmdline"
echo
readlink -f "/proc/$proc_pid/exe"
readlink -f "/proc/$proc_pid/cwd"
cat "/proc/$proc_pid/limits"
ls -l "/proc/$proc_pid/fd"
cat "/proc/$proc_pid/cgroup"
```

Clean up:

```bash
kill -TERM "$proc_pid"
wait "$proc_pid" 2>/dev/null || true
```

### Task 8 — Controlled CPU Observation

Run a workload that automatically stops after 20 seconds:

```bash
timeout 20 yes > /dev/null &
timeout_pid=$!
```

Find the child:

```bash
pgrep -P "$timeout_pid" -a
```

Observe:

```bash
top
```

Inside `top`:

- Press `P` to sort by CPU.
- Press `1` to display individual CPUs.
- Press `q` to quit.

The workload should end automatically. Confirm:

```bash
wait "$timeout_pid" 2>/dev/null || true
pgrep -a -x yes
```

If the final command displays another `yes` process, do not assume it belongs to this lab. Verify its PID, PPID, user, and start time before taking action.

### Task 9 — Create a Process Report

```bash
ps -eo pid,ppid,user,stat,ni,pri,psr,%cpu,%mem,rss,etime,cmd \
  --sort=-%cpu > process-report.txt
```

Review:

```bash
less process-report.txt
```

### Task 10 — Check for Important Conditions

```bash
ps -eo pid,ppid,state,etime,cmd | awk '$3 == "Z"'
ps -eo state,pid,ppid,wchan:30,cmd | awk '$1 ~ /^D/'
journalctl -k | grep -Ei 'out of memory|oom|killed process'
```

No output may be normal.

### Lab Deliverables

```text
module-05/
└── process-report.txt
```

You should also be able to demonstrate:

- A background job
- A stopped process
- A continued process
- Graceful termination
- A changed nice value
- `/proc` inspection
- Controlled CPU observation

---

## 30. Production Troubleshooting Scenarios

### Scenario 1 — One Process Uses 100% CPU

Investigate:

```bash
uptime
top -H -p PID
ps -p PID -o pid,ppid,user,stat,ni,psr,%cpu,%mem,etime,cmd
ps -L -p PID -o pid,tid,psr,stat,%cpu,comm --sort=-%cpu
cat /proc/PID/cgroup
```

Ask:

- Is 100% one logical CPU or the complete system?
- Is it expected workload?
- Is the process making progress?
- Did traffic or batch work increase?
- Was a change deployed?
- Is one thread looping?
- Is the VM showing steal time?

### Scenario 2 — Process Will Not Die After `kill -9`

Check:

```bash
ps -p PID -o pid,ppid,state,wchan:40,cmd
journalctl -k
dmesg -T
```

If state is `D`, the signal may remain pending until the kernel operation returns. Investigate storage, NFS, SAN, filesystem, or driver conditions.

### Scenario 3 — Many Zombie Processes

Check:

```bash
ps -eo pid,ppid,state,etime,cmd | awk '$3 == "Z"'
ps -fp PARENT_PID
pstree -p PARENT_PID
```

Focus on the parent application. Do not repeatedly send signals to already exited zombie entries.

### Scenario 4 — Application Was Killed Unexpectedly

Check:

```bash
journalctl -k | grep -Ei 'out of memory|oom|killed process'
systemctl status SERVICE
systemctl show SERVICE -p MemoryCurrent -p MemoryMax
```

Determine whether:

- The system OOM killer acted
- A cgroup memory limit was reached
- An operator or automation sent a signal
- The application crashed
- systemd timeout or watchdog behavior acted

### Scenario 5 — High Load but CPU Is Mostly Idle

Check:

```bash
vmstat 1 5
ps -eo state,pid,ppid,wchan:40,cmd | awk '$1 ~ /^D/'
iostat -xz 1 5
```

High load with idle CPU can indicate blocked I/O rather than CPU saturation.

### Scenario 6 — Service Has Too Many Processes

Check:

```bash
systemctl status SERVICE
systemctl show SERVICE -p MainPID -p TasksCurrent -p TasksMax
systemd-cgls
pgrep -P MAIN_PID -a
```

Determine whether:

- Worker count is expected
- Processes are leaking
- A fork loop exists
- The task limit is appropriate
- Requests or scheduled jobs increased

### Scenario 7 — Long-Running Command Died After Logout

Possible causes:

- Received `SIGHUP`
- Terminal closed standard input/output
- Shell or session manager terminated the scope
- Command was not managed by a persistent service

For planned important work, use systemd, `tmux`, `screen`, or an approved orchestration mechanism instead of an unmanaged shell background job.

---

## 31. Common Interview Questions and Answers

### 1. What is the difference between a program and a process?

A program is executable code stored on disk. A process is a running instance with a PID, memory, open files, credentials, threads, and scheduling state.

### 2. What are PID and PPID?

PID identifies a process. PPID identifies its parent process.

### 3. What is normally PID 1 on RHEL?

`systemd`.

### 4. What is the difference between `ps` and `top`?

`ps` provides a snapshot. `top` provides an interactive, repeatedly refreshed view.

### 5. What does process state `R` mean?

Running on a CPU or runnable and waiting in the run queue.

### 6. What does state `D` mean?

Uninterruptible sleep, commonly while waiting inside a kernel or I/O operation.

### 7. Why might `kill -9` not immediately remove a `D`-state process?

The task cannot act on the signal until the blocking kernel operation returns.

### 8. What is a zombie process?

It is a terminated process whose parent has not collected its exit status.

### 9. Can you kill a zombie?

There is no running work left to kill. The parent must reap it, or the parent may need to be corrected or safely restarted.

### 10. What is an orphan process?

It is a running process whose original parent exited. It is adopted by PID 1 or another subreaper.

### 11. What is the difference between a job number and PID?

A job number belongs to one shell’s job table. A PID identifies a process system-wide.

### 12. What does `nohup` do?

It makes a command ignore `SIGHUP` and manages output redirection when needed. It does not background the command unless `&` is also used.

### 13. What is the difference between `SIGTERM` and `SIGKILL`?

`SIGTERM` requests graceful termination and can be handled. `SIGKILL` forces termination and cannot be caught, blocked, or ignored.

### 14. Which signal should normally be tried first?

The application’s supported shutdown method or `SIGTERM`, not `SIGKILL`.

### 15. What does `kill -0 PID` do?

It checks process existence and signaling permission without sending an actual signal.

### 16. What is a nice value?

It influences CPU scheduling preference for normal processes. Values commonly range from `-20` to `19`; a higher value means lower scheduling preference.

### 17. Can an ordinary user set a negative nice value?

Normally not. Increasing scheduling preference requires appropriate privilege.

### 18. What is the difference between VSZ and RSS?

VSZ is virtual address-space size. RSS is memory currently resident in physical RAM.

### 19. Does low free memory always mean Linux has a memory problem?

No. Linux uses memory for cache. Review available memory, swap activity, pressure, trends, and OOM events.

### 20. What does load average measure?

It reflects runnable tasks plus tasks in certain uninterruptible states over approximately 1, 5, and 15 minutes.

### 21. How do you identify the thread using CPU?

Use:

```bash
top -H -p PID
```

or:

```bash
ps -L -p PID -o pid,tid,psr,stat,%cpu,comm --sort=-%cpu
```

### 22. How do you check whether the OOM killer terminated a process?

Search kernel logs:

```bash
journalctl -k | grep -Ei 'out of memory|oom|killed process'
```

### 23. Why manage services through systemd rather than manually killing PIDs?

systemd understands the unit, dependencies, cgroup, restart policy, timeouts, and all related processes, providing safer and more consistent control.

### 24. How would you investigate a high-CPU process?

I would confirm impact and timing, examine system and per-CPU utilization, identify the process and busy threads, inspect its parent and cgroup, correlate application logs and recent changes, and avoid terminating it until I understand the workload and recovery procedure.

---

## 32. Quick Knowledge Check

### Questions

1. What does PID stand for?
2. Which variable contains the current shell’s PID?
3. Which variable contains the most recent background process PID?
4. Which process state means runnable?
5. Which state commonly means uninterruptible I/O wait?
6. Which state identifies a terminated process waiting to be reaped?
7. Which command displays a process tree?
8. Which command finds an exact process name?
9. What does `Ctrl+Z` normally do?
10. Which command continues job 1 in the background?
11. Does `nohup` automatically background a command?
12. Which signal normally requests graceful termination?
13. Which signal cannot be caught or ignored?
14. What does a nice value of `15` mean relative to `0`?
15. Which memory field represents resident physical memory?
16. What does `kill -0 PID` test?
17. Why can high load occur while CPU is mostly idle?
18. Can you directly kill a zombie process?
19. Which directory contains per-process kernel information?
20. Which command displays the systemd cgroup hierarchy?

### Answer Key

1. Process ID
2. `$$`
3. `$!`
4. `R`
5. `D`
6. `Z`
7. `pstree`
8. `pgrep -x PROCESS_NAME`
9. Sends a terminal-stop signal to the foreground process group.
10. `bg %1`
11. No. Use `&` to request background execution.
12. `SIGTERM`
13. `SIGKILL`
14. It has lower normal CPU scheduling preference.
15. RSS
16. Process existence and permission to signal it
17. Tasks may be blocked in uninterruptible I/O waits.
18. No. The parent must reap it.
19. `/proc/PID/`
20. `systemd-cgls`

---

## 33. Interview Practice Exercises

Answer each question aloud in 60–90 seconds.

### Exercise 1

> A Java process uses 100% CPU. The application owner asks you to kill it immediately. What do you do?

Include:

- Confirm scope and customer impact
- Determine whether 100% means one CPU
- Identify threads
- Review logs and recent changes
- Preserve evidence
- Use supported service control
- Attempt graceful shutdown
- Use `SIGKILL` only as an approved last resort
- Validate recovery

### Exercise 2

> Load average is 25, but CPU usage is only 10%. Explain how that is possible.

Mention:

- Load includes runnable and uninterruptible tasks
- `D`-state processes
- Storage, NFS, SAN, filesystem, or driver problems
- `vmstat`, `iostat`, `wchan`, and kernel logs

### Exercise 3

> A process remains visible after `kill -9`.

Explain the difference between:

- A `D`-state task waiting in the kernel
- A zombie waiting for its parent
- A process rapidly restarted by systemd
- A PID that has been reused

### Exercise 4

> A database uses most of the server’s memory. Is that automatically a memory leak?

Explain:

- Expected database caching
- RSS and VSZ
- Available memory
- Swap activity
- Historical trend
- OOM evidence
- Application and cgroup limits

---

## 34. Engineer I vs. Engineer II Expectations

| Skill Area | Engineer I | Engineer II |
|---|---|---|
| Process identification | Uses standard commands | Correlates process, thread, service, and cgroup |
| Signals | Uses approved stop procedure | Chooses signal and protects evidence/data |
| CPU troubleshooting | Finds high-CPU process | Analyzes threads, steal, workload, and limits |
| Memory troubleshooting | Finds high-memory process | Analyzes trend, mappings, OOM, and cgroups |
| Blocked processes | Escalates with evidence | Investigates I/O, storage, NFS, and kernel path |
| Zombies | Identifies parent | Diagnoses application reaping defect |
| Priority | Understands nice values | Applies priority and resource controls carefully |
| Communication | Reports symptoms and evidence | Leads mitigation, RCA, and prevention |

---

## 35. Module Completion Checklist

Mark each item when you can complete it without assistance:

- [ ] I can explain a program versus a process.
- [ ] I can identify PID, PPID, owner, state, and command.
- [ ] I can display a parent-child process tree.
- [ ] I can explain `R`, `S`, `D`, `T`, and `Z`.
- [ ] I can manage foreground and background shell jobs.
- [ ] I understand job numbers versus PIDs.
- [ ] I can explain `nohup` and `disown`.
- [ ] I can list and send signals.
- [ ] I understand why `SIGKILL` is a last resort.
- [ ] I can use `nice` and `renice`.
- [ ] I can interpret load-average direction.
- [ ] I can interpret basic CPU fields.
- [ ] I can explain RSS versus VSZ.
- [ ] I can inspect a process through `/proc`.
- [ ] I can explain zombies and orphans.
- [ ] I can check for OOM events.
- [ ] I can inspect systemd cgroups and service resources.
- [ ] I completed the hands-on lab.
- [ ] I answered the interview questions aloud.

---

## 36. Command Revision Sheet

```bash
echo $$
echo $!
ps
ps -ef
ps aux
ps -ef --forest
ps -p PID -o pid,ppid,user,stat,ni,pri,%cpu,%mem,etime,cmd
ps -eo pid,ppid,user,stat,ni,%cpu,%mem,etime,cmd --sort=-%cpu
ps -eo pid,ppid,user,stat,%cpu,%mem,rss,etime,cmd --sort=-rss
ps -L -p PID -o pid,tid,psr,stat,%cpu,comm
pgrep -a PROCESS_NAME
pgrep -x -a PROCESS_NAME
pgrep -P PARENT_PID -a
pidof PROCESS_NAME
pstree -p
pstree -sp PID
top
top -H -p PID
jobs -l
bg %1
fg %1
disown %1
nohup command > command.log 2>&1 &
kill -l
kill -0 PID
kill -TERM PID
kill -STOP PID
kill -CONT PID
kill -KILL PID
nice -n 10 command
renice 10 -p PID
ionice -p PID
free -h
uptime
vmstat 1 5
pidstat -p PID 1 5
mpstat -P ALL 1 5
sar -u
cat /proc/PID/status
tr '\0' ' ' < /proc/PID/cmdline
cat /proc/PID/limits
cat /proc/PID/io
cat /proc/PID/cgroup
sudo lsof -p PID
sudo lsof +L1
sudo ss -tulpn
systemd-cgls
systemd-cgtop
systemctl status SERVICE
systemctl show SERVICE -p MainPID -p MemoryCurrent -p TasksCurrent
journalctl -k
```

---

## Next Module

**Module 06 — systemd Services and Linux Boot Process**

Topics will include:

- Firmware, bootloader, kernel, initramfs, and systemd
- systemd units and dependencies
- Service states and enablement
- `systemctl` and `journalctl`
- Targets and rescue modes
- Unit files and drop-in overrides
- Service restart policies
- Boot-time troubleshooting
- Failed-service investigation
- Production scenarios and practical lab

