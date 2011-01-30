module Clamp
  class Subcommand

    module Execution

      protected
      
      def execute_subcommand
        signal_usage_error "no subcommand specified" unless subcommand_name
        subcommand_class = find_subcommand_class(subcommand_name)
        subcommand = subcommand_class.new("#{invocation_path} #{subcommand_name}", context)
        self.class.declared_options.each do |option|
          option_set = instance_variable_defined?(option.ivar_name)
          if option_set && subcommand.respond_to?(option.write_method)
            subcommand.send(option.write_method, self.send(option.read_method))
          end
        end
        subcommand.run(subcommand_arguments)
      end

      private

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
