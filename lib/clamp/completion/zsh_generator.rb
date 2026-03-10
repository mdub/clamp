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
        generate_functions(lines, @command_class, [function_name], Set.new)
        lines << "_#{function_name}"
        lines.push("").join("\n")
      end

      private

      def function_name
        @executable_name
      end

      def generate_functions(lines, command_class, path, visited)
        has_children = command_class.has_subcommands? && !visited.include?(command_class)
        visited |= [command_class]
        func_name = "_#{path.join('_')}"

        if has_children
          generate_subcommand_node(lines, command_class, path, func_name, visited)
        else
          lines << "#{func_name}() {"
          specs = Completion.visible_options(command_class).map { |o| option_spec(o) }
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
        specs = Completion.visible_options(command_class).map { |o| option_spec(o) }
        specs << "'1:command:->commands'"
        specs << "'*::args:->args'"
        lines << "  _arguments -C \\"
        generate_spec_lines(lines, specs)
        lines << ""
        generate_state_dispatch(lines, command_class, path)
        lines << "}"
        lines << ""
        command_class.recognised_subcommands.each do |sub|
          generate_functions(lines, sub.subcommand_class, path + [sanitize(sub.names.first)], visited)
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
          sub_fn = "_#{(path + [sanitize(sub.names.first)]).join('_')}"
          pattern = sub.names.join("|")
          lines << "        #{pattern}) #{sub_fn} ;;"
        end
        lines << "      esac"
        lines << "      ;;"
        lines << "  esac"
      end

      def option_spec(option)
        expanded = Completion.expanded_switches(option)
        desc = "[#{escape(option.description)}]"
        arg_spec = option.flag? ? "" : ":#{option.type.to_s.downcase}:"
        exclusion = expanded.length > 1 ? "(#{expanded.join(' ')})" : ""

        "'#{exclusion}#{switch_pattern(option.switches)}#{desc}#{arg_spec}'"
      end

      def switch_pattern(switches)
        short = switches.find { |s| s =~ /^-[^-]/ }
        long = switches.find { |s| s =~ /^--/ }
        short && long ? "{#{short},#{long}}" : (long || short).to_s
      end

      def sanitize(name)
        name.gsub(/[^a-zA-Z0-9_]/, "_")
      end

      def escape(str)
        str.gsub("'", "'\\''")
      end

    end

  end
end
