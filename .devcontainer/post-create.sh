#!/bin/bash
set -e

echo "Running post-create setup script..."

# Install Ruby dependencies
echo "Installing Ruby dependencies with bundle install..."
bundle install

# Install Git hooks
echo "Installing Git hooks..."
if [ -f "hooks/install.sh" ]; then
  ./hooks/install.sh
else
  echo "Hooks installation script not found. Skipping."
fi

echo "Post-create setup completed successfully!"
