# frozen_string_literal: true

# This script tests block-scoped activation of check_all
# It will be run as a subprocess

require_relative "../../../lib/ivar"

# Define a class before enabling check_all
class BeforeClass
  def initialize
    @beforeclass_name = "before"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@beforeclass_naem}"
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
  class WithinBlockClass # rubocop:disable Lint/ConstantDefinitionInBlock
    def initialize
      @withinclass_name = "within block"
    end

    def to_s
      # Intentional typo in @name
      "Name: \#{@withinclass_naem}"
    end
  end

  # Verify that Ivar::Checked is included in the class defined within the block
  if WithinBlockClass.included_modules.include?(Ivar::Checked)
    puts "SUCCESS: WithinBlockClass includes Ivar::Checked within block"
  else
    puts "FAILURE: WithinBlockClass does not include Ivar::Checked within block"
    exit 1
  end

  # Create an instance
  WithinBlockClass.new
end
class AfterClass
  def initialize
    @afterclass_name = "after"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@afterclass_naem}"
  end
end

# Verify that Ivar::Checked is not included after the block
if AfterClass.included_modules.include?(Ivar::Checked)
  puts "FAILURE: AfterClass includes Ivar::Checked after block"
  exit 1
else
  puts "SUCCESS: AfterClass does not include Ivar::Checked after block"
end

# Create instances and call to_s to trigger the typo
BeforeClass.new.to_s
AfterClass.new.to_s

exit 0
