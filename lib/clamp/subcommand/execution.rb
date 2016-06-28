module Clamp
  module Subcommand

    module Execution

      # override default Command behaviour

      def execute
        # delegate to subcommand
        subcommand = instantiate_subcommand(subcommand_name)
        subcommand.run(subcommand_arguments)
      end

      private

      def instantiate_subcommand(name)
        subcommand_class = find_subcommand_class(name)
        parent_attribute_values = {}
        self.class.inheritable_attributes.each do |attribute|
          if attribute.of(self).defined?
            parent_attribute_values[attribute] = attribute.of(self).get
          end
        end
        subcommand_class.new("#{invocation_path} #{name}", context, parent_attribute_values)
      end

      def find_subcommand_class(name)
        subcommand_def = self.class.find_subcommand(name) || signal_usage_error(Clamp.message(:no_such_subcommand, :name => name))
        subcommand_def.subcommand_class
      end

    end

  end
end
