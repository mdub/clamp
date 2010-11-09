require 'clamp/argument'
require 'clamp/attribute_declaration'

module Clamp

  module ArgumentSupport

    include AttributeDeclaration
    
    def declared_arguments
      @declared_arguments ||= []
    end

    def argument(name, description, &block)
      argument = Argument.new(name, description)
      declared_arguments << argument
      define_accessors_for(argument, &block)
    end
  
  end

end
