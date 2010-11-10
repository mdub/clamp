require 'clamp/attribute_declaration'
require 'clamp/positional_argument'

module Clamp

  class PositionalArgument

    def initialize(name, description, options = {})
      @name = name
      @description = description
      if options.has_key?(:attribute_name)
        @attribute_name = options[:attribute_name].to_s 
      end
    end

    attr_reader :name, :description, :required
    
    def help
      [name, description]
    end

    OPTIONAL_NAME_PATTERN = /^\[(.*)\]$/
    
    def attribute_name
      @attribute_name ||= name.sub(OPTIONAL_NAME_PATTERN) { $1 }.downcase.tr('-', '_')
    end
    
    def required?
      name !~ OPTIONAL_NAME_PATTERN
    end

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
