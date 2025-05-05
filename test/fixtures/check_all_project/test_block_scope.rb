# frozen_string_literal: true

# This script tests block-scoped activation of check_all
# It will be run as a subprocess

require_relative "../../../lib/ivar"
require "stringio"

# Set up the project root
PROJECT_ROOT = File.expand_path("..", __FILE__)

# Override project_root to use our fixtures directory
Ivar.define_singleton_method(:project_root) do |*args|
  PROJECT_ROOT
end

# Define a class before enabling check_all
class BeforeClass
  def initialize
    @name = "before"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end

# Verify that Ivar::Checked is not included before the block
if BeforeClass.included_modules.include?(Ivar::Checked)
  puts "FAILURE: BeforeClass includes Ivar::Checked before block"
  exit 1
else
  puts "SUCCESS: BeforeClass does not include Ivar::Checked before block"
end

# Use check_all with a block
Ivar.check_all do
  # Define a class within the block using a string and load
  class_def = <<~RUBY
    # This class is defined within the block
    class WithinBlockClass
      def initialize
        @name = "within block"
      end

      def to_s
        # Intentional typo in @name
        "Name: \#{@naem}"
      end
    end
  RUBY

  # Load the class definition
  Object.class_eval(class_def, __FILE__, __LINE__)

  # Verify that Ivar::Checked is included in the class defined within the block
  if WithinBlockClass.included_modules.include?(Ivar::Checked)
    puts "SUCCESS: WithinBlockClass includes Ivar::Checked within block"
  else
    puts "FAILURE: WithinBlockClass does not include Ivar::Checked within block"
    exit 1
  end

  # Create an instance to test for warnings
  begin
    # Redirect stderr to capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Create an instance
    WithinBlockClass.new

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Verify that warnings were emitted
    if warnings.include?("unknown instance variable @naem")
      puts "SUCCESS: Warning emitted for unknown instance variable @naem in WithinBlockClass"
    else
      puts "FAILURE: No warning emitted for unknown instance variable @naem in WithinBlockClass"
      exit 1
    end
  rescue => e
    puts "ERROR: #{e.message}"
    exit 1
  end
end

# Define a class after the block
class AfterClass
  def initialize
    @name = "after"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end

# Verify that Ivar::Checked is not included after the block
if AfterClass.included_modules.include?(Ivar::Checked)
  puts "FAILURE: AfterClass includes Ivar::Checked after block"
  exit 1
else
  puts "SUCCESS: AfterClass does not include Ivar::Checked after block"
end

# Create instances to test for warnings
begin
  # Redirect stderr to capture warnings
  original_stderr = $stderr
  $stderr = StringIO.new

  # Create instances and call to_s to trigger the typo
  BeforeClass.new.to_s
  AfterClass.new.to_s

  # Get the captured warnings
  warnings = $stderr.string

  # Restore stderr
  $stderr = original_stderr

  # Verify that no warnings were emitted
  if warnings.empty?
    puts "SUCCESS: No warnings emitted for BeforeClass and AfterClass"
  else
    puts "FAILURE: Warnings emitted for BeforeClass or AfterClass: #{warnings}"
    exit 1
  end
rescue => e
  puts "ERROR: #{e.message}"
  exit 1
end

# Exit with success
exit 0
