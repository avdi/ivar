# frozen_string_literal: true

# This file contains classes that will be loaded within a block

# Class defined before the block
class BeforeBlockClass
  def initialize
    @name = "before block"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end

# Class that will be referenced within the block
class WithinBlockClass
  def initialize
    @name = "within block"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end

# Function to reference the class within a block
def reference_within_block
  # Reference the class to trigger TracePoint
  WithinBlockClass
end

# Class defined after the block
class AfterBlockClass
  def initialize
    @name = "after block"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end
