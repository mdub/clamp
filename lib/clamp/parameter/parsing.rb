module Clamp
  class Parameter

    module Parsing

      protected
      
      def parse_parameters
        self.class.parameters.each do |parameter|
          begin
            value = parameter.consume(remaining_arguments)
            send("#{parameter.attribute_name}=", value) unless value.nil?
          rescue ArgumentError => e
            if parameter.name != "SUBCOMMAND"
              signal_usage_error "parameter '#{parameter.name}': #{e.message}"
            else
              signal_usage_error "no subcommand specified", true
            end
          end
        end

        unless remaining_arguments.empty?
          signal_usage_error "too many arguments"
        end

      end

    end

  end
end
