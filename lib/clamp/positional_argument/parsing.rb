module Clamp
  class PositionalArgument

    module Parsing

      def parse_positional_arguments
        return false if self.class.positional_arguments.empty?
        self.class.positional_arguments.each do |argument|
          if arguments.empty? && argument.required?
            signal_usage_error "no value provided for #{argument.name}"
          end
          value = arguments.shift
          begin
            send("#{argument.attribute_name}=", value)
          rescue ArgumentError => e
            signal_usage_error "option '#{argument.name}': #{e.message}"
          end
        end
        unless arguments.empty?
          signal_usage_error "too many arguments"
        end
      end

    end

  end
end
