# frozen_string_literal: true

require "clamp/command"
require "clamp/completion/fish_generator"

module Clamp

  # Shell completion script generation.
  #
  module Completion

    GENERATORS = {
      fish: Clamp::Completion::FishGenerator
    }.freeze

    module_function

    def generate(command_class, shell, executable_name)
      generator_class = GENERATORS.fetch(shell) do
        raise ArgumentError, "unsupported shell: #{shell.inspect}"
      end
      generator_class.new(command_class, executable_name).generate
    end

    # Return switches with --[no-]foo expanded to --foo and --no-foo.
    def expanded_switches(option)
      option.switches.flat_map do |switch|
        if switch =~ /^--\[no-\](.*)/
          ["--#{Regexp.last_match(1)}", "--no-#{Regexp.last_match(1)}"]
        else
          switch
        end
      end
    end

    # Options visible in completion (excludes hidden).
    def visible_options(command_class)
      command_class.recognised_options.reject(&:hidden?)
    end

  end
end

module Clamp

  # Reopened to add completion generation.
  #
  class Command

    def self.generate_completion(shell, executable_name)
      Clamp::Completion.generate(self, shell, executable_name)
    end

  end

end
