# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class TestIvarInheritance < Minitest::Test
  def test_ivar_tools_inheritance_warns_about_unknown_ivars
    # Capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Load the fixture files
    require_relative "fixtures/parent_with_ivar_tools"
    require_relative "fixtures/child_with_ivar_tools"

    # Create an instance of the child class
    child = ChildWithIvarTools.new

    # Call the method with the misspelled instance variable
    child.child_method

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that the warning contains the expected text
    assert_match(/unknown instance variable @chyld_var3/, warnings)

    # The parent's instance variables should be known to the child
    refute_match(/unknown instance variable @parent_var1/, warnings)
    refute_match(/unknown instance variable @parent_var2/, warnings)
  end

  def test_checked_ivars_inheritance_warns_about_unknown_ivars
    # Capture warnings
    original_stderr = $stderr
    $stderr = StringIO.new

    # Load the fixture files
    require_relative "fixtures/parent_with_checked_ivars"
    require_relative "fixtures/child_with_checked_ivars"

    # Create an instance of the child class
    child = ChildWithCheckedIvars.new

    # Call the method with the misspelled instance variable
    child.child_method

    # Get the captured warnings
    warnings = $stderr.string

    # Restore stderr
    $stderr = original_stderr

    # Check that the warning contains the expected text
    assert_match(/unknown instance variable @chyld_var3/, warnings)

    # The parent's instance variables should be known to the child
    refute_match(/unknown instance variable @parent_var1/, warnings)
    refute_match(/unknown instance variable @parent_var2/, warnings)
  end
end
