# frozen_string_literal: true

module Clamp
  module Completion

    # Generates zsh shell completion scripts.
    #
    class ZshGenerator

      def initialize(command_class, executable_name)
        @command_class = command_class
        @executable_name = executable_name
      end

      def generate
        lines = ["#compdef #{@executable_name}", ""]
        generate_functions(lines, @command_class, [completion_function], Set.new)
        lines << completion_function
        lines.push("").join("\n")
      end

      private

      def completion_function
        "_clamp_complete_#{Completion.encode_name(@executable_name)}"
      end

      def generate_functions(lines, command_class, path, visited)
        has_children = command_class.has_subcommands? && !visited.include?(command_class)
        visited |= [command_class]
        func_name = path.join("_")

        if has_children
          generate_subcommand_node(lines, command_class, path, func_name, visited)
        else
          lines << "#{func_name}() {"
          specs = Completion.visible_options(command_class).flat_map { |o| option_specs(o) }
          generate_arguments_call(lines, specs) if specs.any?
          lines << "}"
          lines << ""
        end
      end

      def generate_subcommand_node(lines, command_class, path, func_name, visited)
        lines << "#{func_name}() {"
        lines << "  local context state state_descr line"
        lines << "  typeset -A opt_args"
        lines << ""
        specs = Completion.visible_options(command_class).flat_map { |o| option_specs(o) }
        specs << "'1:command:->commands'"
        specs << "'*::args:->args'"
        lines << "  _arguments -C \\"
        generate_spec_lines(lines, specs)
        lines << ""
        generate_state_dispatch(lines, command_class, path)
        lines << "}"
        lines << ""
        command_class.recognised_subcommands.each do |sub|
          generate_functions(lines, sub.subcommand_class, path + [Completion.encode_name(sub.names.first)], visited)
        end
      end

      def generate_arguments_call(lines, specs)
        lines << "  _arguments \\"
        generate_spec_lines(lines, specs)
      end

      def generate_spec_lines(lines, specs)
        specs.each_with_index do |spec, i|
          suffix = i < specs.length - 1 ? " \\" : ""
          lines << "    #{spec}#{suffix}"
        end
      end

      def generate_state_dispatch(lines, command_class, path)
        lines << "  case $state in"
        lines << "    commands)"
        lines << "      local -a cmds"
        lines << "      cmds=("
        command_class.recognised_subcommands.each do |sub|
          sub.names.each do |name|
            lines << "        '#{escape(name)}:#{escape(sub.description)}'"
          end
        end
        lines << "      )"
        lines << "      _describe 'command' cmds"
        lines << "      ;;"
        lines << "    args)"
        lines << "      case $line[1] in"
        command_class.recognised_subcommands.each do |sub|
          sub_fn = (path + [Completion.encode_name(sub.names.first)]).join("_")
          pattern = sub.names.join("|")
          lines << "        #{pattern}) #{sub_fn} ;;"
        end
        lines << "      esac"
        lines << "      ;;"
        lines << "  esac"
      end

      def option_specs(option)
        expanded = Completion.expanded_switches(option)
        suffix = "[#{escape(option.description)}]"
        suffix += ":#{option.type.to_s.downcase}:" unless option.flag?
        exclusion = expanded.length > 1 ? "'(#{expanded.join(' ')})'" : ""
        short = expanded.find { |s| s.match?(/^-[^-]/) }
        longs = expanded.grep(/^--/)

        if short && longs.length == 1
          # Braces outside quotes for zsh brace expansion
          ["#{exclusion}{#{short},#{longs.first}}'#{suffix}'"]
        else
          expanded.map { |sw| "#{exclusion}'#{sw}#{suffix}'" }
        end
      end

      def escape(str)
        str.gsub("'", "'\\''")
      end

    end

  end
end
