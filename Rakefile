# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:rspec)
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ["--parallel"]
end

task default: %i[rubocop rspec]
