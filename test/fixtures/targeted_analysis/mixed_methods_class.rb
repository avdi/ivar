# frozen_string_literal: true

# This class has both instance and class methods
class MixedMethodsClass
  # Class variable
  @@class_var = "class variable"

  # Class instance variable (different from class variable)
  @class_instance_var = "class instance variable"

  # Class method
  def self.class_method
    @class_method_var = "class method var"
    "Using #{@class_method_var} and #{@@class_var}"
  end

  # Another class method
  def self.another_class_method
    @another_class_var = "another class var"
    "Using #{@another_class_var} and #{@class_instance_var}"
  end

  # Instance method
  def initialize
    @instance_var1 = "instance var1"
    @instance_var2 = "instance var2"
  end

  # Another instance method
  def instance_method
    @instance_var1 = "modified"
    @instance_var3 = "instance var3"
    "Using #{@instance_var1}, #{@instance_var2}, and #{@instance_var3}"
  end

  # Private instance method
  private

  def private_instance_method
    @private_var = "private var"
    "Using #{@private_var} and #{@instance_var1}"
  end
end
