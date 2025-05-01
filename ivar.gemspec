# frozen_string_literal: true

require_relative "lib/ivar/version"

Gem::Specification.new do |spec|
  spec.name = "ivar"
  spec.version = Ivar::VERSION
  spec.authors = ["Avdi Grimm"]
  spec.email = ["avdi@avdi.codes"]

  spec.summary = "Automatically check instance variables for typos."
  spec.description = <<~DESCRIPTION
    Ruby instance variables are so convenient - you don't even need to declare them!
    But... they are also dangerous, because a mispelled variable name results in `nil`
    instead of an error.

    Why not have the best of both worlds? Ivar lets you use plain-old instance variables,
    and automatically checks for typos.

    Ivar waits until an instance is created to do the checking, then uses Prism to look
    for variables that don't match what was set in initialization. So it's a little bit
    dynamic, a little bit static. It doesn't encumber your instance variable reads and
    writes with any extra checking. And with the `:warn_once` policy, it won't overwhelm
    you with output.
  DESCRIPTION

  spec.homepage = "https://github.com/avdi/ivar"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/avdi/ivar"
  spec.metadata["changelog_uri"] = "https://github.com/avdi/ivar/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile]) ||
        f.end_with?(".gem")
    end
  end
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "prism", "~> 1.2"
end
