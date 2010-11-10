require 'clamp/attribute_declaration'
require 'clamp/parameter'

module Clamp
  class Parameter

    module Declaration

      include AttributeDeclaration

      def parameters
        @parameters ||= []
      end

      def parameter(name, description, &block)
        parameter = Parameter.new(name, description)
        parameters << parameter
        define_accessors_for(parameter, &block)
      end

    end

  end
end
