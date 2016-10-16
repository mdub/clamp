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
        subcommand = subcommand_class.new("#{invocation_path} #{name}", context)
        self.class.inheritable_attributes.each do |attribute|
          if attribute.of(self).defined?
            attribute.of(subcommand).set(attribute.of(self).get)
          end
        end
        subcommand
      end

      def find_subcommand_class(name)
        subcommand_def = self.class.find_subcommand(name)
        return subcommand_def.subcommand_class if subcommand_def
        subcommand_missing(name)
      end

    end

  end
end
