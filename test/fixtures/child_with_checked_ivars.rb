# frozen_string_literal: true

require_relative "parent_with_checked_ivars"

class ChildWithCheckedIvars < ParentWithCheckedIvars
  def initialize
    super
    @child_var1 = "child1"
    @child_var2 = "child2"
  end

  def child_method
    "Using #{@child_var1} and #{@child_var2} and #{@chyld_var3}"
  end
end
