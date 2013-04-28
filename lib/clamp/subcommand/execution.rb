module Clamp
  module Subcommand

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
        parent_attribute_values = {}
        inheritable_attributes.each do |option|
          if instance_variable_defined?(option.ivar_name)
            parent_attribute_values[option] = instance_variable_get(option.ivar_name)
          end
        end
        subcommand_class.new("#{invocation_path} #{name}", context, parent_attribute_values)
      end

      def inheritable_attributes
        self.class.recognised_options + self.class.parameters_before_subcommand
      end

      def find_subcommand_class(name)
        subcommand_def = self.class.find_subcommand(name) || signal_usage_error("No such sub-command '#{name}'")
        subcommand_def.subcommand_class
      end

    end

  end
end
