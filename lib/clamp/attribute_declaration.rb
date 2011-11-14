module Clamp

  module AttributeDeclaration

    protected

    def define_accessors_for(attribute, &block)
      define_reader_for(attribute)
      define_default_for(attribute)
      define_writer_for(attribute, &block)
    end

    def define_reader_for(attribute)
      define_method(attribute.read_method) do
        if instance_variable_defined?(attribute.ivar_name)
          instance_variable_get(attribute.ivar_name)
        else
          send(attribute.default_method)
        end
      end
    end

    def define_default_for(attribute)
      define_method(attribute.default_method) do
        attribute.default_value
      end
    end

    def define_writer_for(attribute, &block)
      define_method(attribute.write_method) do |value|
        if block
          value = instance_exec(value, &block)
        end
        instance_variable_set(attribute.ivar_name, value)
      end
    end

  end

end