require "clamp/attribute/instance"

module Clamp
  module Attribute

    class Definition

      def initialize(options)
        if options.key?(:attribute_name)
          @attribute_name = options[:attribute_name].to_s
        end
        @default_value = options[:default] if options.key?(:default)
        if options.key?(:environment_variable)
          @environment_variable = options[:environment_variable]
        end
        @hidden = options[:hidden] if options.key?(:hidden)
      end

      attr_reader :description, :environment_variable

      def help_rhs
        description + default_description
      end

      def help
        [help_lhs, help_rhs]
      end

      def ivar_name
        "@#{attribute_name}"
      end

      def read_method
        attribute_name
      end

      def default_method
        "default_#{read_method}"
      end

      def write_method
        "#{attribute_name}="
      end

      def append_method
        "append_to_#{attribute_name}" if multivalued?
      end

      def multivalued?
        @multivalued
      end

      def required?
        @required
      end

      def hidden?
        @hidden
      end

      def attribute_name
        @attribute_name ||= infer_attribute_name
      end

      def default_value
        if defined?(@default_value)
          @default_value
        elsif multivalued?
          []
        end
      end

      def of(command)
        Attribute::Instance.new(self, command)
      end

      private

      def default_description
        default_sources = [
          ("$#{@environment_variable}" if defined?(@environment_variable)),
          (@default_value.inspect if defined?(@default_value))
        ].compact
        return "" if default_sources.empty?
        " (default: " + default_sources.join(", or ") + ")"
      end

    end

  end
end
