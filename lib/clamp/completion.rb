# frozen_string_literal: true

require "clamp/command"
require "clamp/completion/fish_generator"
require "clamp/completion/command"

module Clamp

  # Shell completion script generation.
  #
  module Completion

    GENERATORS = {
      fish: Clamp::Completion::FishGenerator
    }.freeze

    # Raised when --completion is used; caught by Command.run.
    #
    class Wanted < StandardError

      def initialize(command, shell)
        super("completion requested")
        @command = command
        @shell = shell
      end

      attr_reader :command, :shell

    end

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

  # Reopened to add completion support.
  #
  class Command

    def self.generate_completion(shell, executable_name)
      Clamp::Completion.generate(self, shell, executable_name)
    end

    # Adds --completion option and handles the Wanted exception.
    #
    module RunWithCompletion

      def run(invocation_path = File.basename($PROGRAM_NAME), arguments = ARGV, context = {})
        context[:root_command_class] ||= self
        super
      rescue Clamp::Completion::Wanted => e
        shell_name = File.basename(e.shell).to_sym
        begin
          puts generate_completion(shell_name, invocation_path)
        rescue ArgumentError => ex
          $stderr.puts "ERROR: #{ex.message}"
          exit(1)
        end
      end

    end

    class << self

      prepend RunWithCompletion

    end

  end

end

module Clamp
  module Option

    # Adds implicit --shell-completions option to all commands.
    #
    module Declaration

      # Declares --shell-completions alongside other implicit options.
      #
      module WithCompletionOption

        def recognised_options
          unless @implicit_completion_option_declared
            @implicit_completion_option_declared = true
            declare_implicit_completion_option
          end
          super
        end

        private

        def declare_implicit_completion_option
          return if effective_options.find { |o| o.handles?("--shell-completions") }

          option "--shell-completions", "SHELL",
                 "generate shell completion script",
                 hidden: true do |shell|
            raise Clamp::Completion::Wanted.new(self, shell)
          end
        end

      end

      prepend WithCompletionOption

    end

  end
end
