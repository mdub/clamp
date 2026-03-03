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

      parameter "[SHELL]", "shell type or path (e.g. bash, /usr/bin/fish)",
                default: "NONE", environment_variable: "SHELL"

      def execute
        root_class = context.fetch(:root_command_class) do
          raise "Clamp::Completion::Command requires 'clamp/completion' to be loaded before .run is called"
        end
        executable_name = invocation_path.split.first
        shell_name = File.basename(shell).to_sym
        puts root_class.generate_completion(shell_name, executable_name)
      end

    end

  end
end
