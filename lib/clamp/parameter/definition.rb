require 'clamp/attribute/definition'

module Clamp
  module Parameter

    class Definition < Attribute::Definition

      def initialize(name, description, options = {})
        @name = name
        @description = description
        super(options)
        @multivalued = (@name =~ ELLIPSIS_SUFFIX)
        @required = options.fetch(:required) do
          (@name !~ OPTIONAL)
        end
        @prompt = options[:prompt]
      end

      attr_reader :name, :prompt

      def help_lhs
        name
      end

      def consume(arguments)
        if arguments.empty?
          return Array(prompt.call) if prompt
          raise ArgumentError, Clamp.message(:no_value_provided) if required?
        end
        arguments.shift(multivalued? ? arguments.length : 1)
      end

      private

      ELLIPSIS_SUFFIX = / \.\.\.$/
      OPTIONAL = /^\[(.*)\]/

      VALID_ATTRIBUTE_NAME = /^[a-z0-9_]+$/

      def infer_attribute_name
        inferred_name = name.downcase.tr('-', '_').sub(ELLIPSIS_SUFFIX, '').sub(OPTIONAL) { $1 }
        unless inferred_name =~ VALID_ATTRIBUTE_NAME
          raise "cannot infer attribute_name from #{name.inspect}"
        end
        inferred_name += "_list" if multivalued?
        inferred_name
      end

    end

  end
end
