require 'clamp/attribute_declaration'

module Clamp

  class Argument < Struct.new(:name, :description)

    def help
      [name, description]
    end

    def attribute_name
      @attribute_name ||= name.downcase.tr('-', '_')
    end
    
    def default_value
      nil
    end

    def flag?
      false
    end
    
  end

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
