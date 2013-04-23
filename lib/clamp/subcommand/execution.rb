module Clamp
  class Subcommand

    module Execution

      # override default Command behaviour

      def execute
        # delegate to subcommand
        subcommand = instatiate_subcommand(subcommand_name)
        subcommand.run(subcommand_arguments)
      end

      private

      def instatiate_subcommand(name)
        subcommand_class = find_subcommand_class(name)
        subcommand = subcommand_class.new("#{invocation_path} #{name}", context)
        shared_options = self.class.recognised_options & subcommand_class.recognised_options
        shared_options.each do |option|
          if instance_variable_defined?(option.ivar_name)
            subcommand.instance_variable_set(option.ivar_name, instance_variable_get(option.ivar_name))
          end
        end
        subcommand
      end

      def find_subcommand_class(name)
        subcommand_def = self.class.find_subcommand(name) || signal_usage_error("No such sub-command '#{name}'")
        subcommand_def.subcommand_class
      end

    end

  end
end
