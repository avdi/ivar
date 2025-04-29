# frozen_string_literal: true

require_relative "parent_with_ivar_tools"

class ChildWithIvarTools < ParentWithIvarTools
  def initialize
    super
    @child_var1 = "child1"
    @child_var2 = "child2"
    check_ivars
  end

  def child_method
    "Using #{@child_var1} and #{@child_var2} and #{@chyld_var3}"
  end
end
