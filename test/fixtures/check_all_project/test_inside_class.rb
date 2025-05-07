# frozen_string_literal: true

# This script tests that classes inside the project get Ivar::Checked included
# It will be run as a subprocess

require_relative "../../../lib/ivar"

# Set up the project root
PROJECT_ROOT = File.expand_path("..", __FILE__)

# Override project_root to use our fixtures directory
Ivar.define_singleton_method(:project_root) do |*args|
  PROJECT_ROOT
end

# Enable check_all
Ivar.check_all

# Define a class inside the project
class InsideClass
  def initialize
    @name = "inside"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end

# Verify that Ivar::Checked is included
if InsideClass.included_modules.include?(Ivar::Checked)
  puts "SUCCESS: InsideClass includes Ivar::Checked"
else
  puts "FAILURE: InsideClass does not include Ivar::Checked"
  exit 1
end

# Create an instance to trigger the warning
InsideClass.new.to_s

exit 0
