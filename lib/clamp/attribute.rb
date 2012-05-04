module Clamp

  class Attribute

    attr_reader :description, :attribute_name, :default_value, :environment_variable

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
