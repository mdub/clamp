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
            raise ParameterParseError.new("parameter '#{parameter.name}': #{e.message}", self, parameter.name, e)
          end
        end

        self.class.parameters.each do |parameter|
          parameter.of(self).default_from_environment
        end

      end

    end

  end
end
