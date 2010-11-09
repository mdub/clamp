require 'clamp/argument'
require 'clamp/attribute_declaration'

module Clamp

  module ArgumentSupport

    include AttributeDeclaration
    
    def declared_arguments
      @declared_arguments ||= []
    end

    def argument(name, description)
      argument = Argument.new(name, description)
      declared_arguments << argument
      define_accessors_for(argument)
    end
  
  end

end
