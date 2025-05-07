# frozen_string_literal: true

require_relative "lib/ivar/version"

Gem::Specification.new do |spec|
  spec.name = "ivar"
  spec.version = Ivar::VERSION
  spec.authors = ["Avdi Grimm"]
  spec.email = ["avdi@avdi.codes"]

  spec.summary = "A Ruby gem that automatically checks for typos in instance variables."
  spec.description = <<~DESCRIPTION
    Ivar is a Ruby gem that automatically checks for typos in instance variables.
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
