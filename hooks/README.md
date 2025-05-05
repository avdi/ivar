# Git Hooks

This directory contains Git hooks for the ivar project.

## Available Hooks

- **pre-commit**: Automatically checks and fixes linting issues before committing.

## Installation

To install the hooks, run:

```bash
./hooks/install.sh
```

This will copy the hooks to your local `.git/hooks` directory and make them executable.

## Automatic Installation

The hooks are automatically installed when you open the project in a devcontainer.

## Manual Installation

If you prefer to install the hooks manually, you can copy them to your `.git/hooks` directory:

```bash
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## How the Pre-commit Hook Works

The pre-commit hook:

1. Identifies staged Ruby files
2. Checks them for linting issues using standardrb
3. If issues are found, attempts to automatically fix them
4. Adds the fixed files back to the staging area
5. Performs a final check to ensure all issues are fixed

If any issues cannot be automatically fixed, the commit will be aborted with an error message.
