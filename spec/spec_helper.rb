# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "bundler/setup"
require "pry-byebug"
require "reforge"
require "super_diff/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Run tests in random order
  config.order = :random

  # Profile the 5 slowest examples
  config.profile_examples = 5

  config.expect_with :rspec do |expect_config|
    expect_config.syntax = :expect

    # Show all expectation messages when they are chained together
    expect_config.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # Show detailed output when only one file is run
  config.default_formatter = :documentation if config.files_to_run.one?

  config.mock_with :rspec do |mock_config|
    # Expecting/allowing method calls on nil is an error
    mock_config.allow_message_expectations_on_nil = false

    # Disallow expecting/allowing unknown method calls
    mock_config.verify_partial_doubles = true
  end

  # TRICKY: class instance variables persist between tests and should be cleared to avoid cross-test pollution,
  # particularly in cases when they have been stubbed. We remove the ones present in the following array before
  # every test just to be safe
  class_instance_variables = [
    [Reforge, :@configuration],
    [Reforge::Transformation, :@transform_definitions]
  ]
  config.prepend_before do
    class_instance_variables.each do |klass, instance_variable|
      klass.remove_instance_variable(instance_variable) if klass.instance_variable_defined?(instance_variable)
    end
  end
end
