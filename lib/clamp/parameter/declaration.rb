require 'clamp/attribute_declaration'
require 'clamp/parameter'

module Clamp
  class Parameter

    module Declaration

      include Clamp::AttributeDeclaration

      def parameters
        @parameters ||= []
      end

      def has_parameters?
        !parameters.empty?
      end

      def parameter(name, description, options = {}, &block)
        parameter = Parameter.new(name, description, options)
        parameters << parameter
        define_accessors_for(parameter, &block)
      end

    end

  end
end
