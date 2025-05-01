#!/bin/bash
set -e

echo "Running post-create setup script..."

# Install Ruby dependencies
echo "Installing Ruby dependencies with bundle install..."
bundle install

echo "Post-create setup completed successfully!"
