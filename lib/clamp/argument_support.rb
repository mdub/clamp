require 'clamp/argument'
require 'clamp/attribute_declaration'

module Clamp

  module ArgumentSupport

    include AttributeDeclaration
    
    def positional_arguments
      @positional_arguments ||= []
    end

    def argument(name, description, &block)
      argument = Argument.new(name, description)
      positional_arguments << argument
      define_accessors_for(argument, &block)
    end
  
  end

end
