module Clamp
  module Attribute

    module Declaration

      protected

      def define_accessors_for(attribute, &block)
        define_reader_for(attribute)
        define_default_for(attribute)
        define_writer_for(attribute, &block)
      end

      def define_reader_for(attribute)
        define_method(attribute.read_method) do
          if attribute.of(self).defined?
            attribute.of(self).value
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
          if attribute.multivalued?
            unless attribute.of(self).defined?
              attribute.of(self).value = []
            end
            attribute.of(self).value << value
          else
            attribute.of(self).value = value
          end
        end
      end

    end

  end
end
