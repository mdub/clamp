module Clamp
  class Parameter

    module Parsing

      protected
      
      def parse_parameters

        return false if self.class.parameters.empty?

        self.class.parameters.each do |parameter|
          begin
            value = parameter.consume(arguments)
            send("#{parameter.attribute_name}=", value)
          rescue ArgumentError => e
            signal_usage_error "parameter '#{parameter.name}': #{e.message}"
          end
        end

        unless arguments.empty?
          signal_usage_error "too many arguments"
        end

      end

    end

  end
end
