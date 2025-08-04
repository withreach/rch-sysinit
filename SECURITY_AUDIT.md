# Security Audit: Shell Usage Replacement

## Overview
This document outlines the security improvements made to replace risky shell calls with native Ansible modules where practical, along with documentation for unavoidable shell usage.

## Changes Made

### 1. GPG Key Management
**Files affected:** `roles/sysinit/tasks/apt.yml`, `roles/sysinit/tasks/tools/docker.yml`

**Before:** Using `shell` module with `curl` and `gpg` commands to add GPG keys
```yaml
ansible.builtin.shell: >
  curl -fsSL {{ item.key_url }} | gpg --dearmor | sudo tee /etc/apt/keyrings/{{ item.name }}.gpg > /dev/null
```

**After:** Using native `apt_key` module for better security and idempotency
```yaml
ansible.builtin.apt_key:
  url: "{{ item.key_url }}"
  state: present
  keyring: "/etc/apt/keyrings/{{ item.name }}.gpg"
```

**Benefits:**
- Native module handles GPG operations securely
- Better error handling and idempotency
- Reduced command injection risk

### 2. AUR Package Installation
**File affected:** `roles/sysinit/tasks/aur.yml`

**Improvements made:**
- Added `args: creates:` to enforce idempotency
- Removed redundant condition checking (now handled by `creates`)
- Added documentation explaining necessity of shell usage

**Input validation:** Variables come from controlled list `aur_packages` in `defaults/main.yml`

### 3. Mise Plugin Management
**File affected:** `roles/sysinit/tasks/tools/mise.yml`

**Improvements made:**
- Added `args: creates:` to both plugin installation tasks
- Added documentation explaining necessity of shell usage
- Improved idempotency by checking for plugin directory existence

**Input validation:** Variables come from controlled lists `sysinit_mise_plugins` and `mise_custom_plugins` in `defaults/main.yml`

### 4. Starship Installation
**File affected:** `roles/sysinit/tasks/tools/starship.yml`

**Improvements made:**
- Added `args: creates:` to prevent reinstallation
- Added documentation explaining why shell is necessary
- Enhanced security with checksum verification

**Input validation:** Installation script is downloaded with checksum verification

## Unavoidable Shell Usage

The following tasks require shell usage due to lack of native Ansible modules:

### 1. AUR Package Management (`roles/sysinit/tasks/aur.yml`)
**Reason:** No native Ansible module exists for `yay` (AUR helper)
**Mitigation:**
- Input validation through controlled variable lists
- Idempotency enforced with `creates` argument
- Variables sourced from trusted configuration files

### 2. Mise Plugin Management (`roles/sysinit/tasks/tools/mise.yml`)
**Reason:** No native Ansible module exists for `mise` tool management
**Mitigation:**
- Input validation through controlled variable lists
- Idempotency enforced with `creates` argument
- Variables sourced from trusted configuration files

### 3. Starship Installation (`roles/sysinit/tasks/tools/starship.yml`)
**Reason:** Upstream project only provides installation script
**Mitigation:**
- Checksum verification of installation script
- Idempotency enforced with `creates` argument
- Script downloaded from official source with integrity checking

## Security Best Practices Implemented

1. **Input Validation:** All variables used in shell commands come from controlled lists in `defaults/main.yml`
2. **Idempotency:** All shell tasks now use `args: creates:` to prevent unnecessary re-execution
3. **Checksum Verification:** Downloaded scripts and binaries are verified with checksums
4. **Documentation:** All unavoidable shell usage is documented with security justification
5. **Native Modules:** Replaced shell-based GPG key management with native `apt_key` module

## Recommendations

1. **Regular Updates:** Monitor upstream projects for native package availability
2. **Variable Validation:** Consider adding variable validation tasks for critical inputs
3. **Audit Trail:** Log all package installations for security auditing
4. **Testing:** Test all changes in a controlled environment before production deployment

## Files Modified

- `roles/sysinit/tasks/apt.yml`
- `roles/sysinit/tasks/aur.yml`
- `roles/sysinit/tasks/tools/docker.yml`
- `roles/sysinit/tasks/tools/mise.yml`
- `roles/sysinit/tasks/tools/starship.yml`
- `SECURITY_AUDIT.md` (this file)
