require 'clamp/attribute'

module Clamp

  class Parameter < Attribute

    def initialize(name, description, options = {})
      @name = name
      @description = description
      @multivalued = (@name =~ ELLIPSIS_SUFFIX)
      @required = (@name !~ OPTIONAL)
      if options.has_key?(:attribute_name)
        @attribute_name = options[:attribute_name].to_s
      end
      if options.has_key?(:default)
        @default_value = options[:default]
      end
      if options.has_key?(:environment_variable)
        @environment_variable = options[:environment_variable]
      end
      @attribute_name ||= infer_attribute_name
    end

    attr_reader :name, :attribute_name

    def help_lhs
      name
    end

    def consume(arguments)
      if required? && arguments.empty?
        raise ArgumentError, "no value provided"
      end
      if multivalued?
        if arguments.length > 0
          arguments.shift(arguments.length)
        end
      else
        arguments.shift
      end
    end

    def default_value
      if defined?(@default_value)
        @default_value
      elsif multivalued?
        []
      end
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

    def multivalued?
      @multivalued
    end

    def required?
      @required
    end

  end

end
