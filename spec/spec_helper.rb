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

  config.expect_with :rspec do |c|
    c.syntax = :expect
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
