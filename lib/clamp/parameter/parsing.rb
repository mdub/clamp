module Clamp
  class Parameter

    module Parsing

      protected
      
      def parse_parameters
        return false if self.class.parameters.empty?
        self.class.parameters.each do |parameter|
          if arguments.empty? && parameter.required?
            signal_usage_error "no value provided for #{parameter.name}"
          end
          value = arguments.shift
          begin
            send("#{parameter.attribute_name}=", value)
          rescue ArgumentError => e
            signal_usage_error "option '#{parameter.name}': #{e.message}"
          end
        end
        unless arguments.empty?
          signal_usage_error "too many arguments"
        end
      end

    end

  end
end
