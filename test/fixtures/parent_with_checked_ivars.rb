# frozen_string_literal: true

require "ivar"

class ParentWithCheckedIvars
  include Ivar::CheckedIvars

  def initialize
    @parent_var1 = "parent1"
    @parent_var2 = "parent2"
  end

  def parent_method
    "Using #{@parent_var1} and #{@parent_var2}"
  end
end
