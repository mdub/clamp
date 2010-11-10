module Clamp
  class Subcommand

    module Execution

      def execute_subcommand
        signal_usage_error "no subcommand specified" if arguments.empty?
        subcommand_name = arguments.shift
        subcommand_class = find_subcommand_class(subcommand_name)
        subcommand = subcommand_class.new("#{name} #{subcommand_name}", context)
        subcommand.parent_command = self
        subcommand.run(arguments)
      end

      def find_subcommand(name)
        self.class.find_subcommand(name) || 
        signal_usage_error("No such sub-command '#{name}'")
      end

      def find_subcommand_class(name)
        subcommand = find_subcommand(name)
        subcommand.subcommand_class if subcommand
      end

    end

  end
end
