require "clamp/attribute/declaration"
require "clamp/parameter/definition"

module Clamp
  module Parameter

    module Declaration

      include Clamp::Attribute::Declaration

      def parameters
        @parameters ||= []
      end

      def has_parameters?
        !parameters.empty?
      end

      def parameter(name, description, options = {}, &block)
        Parameter::Definition.new(name, description, options).tap do |parameter|
          declare_attribute(parameter, &block)
          parameters << parameter
        end
      end

    end

  end
end
