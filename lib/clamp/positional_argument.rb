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

  end

end
