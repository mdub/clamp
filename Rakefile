# frozen_string_literal: true

require "bundler"

Bundler::GemHelper.install_tasks

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/**/*_spec.rb"
  t.exclude_pattern = "spec/**/*_integration_spec.rb"
  t.rspec_opts = ["--colour", "--format", "documentation"]
end

RSpec::Core::RakeTask.new(:integration) do |t|
  t.pattern = "spec/**/*_integration_spec.rb"
  t.rspec_opts = ["--colour", "--format", "documentation"]
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task "default" => ["spec", "integration", "rubocop"]
