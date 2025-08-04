# Linux System Initialization

An opinionated script to initialize your Linux system for use with Reach Ltd.

## Distros

This release has been tested on the following distributions, and should work on all distros based from:

- Arch
- Debian
- Fedora
- Redhat
- Ubuntu

## Quick Start

### Recommended Installation (Two-Step Process)

For security best practices, we recommend downloading and reviewing the installation script before execution:

1. **Download the installation script:**
   ```bash
   # Download from the latest release (recommended)
   wget https://github.com/withreach/rch-sysinit/releases/latest/download/install.sh

   # Or download from the main branch
   wget https://raw.githubusercontent.com/withreach/rch-sysinit/main/install.sh
   ```

2. **Review and execute the script:**
   ```bash
   # Review the script contents
   less install.sh

   # Make executable and run
   chmod +x install.sh
   ./install.sh
   ```

### Security Verification (Optional)

For enhanced security, you can verify the integrity of the installation script:

#### Checksum Verification
```bash
# Download the checksum file (when available)
wget https://github.com/withreach/rch-sysinit/releases/latest/download/install.sh.sha256

# Verify the checksum
sha256sum -c install.sh.sha256
```

#### GPG Signature Verification
```bash
# Download the GPG signature (when available)
wget https://github.com/withreach/rch-sysinit/releases/latest/download/install.sh.sig

# Import the signing key (replace with actual key ID)
# gpg --keyserver keyserver.ubuntu.com --recv-keys <KEY_ID>

# Verify the signature
# gpg --verify install.sh.sig install.sh
```

### Alternative: Clone Repository

You can also clone the entire repository to review all files:

```bash
git clone https://github.com/withreach/rch-sysinit.git
cd rch-sysinit
./install.sh
```

### ⚠️ Security Warning

**We strongly discourage piping scripts directly to bash** (e.g., `curl | bash` or `wget | bash`) as this prevents you from reviewing the code before execution. Always download, review, and then execute installation scripts.

## Configuration

### GitHub Token

The playbook supports optional GitHub token configuration for accessing private repositories or increasing API rate limits. The token can be supplied in several ways:

#### Using Ansible Vault (Recommended)

1. Create an encrypted vault file:
   ```bash
   ansible-vault create vault.yml
   ```

2. Add your GitHub token to the vault file:
   ```yaml
   vault_github_token: "your_github_token_here"
   ```

3. Run the playbook with the vault file:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbook.yml --ask-vault-pass -e @vault.yml
   ```

#### Using Environment Variables

You can also set the token via environment variables:

```bash
export vault_github_token="your_github_token_here"
ansible-playbook -i inventory/hosts.yml playbook.yml
```

#### Using Extra Variables

Alternatively, pass the token directly as an extra variable:

```bash
ansible-playbook -i inventory/hosts.yml playbook.yml -e vault_github_token="your_github_token_here"
```

**Note:** If no token is provided, the playbook will continue with an empty token value, which may result in GitHub API rate limiting for some operations.

## Development

For contributors and developers working on this project, please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed setup instructions, including:

- Setting up pre-commit hooks for code quality and security
- Development workflow and best practices
- Running tests and linting locally

This project uses pre-commit hooks to ensure code quality, security scanning, and consistent formatting. All contributions are automatically checked for:

- **Secret detection** - Prevents accidental commit of sensitive information
- **Ansible linting** - Ensures playbooks follow best practices
- **Shell script validation** - Checks scripts for common issues
- **YAML formatting** - Maintains consistent file formatting
- **Molecule testing** - Comprehensive role testing including idempotency and checksum validation

### Testing

The project includes comprehensive testing with Molecule, providing:

- **Functional testing** - Validates role behavior on multiple OS versions
- **Idempotency testing** - Ensures roles can be run multiple times safely
- **Checksum enforcement** - Validates security through checksum verification
- **CI/CD integration** - Automated testing on every push and pull request

#### Running Tests Locally

```bash
# Install all development dependencies (includes Molecule)
make install-deps

# Run all test scenarios
make molecule-test-all

# Run individual test scenarios
make molecule-test              # Default functional tests
cd roles/sysinit && molecule test -s checksum-enforcement  # Security tests
cd roles/sysinit && molecule test -s idempotency          # Idempotency tests

# Development workflow
make molecule-converge   # Create test instances
make molecule-verify     # Run verification tests
make molecule-destroy    # Clean up test instances
```

To get started with development:

```bash
# Install development dependencies
make install-deps

# Set up development environment
make setup-dev
```
