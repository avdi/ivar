# frozen_string_literal: true

# This script tests that classes outside the project don't get Ivar::Checked included
# It will be run as a subprocess

require_relative "../../../lib/ivar"

Ivar.project_root = __dir__
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

# Create an instance and call to_s to trigger the potential typo warning
OutsideClass.new.to_s

exit 0
