module Clamp
  
  class Attribute

    attr_reader :description, :attribute_name, :default_value

    def help_rhs
      rhs = description
      if defined?(@default_value)
        rhs += " (default: #{@default_value.inspect})"
      end
      rhs
    end
    
    def help
      [help_lhs, help_rhs]
    end
    
  end
  
end