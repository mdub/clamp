module Clamp
  module Attribute

    # Represents an option/parameter of a Clamp::Command instance.
    #
    class Instance

      def initialize(attribute, command)
        @attribute = attribute
        @command = command
      end

      attr_reader :attribute, :command

      def defined?
        command.instance_variable_defined?(attribute.ivar_name)
      end

      # get value, without defaulting
      def value
        command.instance_variable_get(attribute.ivar_name)
      end

      # set value directly
      def value=(value)
        command.instance_variable_set(attribute.ivar_name, value)
      end

      # get value, with defaulting
      def read
        command.send(attribute.read_method)
      end

      # set value via write_method
      def write(value)
        command.send(attribute.write_method, value)
      end

    end

  end
end
