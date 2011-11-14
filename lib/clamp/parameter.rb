require 'clamp/attribute'

module Clamp

  class Parameter < Attribute

    def initialize(name, description, options = {})
      @name = name
      @description = description
      infer_attribute_name_and_multiplicity
      if options.has_key?(:attribute_name)
        @attribute_name = options[:attribute_name].to_s
      end
      if options.has_key?(:default)
        @default_value = options[:default]
      end
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

    NAME_PATTERN = "([A-Za-z0-9_-]+)"

    def infer_attribute_name_and_multiplicity
      case @name
      when /^\[#{NAME_PATTERN}\]$/
        @attribute_name = $1
      when /^\[#{NAME_PATTERN}\] ...$/
        @attribute_name = "#{$1}_list"
        @multivalued = true
      when /^#{NAME_PATTERN} ...$/
        @attribute_name = "#{$1}_list"
        @multivalued = true
        @required = true
      when /^#{NAME_PATTERN}$/
        @attribute_name = @name
        @required = true
      else
        raise "invalid parameter name: '#{name}'"
      end
      @attribute_name = @attribute_name.downcase.tr('-', '_')
    end

    def multivalued?
      @multivalued
    end

    def required?
      @required
    end

  end

end
