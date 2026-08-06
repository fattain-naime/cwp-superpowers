# Contributing to CWP AI Agent Plugin

Thank you for your interest in contributing to the CWP AI Agent Plugin! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We are committed to providing a welcoming and inclusive experience for everyone.

## How to Contribute

### Reporting Bugs

1. Check existing [issues](https://github.com/your-org/cwp-pro-centos/issues) to avoid duplicates
2. Open a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Environment details (OS, CWP version, bash version)
   - Relevant logs or error messages

### Suggesting Features

1. Open an issue with the `enhancement` label
2. Describe the feature and its use case
3. Explain why it would be valuable

### Submitting Code

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Follow the coding standards below
5. Test your changes
6. Commit with clear messages
7. Push to your fork
8. Open a Pull Request

## Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/cwp-pro-centos.git
cd cwp-pro-centos

# Make scripts executable
chmod +x cli/cwp scripts/*.sh examples/*.sh tests/*.sh

# Run tests (local, no server needed)
bash tests/test-cli.sh

# Run integration tests (requires CWP server)
bash tests/test-integration.sh --host YOUR_SERVER
```

## Coding Standards

### Bash Scripts

- Use `#!/usr/bin/env bash` shebang
- Include `set -euo pipefail` at the top
- Use 4-space indentation (no tabs)
- Quote all variables: `"$variable"` not `$variable`
- Use `[[ ]]` for conditionals, not `[ ]`
- Use `$(command)` for command substitution, not backticks
- Add comments for complex logic
- Use `readonly` for constants
- Use functions for reusable code
- Include usage/help functions

### Naming Conventions

- Functions: `lowercase_with_underscores` (e.g., `check_services`)
- Variables: `UPPERCASE` for globals, `lowercase` for locals
- Files: `lowercase-with-hyphens.sh` for scripts
- Constants: `readonly UPPER_SNAKE_CASE`

### Error Handling

```bash
# Good
set -euo pipefail

die() {
    echo "[ERROR] $*" >&2
    exit 1
}

command || die "Command failed"

# Bad
command
echo "done"
```

### Color Output

Use the standard color variables:

```bash
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
```

### Templates

- Use `{{VARIABLE_NAME}}` for placeholders
- Include comments explaining each variable
- Include both production and development configurations
- Comment out optional sections with clear labels

## Testing

### Writing Tests

- Add tests for new features
- Follow the existing test framework pattern
- Tests should work without a server connection (skip remote tests)
- Include both positive and negative test cases

### Running Tests

```bash
# CLI tests (no server needed)
bash tests/test-cli.sh

# API tests (needs configured server)
bash tests/test-api.sh

# Integration tests
bash tests/test-integration.sh

# Run all tests
for test in tests/test-*.sh; do
    echo "=== Running $test ==="
    bash "$test" || true
done
```

## Documentation

- Update README.md for new features
- Add entries to CHANGELOG.md
- Include usage examples
- Document all options and arguments
- Keep documentation concise and practical

## Pull Request Guidelines

1. **One feature per PR** - Keep changes focused
2. **Clear description** - Explain what and why
3. **Test coverage** - Include tests for new code
4. **Documentation** - Update docs if needed
5. **No breaking changes** - Or clearly document them
6. **Clean history** - Squash commits if needed

### PR Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Local tests pass
- [ ] Integration tests pass (if applicable)

## Checklist
- [ ] Code follows project style
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
```

## Release Process

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create a release branch
4. Tag the release: `git tag v1.x.x`
5. Push tag: `git push origin v1.x.x`

## Questions?

Open an issue for any questions about contributing.
