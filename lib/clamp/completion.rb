# frozen_string_literal: true

require "clamp/command"
require "clamp/completion/bash_generator"
require "clamp/completion/fish_generator"
require "clamp/completion/zsh_generator"

module Clamp

  # Shell completion script generation.
  #
  module Completion

    GENERATORS = {
      bash: Clamp::Completion::BashGenerator,
      fish: Clamp::Completion::FishGenerator,
      zsh: Clamp::Completion::ZshGenerator
    }.freeze

    # Raised when --shell-completions is used; caught by Command.run.
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

    # Walk the command tree depth-first, yielding (command_class, path, has_children).
    # Path is an array of Subcommand::Definition objects.
    # Always yields, even for revisited classes (with has_children=false).
    def walk_command_tree(command_class, path = [], visited = Set.new, &block)
      fresh = !visited.include?(command_class)
      visited |= [command_class]
      has_children = command_class.has_subcommands? && fresh
      yield command_class, path, has_children
      return unless has_children

      command_class.recognised_subcommands.each do |sub|
        walk_command_tree(sub.subcommand_class, path + [sub], visited, &block)
      end
    end

    # Count required, non-multivalued parameters for a command.
    def required_parameter_count(command_class)
      command_class.parameters.count { |p| p.required? && !p.multivalued? }
    end

    # Collect all subcommand names across the command tree.
    def collect_subcommand_names(command_class)
      names = []
      walk_command_tree(command_class) do |cmd, _path, has_children|
        cmd.recognised_subcommands.each { |sub| names.concat(sub.names) } if has_children
      end
      names.uniq
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

    # Adds --shell-completions option and handles the Wanted exception.
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
