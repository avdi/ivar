# frozen_string_literal: true

# This file contains classes for testing block-scoped activation

# This class will be defined outside the block
class OutsideBlockClass
  def initialize
    @name = "outside block"
  end

  def to_s
    # Intentional typo in @name
    "Name: #{@naem}"
  end
end

# This function will define a class inside the block
def define_class_in_block
  # Define the class using the class keyword to trigger the TracePoint
  eval <<~RUBY, binding, __FILE__, __LINE__ + 1
    # This class will be defined inside the block
    class InsideBlockClass
      def initialize
        @name = "inside block"
      end

      def to_s
        # Intentional typo in @name
        "Name: \#{@naem}"
      end
    end
  RUBY
end
