# frozen_string_literal: true

# This script tests that classes inside the project get Ivar::Checked included
# It will be run as a subprocess

require_relative "../../../lib/ivar"
require "stringio"

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

# Create an instance to test for warnings
begin
  # Redirect stderr to capture warnings
  original_stderr = $stderr
  $stderr = StringIO.new

  # Create an instance
  InsideClass.new

  # Get the captured warnings
  warnings = $stderr.string

  # Restore stderr
  $stderr = original_stderr

  # Verify that warnings were emitted
  if warnings.include?("unknown instance variable @naem")
    puts "SUCCESS: Warning emitted for unknown instance variable @naem"
  else
    puts "FAILURE: No warning emitted for unknown instance variable @naem"
    exit 1
  end
rescue => e
  puts "ERROR: #{e.message}"
  exit 1
end

# Exit with success
exit 0
