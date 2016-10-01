module Clamp
  module Parameter

    module Parsing

      protected

      def parse_parameters

        self.class.parameters.each do |parameter|
          begin
            parameter.consume(remaining_arguments).each do |value|
              parameter.of(self).take(value)
            end
          rescue ArgumentError => e
            signal_usage_error Clamp.message(:parameter_argument_error, :param => parameter.name, :message => e.message)
          end
        end

        self.class.parameters.each do |parameter|
          parameter.of(self).default_from_environment
          parameter.of(self).value_from_prompt
        end

      end

    end

  end
end
