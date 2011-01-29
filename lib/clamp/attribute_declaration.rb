module Clamp
  
  module AttributeDeclaration

    protected
    
    def define_accessors_for(attribute, &block)
      define_reader_for(attribute)
      define_default_for(attribute)
      define_writer_for(attribute, &block)
    end
    
    def define_reader_for(attribute)
      reader_name = attribute.attribute_name
      reader_name += "?" if attribute.respond_to?(:flag?) && attribute.flag?
      ivar_name = "@#{attribute.attribute_name}"
      define_method(reader_name) do
        if instance_variable_defined?(ivar_name)
          instance_variable_get(ivar_name)
        elsif parent_command && parent_command.respond_to?(reader_name)
          parent_command.send(reader_name)
        elsif respond_to?("default_#{attribute.attribute_name}")
          send("default_#{attribute.attribute_name}")
        end
      end
    end

    def define_default_for(attribute)
      if attribute.respond_to?(:default_value)
        define_method("default_#{attribute.attribute_name}") do
          attribute.default_value
        end
      end
    end

    def define_writer_for(attribute, &block)
      define_method("#{attribute.attribute_name}=") do |value|
        if block
          value = instance_exec(value, &block)
        end
        instance_variable_set("@#{attribute.attribute_name}", value)
      end
    end

  end
  
end