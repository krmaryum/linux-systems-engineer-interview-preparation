#!/usr/bin/env bash

# Linux Systems Engineer I & II Interview Preparation
# Repository Structure Generator
#
# Usage:
#   bash create-linux-systems-engineer-repo.sh
#   bash create-linux-systems-engineer-repo.sh /path/to/repository
#
# The default repository directory is:
#   ./linux-systems-engineer-interview-preparation
#
# Existing files are preserved. Every otherwise-empty leaf directory receives
# a .gitkeep file so Git and GitHub can track the complete folder structure.

set -euo pipefail

default_repo="linux-systems-engineer-interview-preparation"

show_help() {
    printf '%s\n' \
        "Usage:" \
        "  bash $(basename "$0") [REPOSITORY_PATH]" \
        "" \
        "Examples:" \
        "  bash $(basename "$0")" \
        "  bash $(basename "$0") ~/projects/linux-systems-engineer-interview-preparation" \
        "" \
        "If REPOSITORY_PATH is omitted, the script creates:" \
        "  ./${default_repo}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

if (( $# > 1 )); then
    printf 'Error: Accepts zero or one argument.\n\n' >&2
    show_help >&2
    exit 2
fi

repo_dir="${1:-$default_repo}"

if [[ -z "$repo_dir" || "$repo_dir" == "/" ]]; then
    printf 'Error: Refusing unsafe repository path: %q\n' "$repo_dir" >&2
    exit 2
fi

if [[ -e "$repo_dir" && ! -d "$repo_dir" ]]; then
    printf 'Error: The target exists but is not a directory: %s\n' "$repo_dir" >&2
    exit 2
fi

create_directory() {
    local relative_path="$1"
    mkdir -p -- "$repo_dir/$relative_path"
}

add_gitkeep() {
    local relative_path="$1"
    touch -- "$repo_dir/$relative_path/.gitkeep"
}

create_readme_if_missing() {
    local readme_path="$repo_dir/README.md"

    if [[ ! -e "$readme_path" ]]; then
        {
            printf '# Linux Systems Engineer I & II Interview Preparation\n\n'
            printf 'Learn it. Practice it. Troubleshoot it. Explain it.\n\n'
            printf 'A structured, hands-on learning repository for Linux Systems Engineer I and Linux Systems Engineer II roles. The project focuses on Red Hat Enterprise Linux administration, production troubleshooting, Bash automation, AWS, security, monitoring, change management, root cause analysis, and technical interview preparation.\n\n'
            printf '## Learning Layers\n\n'
            printf '1. Shared Linux Foundation — Modules 01–10\n'
            printf '2. Linux Systems Engineer I — Modules 11–22\n'
            printf '3. Linux Systems Engineer II — Modules 23–36\n'
            printf '4. Job Readiness — Modules 37–40\n'
        } > "$readme_path"
    fi
}

create_gitignore_if_missing() {
    local gitignore_path="$repo_dir/.gitignore"

    if [[ ! -e "$gitignore_path" ]]; then
        {
            printf '# Operating-system files\n'
            printf '.DS_Store\n'
            printf 'Thumbs.db\n\n'
            printf '# Editor files\n'
            printf '*.swp\n'
            printf '*.swo\n'
            printf '*~\n'
            printf '.vscode/\n'
            printf '.idea/\n\n'
            printf '# Logs and temporary output\n'
            printf '*.log\n'
            printf '*.tmp\n'
            printf 'tmp/\n\n'
            printf '# Secrets and environment files\n'
            printf '.env\n'
            printf '.env.*\n'
            printf '*.pem\n'
            printf '*.key\n'
            printf '!examples/**/*.key\n'
        } > "$gitignore_path"
    fi
}

shared_modules=(
    "module-01-linux-architecture"
    "module-02-filesystem-hierarchy"
    "module-03-users-groups-sudo"
    "module-04-permissions-acls-special-bits"
    "module-05-processes-jobs-signals"
    "module-06-systemd-and-boot"
    "module-07-rpm-dnf-repositories"
    "module-08-filesystems-mounts-swap"
    "module-09-lvm"
    "module-10-networking-and-ssh"
)

engineer_i_modules=(
    "module-11-logging"
    "module-12-cron-timers-logrotate"
    "module-13-dns-time-connectivity"
    "module-14-firewalld-selinux"
    "module-15-backup-and-recovery"
    "module-16-nfs-and-smb"
    "module-17-web-services"
    "module-18-virtualization-fundamentals"
    "module-19-monitoring-alerts"
    "module-20-bash-automation"
    "module-21-patching-change-management"
    "module-22-engineer-i-capstone"
)

engineer_ii_modules=(
    "module-23-performance-analysis"
    "module-24-storage-san-nas"
    "module-25-advanced-networking"
    "module-26-enterprise-identity"
    "module-27-hardening-encryption"
    "module-28-vulnerability-lifecycle"
    "module-29-high-availability"
    "module-30-aws-ec2-ebs-s3"
    "module-31-aws-vpc-iam-rds"
    "module-32-cloudwatch-observability"
    "module-33-ansible"
    "module-34-infrastructure-awareness"
    "module-35-tier-iii-rca"
    "module-36-leadership-on-call"
)

job_readiness_modules=(
    "module-37-engineer-i-assessment"
    "module-38-engineer-ii-assessment"
    "module-39-capstone-project"
    "module-40-final-mock-interview"
)

supporting_leaf_directories=(
    "00-master-roadmap"
    "hands-on-labs/engineer-i"
    "hands-on-labs/engineer-ii"
    "troubleshooting-scenarios/user-access"
    "troubleshooting-scenarios/system-performance"
    "troubleshooting-scenarios/storage"
    "troubleshooting-scenarios/networking"
    "troubleshooting-scenarios/services"
    "troubleshooting-scenarios/security"
    "troubleshooting-scenarios/aws"
    "bash-scripts/system-health"
    "bash-scripts/user-management"
    "bash-scripts/storage"
    "bash-scripts/monitoring"
    "bash-scripts/backup"
    "bash-scripts/patching"
    "assessments/mcq-quizzes"
    "assessments/practical-tests"
    "assessments/answer-keys"
    "assessments/scoring-rubrics"
    "mock-interviews/engineer-i"
    "mock-interviews/engineer-ii"
    "mock-interviews/behavioral"
    "mock-interviews/scenario-based"
    "cheat-sheets"
    "posters"
    "assets"
)

mkdir -p -- "$repo_dir"

create_readme_if_missing
create_gitignore_if_missing

for module in "${shared_modules[@]}"; do
    create_directory "01-shared-linux-foundation/$module"
    add_gitkeep "01-shared-linux-foundation/$module"
done

for module in "${engineer_i_modules[@]}"; do
    create_directory "02-systems-engineer-i/$module"
    add_gitkeep "02-systems-engineer-i/$module"
done

for module in "${engineer_ii_modules[@]}"; do
    create_directory "03-systems-engineer-ii/$module"
    add_gitkeep "03-systems-engineer-ii/$module"
done

for module in "${job_readiness_modules[@]}"; do
    create_directory "04-job-readiness/$module"
    add_gitkeep "04-job-readiness/$module"
done

for directory in "${supporting_leaf_directories[@]}"; do
    create_directory "$directory"
    add_gitkeep "$directory"
done

directory_count="$(
    find "$repo_dir" -type d -print | wc -l
)"

gitkeep_count="$(
    find "$repo_dir" -type f -name '.gitkeep' -print | wc -l
)"

printf '\nRepository structure created successfully.\n'
printf 'Location: %s\n' "$repo_dir"
printf 'Directories: %s\n' "${directory_count//[[:space:]]/}"
printf '.gitkeep files: %s\n' "${gitkeep_count//[[:space:]]/}"
printf '\nNext steps:\n'
printf '  cd %q\n' "$repo_dir"
printf '  git init\n'
printf '  git add .\n'
printf '  git commit -m "Create Linux Systems Engineer learning structure"\n'
printf '\nThe script is safe to run again; existing files are preserved.\n'
