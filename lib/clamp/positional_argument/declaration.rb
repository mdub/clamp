require 'clamp/attribute_declaration'
require 'clamp/positional_argument'

module Clamp
  class PositionalArgument

    module Declaration

      include AttributeDeclaration

      def positional_arguments
        @positional_arguments ||= []
      end

      def argument(name, description, &block)
        argument = PositionalArgument.new(name, description)
        positional_arguments << argument
        define_accessors_for(argument, &block)
      end

    end

  end
end
