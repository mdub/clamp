module Clamp

  class Argument

    def initialize(name, description, options = {})
      @name = name
      @description = description
      if options.has_key?(:attribute_name)
        @attribute_name = options[:attribute_name].to_s 
      end
    end

    attr_reader :name, :description
    
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

end
