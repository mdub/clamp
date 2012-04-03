module Clamp
  class Subcommand

    module Parsing

      protected

      def parse_subcommand
        return false unless self.class.has_subcommands?
        subcommand_name = parse_subcommand_name
        @subcommand = instatiate_subcommand(subcommand_name)
        @subcommand.parse(remaining_arguments)
        remaining_arguments.clear
      end

      private

      def parse_subcommand_name
        remaining_arguments.shift || self.class.default_subcommand || request_help
      end

      def find_subcommand(name)
        self.class.find_subcommand(name) ||
        signal_usage_error("No such sub-command '#{name}'")
      end

      def instatiate_subcommand(name)
        subcommand_class = find_subcommand(name).subcommand_class
        subcommand = subcommand_class.new("#{invocation_path} #{name}", context)
        self.class.recognised_options.each do |option|
          if instance_variable_defined?(option.ivar_name)
            subcommand.instance_variable_set(option.ivar_name, instance_variable_get(option.ivar_name))
          end
        end
        subcommand
      end

    end

  end
end
