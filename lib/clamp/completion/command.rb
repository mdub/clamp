# frozen_string_literal: true

module Clamp
  module Completion

    # A subcommand that generates shell completion scripts.
    #
    # Usage:
    #   subcommand "completion", "Generate shell completions",
    #     Clamp::Completion::Command
    #
    class Command < Clamp::Command

      parameter "SHELL", "shell type (bash, fish, zsh)"

      def execute
        root_class = context.fetch(:root_command_class) do
          raise "Clamp::Completion::Command requires 'clamp/completion' to be loaded before .run is called"
        end
        executable_name = invocation_path.split.first
        puts root_class.generate_completion(shell.to_sym, executable_name)
      end

    end

  end
end
