#!/bin/sh

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Copy pre-commit hook
cp hooks/pre-commit .git/hooks/pre-commit

# Make pre-commit hook executable
chmod +x .git/hooks/pre-commit

echo "Git hooks installed successfully!"
