# Ivar

Ivar is a Ruby gem that automatically checks for typos in instance variables.

## Synopsis

```ruby
require "ivar/check_all" if $VERBOSE

class Pizza
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
$ ruby -w pizza.rb
pizza.rb:10: warning: unknown instance variable @topings. Did you mean: @toppings?
```

## Introduction

> OK I read the synopsis but I don't get it.

That's because what Ivar does seems so basic that it's almost a surprise it isn't part of the language. Do you see that warning about an unkown instance variable? That's Ivar, helping you avoid a bug.

> Oh! Because in Ruby, any unset instance variable ("ivar") you reference just returns `nil`, with no error or warning.

Exactly.

> Yeah what's up with that anyway.

It's actually one of the conveniences of the language: when you realize you need to store a field you just do it, without having to go back and declare it somewhere else in the class:

```ruby
class MyClass
  # ...
  def increment_usage_count!
    (@usage_count ||= 0) += 1
  end
  # ...
end
```

> Right but there is no protection against typos.

Also true. If we later do this:

```ruby
class MyClass
  # ...
  def usage_count
    @usag_count
  end
  # ...
end
```

...there's nothing to tell us we got the variable wrong.

> I thought that's why we're supposed to use attr_reader and friends.

Yes, this is why a lot of people recommend using `attr_reader`/`_writer`/`attr_accessor` pervasively. Only ever reading or writing ivars through accessors. But this gives up the convenience, informality, and conciseness of Ruby's instance variables. And it also puts you at risk of Ruby's all-time favorite gotcha: forgetting to put `self.` in front a setter call.

```ruby
class MyClass
  attr_accessor :usage_count

  def increment_usage_count!
    usage_count += 1  # oops, incremented a local, not the ivar
  end
end
```

> Ouch, bad memories.

Yeah. Personally I've gone through phases with this. For many years I followed and advocated the advice to use accessors everywhere. But lately I've kind of gone back to my roots on using unadorned ivars directly when I'm not setting up a public interface.

Then I ran into Joel Drapper's [`strict_ivars`](https://github.com/joeldrapper/strict_ivars) gem and it got my wheels turning. I preferred a warning to a hard error, and I didn't necessarily want to have to change methods that intentionally referenced unset ivars. It got me wondering, though: what would it look like to have Ruby warn about possible typos in ivar names, the same way it warns about other potential oopsies? What even would the heuristic be to determine if an ivar reference might be a typo?

> Well obviously you found a way to do it. What heuristics does Ivar use?

At the moment there are two ways to give an ivar the stamp of approval. The first is the most un-intrusive: set it in the initializer.

> Oh, like in that first example, you set `@toppings` in the initializer.

```ruby
require "ivar/check_all" if $VERBOSE

class Pizza
  def initialize(toppings)
    @toppings = toppings
  end
  # ...
end

```

Exactly.

> And then what... spooky magic happens?

Well, let's use a slightly more explicit version.

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  def initialize(toppings)
    @toppings = toppings
  end
  # ...
end
```

That's what `ivar/check_all` implicitly does under the hood: adds `Ivar::Checked` to classes.

> Which does what, exactly?

Let's use an even more explicit version to demonstrate:

```ruby
require "ivar"

class Pizza
  include Ivar::Validation

  def initialize(toppings)
    @toppings = toppings
    check_ivars
  end
  # ...
end
```

> So `check_ivars` is the magic method that does the checking?

Exactly. `Ivar::Checked` just arranges to automatically call it after your `initialize` methods finish.

> And what, precisely, does `check_ivars` do?

Well, it first notes all currently set ivars, and stamps them as "known". Then it kicks off a just-in-time static analysis of the class using [Prism](https://github.com/ruby/prism), to find all ivar references. And then it compares the two lists and generates warnings for any references that don't match a known ivar.

> And it does this when an instance is created?

Yep!

> OK I have some concerns about that but I'll save them for later. My next question is: what if I want to use an ivar without first initializing it in the `initialize` method?

Well, if you're using the explicit `check_ivars` version you can stamp some additional ivars as "known" by passing them in as an argument:

```ruby
require "ivar"

class Pizza
  include Ivar::Validation

  def initialize(toppings)
    @toppings = toppings
    check_ivars(add: [:@extra_cheese])
  end
  # ...
end
```

But the canonical way to do it is with the `ivar` macro:

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  ivar :@minutes_waiting

  def increment_wait_time
    (@minutes_waiting ||= 0) += 1
  end
  # ...
end
```

This is purely a declaration: the variable will not be set. But as a convenience, you *can* also initialize it with a value:

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  ivar :@minutes_waiting, value: 0

  def increment_wait_time
    @minutes_waiting += 1
  end
  # ...
end
```

> Can I initialize it with a different value for each instance?

Yes, you can pass a block that generates the value:

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  ivar(:@order_time) { Time.now }
  # ...
end
```

This block will be passed the ivar name as an argument, if you want to do something fancy like share one dynamic initialization block between multiple ivars:

```ruby
require "ivar"

class Pizza
  include Ivar::Checked

  ivar :@order_time, :@delivery_time do |ivar_name|
   Time.now + (ivar_name == :@order_time ? 0 : 30)
  end
  # ...
end
```

Which, yes, you can declare multiple ivars in one `ivar` call, if you want. You can also split them between individual `ivar` declarations.

> But what if I want to initialize an ivar from a constructor argument? Do I need to go back to the `initialize` method for that?

No you don't! One of the coolest conveniences that `ivar` adds is the ability to mark an ivar as initializable from a constructor argument:

```ruby
require "ivar"

class Sandwich
  include Ivar::Checked

  ivar :@bread, init: :kwarg
  ivar :@cheese, init: :kwarg
  ivar :@condiments, init: :kwarg

  def to_s
    "A #{@bread} sandwich with #{@cheese} and #{@condiments.join(", ")}"
  end
end

s = Sandwich.new(bread: "wheat", cheese: "muenster", condiments: ["mayo"])
s.to_s  # => "A wheat sandwich with muenster and mayo"
```

Notice the lack of an initialize method, and the lack of the usual Ruby repetition of `@ivar_name = ivar_name`.

> Whoah.

Right??? Oh yeah we've got positional arguments too if you like those better.

```ruby
require "ivar"

class Sandwich
  include Ivar::Checked

  ivar :@bread, init: :arg
  ivar :@cheese, init: :arg
  ivar :@condiments, init: :arg

  def to_s
    "A #{@bread} sandwich with #{@cheese} and #{@condiments.join(", ")}"
  end
end

s = Sandwich.new("wheat", "muenster", ["mayo"])
s.to_s  # => "A wheat sandwich with muenster and mayo"
```

> What if I also want external accessor methods?

Gotcha covered.

```ruby
require "ivar"

class Sandwich
  include Ivar::Checked

  ivar :@bread, init: :kwarg, reader: true
  ivar :@cheese, init: :kwarg, reader: true
  ivar :@condiments, init: :kwarg, accessor: true
end

s = Sandwich.new(bread: "wheat", cheese: "muenster", condiments: ["mayo"])
s.bread  # => "wheat"
s.cheese  # => "muenster"
s.condiments = ["mustard"]
s.condiments  # => ["mustard"]
```

> This seems like it's more than just about detecting ivar typos at this point.

Yeah, well, I knew that in order to determine typos I'd have to have some kind of declaration mechanism. And once I have that, I might as well make it useful. And use it to gain back some of the convenience lost to having to write the declaration in the first place.

> Fair enough.

Any other questions?

> What about inheritance? Can I use these tools both parent and child clases?

Yes, `ivar` goes to a fair amount of trouble to "just work" in ways you'll (hopefully) expect when it comes to inheritance.

More questions?

> Well, earlier you said that checking happens at object-instantiation time. Does this mean I'm going to be flooded with warnings if my code creates a lot of instances?

Excellent question! No, not out of the boxt. The default policy (`:warn_once`) is to warn only once per class, not per instance.

> Are there other policies?

Yeah, there's `:warn` for warning every time; `:log` for logging warnings, `:raise` for raising an exception, and `:none` for no checking at all.

Policies can be set program-wide:

```ruby
require "ivar"
Ivar.check_policy = :log
```

...or on a per-class basis:

```ruby
require "ivar"

class Pizza
  include Ivar::Checked
  ivar_check_policy :none
  # ...
end
```

...or when invoking `check_ivars`:

```ruby
require "ivar"

class Pizza
  include Ivar::Validation

  def initialize(toppings)
    @toppings = toppings
    check_ivars(policy: :raise)
  end
  # ...
end
```

You can check out the source code for more details about check policies.

> I still have some questions. Specifically... what exactly is going on behind the scenes with `ivar/check_all`? That seems... spooky.

Yeah. So when you require `ivar/check_all`, what you're doing is invoking `Ivar.check_all`.

This sets up a TracePoint that watches for class and module definitions. When it detects one, it includes `Ivar::Checked` into that the class or module.

> Wait so it infects every single class I load?

Not quite. It tries pretty hard to only do it for code from your project; not for stuff from gems or the standard library.

> Doesn't a TracePoint have a performance impact?

Yeah probably. That's why I don't necessarily recommend `ivar/check_all` for production use. But there are a couple of alternatives. For one, you can do it like we had in the opening example: only load it when `$VERBOSE` is true.

```ruby
require "ivar/check_all" if $VERBOSE
```

Or, you can use the block form of `Ivar.check_all`, which will only enable checking for classes defined within the block.

```ruby
require "ivar"

Ivar.check_all do
  # load your code here
end
```

With this version the tracepoint will only be active for the duration of the `check_all` block.

## Acknowledgements

Thanks first to [Joel Draper](https://github.com/joeldrapper) for creating [strict_ivars](https://github.com/joeldrapper/strict_ivars), which inspired this gem. If `ivar` isn't quite what you're looking for, check out `strict_ivars` instead!

Thanks also to [Augment Code](https://www.augmentcode.com/), which served as my "hands" for building this. I'm not at a point in my life where I can actually afford the time to build random passion projects, so this project wouldn't exist without help from the robot.

## Contribution

Contributions are welcome! Fair warning, if I accept a bunch of your PRs I may nominate you as a maintainer. I know my limits: I'm better at kicking off projects than at maintaining them.
