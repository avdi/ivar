# Ivar

## Synopsis

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  def initialize(toppings)
    @toppings = toppings
  end

  def to_s
    "A pizza with #{@topings.join(", ")}"
  end
end

Pizza.new(["pepperoni", "mushrooms"])
```

```shell
$ ruby pizza.rb
pizza.rb:10: warning: unknown instance variable @topings. Did you mean: @toppings?
```

## Introduction

Ruby instance variables are so convenient - you don't even need to declare them! But... they are also dangerous, because a mispelled variable name results in `nil` instead of an error.

For this reason it's often recommended to wrap every instance variable in getter and setter methods with `attr_accessor`. But this added ceremony is exactly what self-declaring instance variables are there to avoid.

Why not have the best of both worlds? Ivar lets you use plain-old instance variables, and automatically checks for typos.

Ivar waits until an instance is created to do the checking, then uses Prism to look for variables that don't match what was set in initialization. So it's a little bit dynamic, a little bit static. It doesn't encumber your instance variable reads and writes with any extra checking. And with the `:warn_once` policy, it won't overwhelm you with output.


## Usage

### Explicit Validation

```ruby
# sandwich.rb
require "ivar"

class Sandwich
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
    check_ivars(add: [:@side])
  end

  def to_s
    "A #{@bread} sandwich with #{@chese} and #{@condiments.join(", ")}" \
    (@side ? "and a side of #{@side}" : "")
  end
end

Sandwich.new
```

```shell
$ ruby sandwich.rb -w
sandwich.rb:22: warning: unknown instance variable @chese. Did you mean: @cheese?
```

### Automatic Validation

```ruby
require "ivar"

class Sandwich
  include Ivar::Checked

  def initialize
    @bread = "white"
    @cheese = "havarti"
    @condiments = ["mayo", "mustard"]
    # no need for explicit check_ivars call
  end
  # ...
end
```

The `Checked` module automatically calls `check_ivars` after initialization.

Note that the `:warn_once` policy is the default, meaning that this will emit a warning the first time an instance is created, but not for later instances.

### Declare Instance Variables

With Ivar we "declare" variables implicitly by setting them in `initialize`. But if you don't have any reason to set them in the initializer, you can explicitly declare them so they won't be flagged.

#### Basic Declaration

```ruby
require "ivar"

class SandwichWithIvarMacro
  include Ivar::Checked

  ivar :@side

  def initialize
    @bread = "wheat"
    @cheese = "muenster"
    @condiments = ["mayo", "mustard"]
  end

  def add_side(side)
    @side = side
  end

  def to_s
    result = "A #{@bread} sandwich with #{@cheese} and #{@condiments.join(", ")}"
    result += " and a side of #{@side}" if defined?(@side) && @side
    result
  end
end
```

#### Declaration with Initial Values

As a convenience, ivars can be declared with initial values:

```ruby
class SandwichWithInitialValues
  include Ivar::Checked

  # Declare instance variables with initial values
  ivar "@bread":  "wheat",
       "@cheese": "muenster",
       "@pickles": true

  # ...
end
```

Note that this if you have an `initialize` method already, there is no great benefit to initializing your ivars in this way.

#### Declaration default `:value`

Alternately, you can use the `:value` keyword:

```ruby
class SandwichWithSharedValues
  include Ivar::Checked

  # Declare multiple condiments with the same initial value (true)
  ivar :@cheese, "pepper jack"

    # ...
end
```

You can also initialize multiple variables to the same default:

```ruby
class Sandwich
  include Ivar::Checked

  # Declare multiple condiments with the same initial value (true)
  ivar :@mayo, :@mustard, :@ketchup, value: true

  # ...
end
```

#### Declaration with dynamic values

For dynamic initialization, a block can be passed:

```ruby
class Sandwich
  include Ivar::Checked

  ivar(:@side) {  Time.now.hour < 12 ? "hash browns" : "chips" }

  # ...
end
```

The name of the variable being initialized is passed to the block.

```ruby
class Sandwich
  include Ivar::Checked

  ivar(:@mayo, :@mustard, :@ketchup) { |varname| !varname.include?("mayo") }

  # ...
end
```

#### Adding Accessor Methods

As another convenience, we can generate `attr_reader`/`attr_writer`/`attr_accessor` methods at the same time as declaring a variable:

```ruby
class Sandwich
  include Ivar::Checked

  # Declare instance variables with accessors
  ivar :@bread, :@cheese, accessor: true, value: "default"

  # Declare condiments with a reader
  ivar :@condiments, reader: true, value: ["mayo", "mustard"]

  # Declare pickles with a writer
  ivar :@pickles, writer: true, value: true

  # ...
end

sandwich = SandwichWithAccessors.new
puts "Bread: #{sandwich.bread}"  # Reader method
sandwich.bread = "rye"           # Writer method
puts "Updated bread: #{sandwich.bread}"
```

## Check Policies

Ivar supports different policies for handling unknown instance variables. You can specify a policy at the global level, class level, or per-check level.

### Available Policies

- `:warn` - Emit warnings for all unknown instance variables (default)
- `:warn_once` - Emit warnings only once per class
- `:raise` - Raise an exception for unknown instance variables
- `:log` - Log unknown instance variables to a logger
- `:none` - Do nothing (no-op) for unknown instance variables

### Setting a Global Policy

```ruby
# Set the global policy to raise exceptions
Ivar.check_policy = :raise

class Sandwich
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    check_ivars
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"  # This will raise an exception
  end
end

Sandwich.new  # Raises: NameError: test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

### Setting a Class-Level Policy

```ruby
class Sandwich
  include Ivar::Validation
  extend Ivar::CheckPolicy

  # Set the class-level policy to log
  ivar_check_policy :log, logger: Logger.new($stderr)

  def initialize
    @bread = "wheat"
    check_ivars
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"  # This will log a warning
  end
end

Sandwich.new  # Logs: W, [2023-06-01T12:34:56.789123 #12345] WARN -- : test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

### Setting a Per-Check Policy

```ruby
class Sandwich
  include Ivar::Validation

  def initialize
    @bread = "wheat"
    # Use the raise policy for this check
    check_ivars(policy: :raise)
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"
  end
end

Sandwich.new  # Raises: NameError: test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

### Using the Checked Module with Policies

The `Checked` module sets a default policy: of `:warn_once`.

You can override the default policy:

```ruby
class Sandwich
  include Ivar::Checked

  # Override the default policy
  ivar_check_policy :raise

  def initialize
    @bread = "wheat"
  end

  def to_s
    "A #{@bread} sandwich with #{@chese}"  # This will raise an exception
  end
end

Sandwich.new  # Raises: NameError: test_file.rb:2: unknown instance variable @chese. Did you mean: @cheese?
```

# Acknowledgements

Thank you to Joel Drapper, for inspiring me with [the strict_ivars gem](https://github.com/joeldrapper/strict_ivars).


And thanks to [Augment Code](https://www.augmentcode.com/), without which this gem wouldn't exist because I don't actually have time for pleasure projects anymore.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/avdi/ivar.

Fair warning: If you contribute a lot I might nominate you to be a maintainer. I know my limitations; I'm good at launching libraries, but not so good at maintaining them.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Releasing

This project uses a standardized release process:

1. Update the version number in `version.rb` according to [Semantic Versioning](https://semver.org/)
2. Update the CHANGELOG.md with your changes under the "Unreleased" section
3. Run the release script: `bin/release [major|minor|patch]`
4. Push the changes and tag: `git push origin main && git push origin v{version}`

For more details, see [VERSION.md](VERSION.md).

# TODO

- Add a module for dynamic checking of instance_variable_get/set
- Audit and improve code the robot wrote