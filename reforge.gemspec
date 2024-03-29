# frozen_string_literal: true

Gem::Specification.new do |spec|
  raise "RubyGems 2.0 or newer is required to protect against public gem pushes." unless spec.respond_to?(:metadata)

  spec.name = "reforge"
  spec.version = "0.1.2"
  spec.authors = ["Nate Eizenga"]
  spec.email = ["eizengan@gmail.com"]

  spec.summary = "Simple DSL-driven data transformation for Ruby"
  spec.homepage = "https://github.com/eizengan/reforge"
  spec.license = "MIT"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/eizengan/reforge/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = [">= 2.5", "< 4"]

  spec.add_dependency "zeitwerk", "~> 2.4"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "pry-byebug", "~> 3.9"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-performance", "~> 1.8"
  spec.add_development_dependency "rubocop-rake", "~> 0.6"
  spec.add_development_dependency "rubocop-rspec", "~> 2.10"
  spec.add_development_dependency "simplecov", "~> 0.17.1" # 0.18 breaks Code Climate. Ref: https://github.com/codeclimate/test-reporter/issues/413
  spec.add_development_dependency "super_diff", "~> 0.6"
end
