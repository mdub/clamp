module Clamp
  module Parameter

    module Parsing

      protected

      def parse_parameters

        self.class.parameters.each do |parameter|
          begin
            parameter.consume(remaining_arguments).each do |value|
              parameter.of(self).write(value)
            end
          rescue ArgumentError => e
            signal_usage_error "parameter '#{parameter.name}': #{e.message}"
          end
        end

        self.class.parameters.each do |parameter|
          next if parameter.of(self).defined?
          next if parameter.environment_variable.nil?
          next unless ENV.has_key?(parameter.environment_variable)
          # Set the parameter value if it's environment variable is present
          value = ENV[parameter.environment_variable]
          parameter.of(self).write(value)
        end

      end

    end

  end
end
