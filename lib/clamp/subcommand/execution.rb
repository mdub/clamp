module Clamp
  class Subcommand

    module Execution

      def execute
        subcommand_class = find_subcommand_class(subcommand_name)
        subcommand = subcommand_class.new("#{invocation_path} #{subcommand_name}", context)
        self.class.recognised_options.each do |option|
          option_set = instance_variable_defined?(option.ivar_name)
          if option_set && subcommand.respond_to?(option.write_method)
            subcommand.send(option.write_method, self.send(option.read_method))
          end
        end
        subcommand.run(subcommand_arguments)
      end

      protected

      def handle_remaining_arguments
        @subcommand_arguments = remaining_arguments
        @subcommand_name = @subcommand_arguments.shift
      end

      private

      def subcommand_name
        @subcommand_name ||= default_subcommand
      end

      attr_reader :subcommand_arguments

      def default_subcommand
        request_help
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
