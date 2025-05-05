# frozen_string_literal: true

# This script tests that classes outside the project don't get Ivar::Checked included
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

# Define a class outside the project (simulated by loading from a different path)
outside_file = File.expand_path("../../outside_project/outside_class.rb", __FILE__)
load outside_file

# Verify that Ivar::Checked is not included
if OutsideClass.included_modules.include?(Ivar::Checked)
  puts "FAILURE: OutsideClass includes Ivar::Checked"
  exit 1
else
  puts "SUCCESS: OutsideClass does not include Ivar::Checked"
end

# Create an instance to test for warnings
begin
  # Redirect stderr to capture warnings
  original_stderr = $stderr
  $stderr = StringIO.new

  # Create an instance and call to_s to trigger the typo
  OutsideClass.new.to_s

  # Get the captured warnings
  warnings = $stderr.string

  # Restore stderr
  $stderr = original_stderr

  # Verify that no warnings were emitted
  if warnings.empty?
    puts "SUCCESS: No warnings emitted for OutsideClass"
  else
    puts "FAILURE: Warnings emitted for OutsideClass: #{warnings}"
    exit 1
  end
rescue => e
  puts "ERROR: #{e.message}"
  exit 1
end

# Exit with success
exit 0
