require 'clamp/option'

module Clamp

  module OptionSupport

    def option(switches, argument_type, description, opts = {}, &block)
      option = Clamp::Option.new(switches, argument_type, description, opts)
      declare_option(option, &block)
    end

    def has_options?
      !declared_options.empty?
    end

    def declared_options
      my_declared_options + inherited_declared_options
    end

    def recognised_options
      declared_options + standard_options
    end

    def find_option(switch)
      recognised_options.find { |o| o.handles?(switch) }
    end

    private

    def my_declared_options
      @my_declared_options ||= []
    end

    def declare_option(option, &block)
      my_declared_options << option
      declare_option_reader(option)
      declare_option_writer(option, &block)
    end

    def inherited_declared_options
      if superclass.respond_to?(:declared_options)
        superclass.declared_options
      else
        []
      end
    end

    HELP_OPTION = Clamp::Option.new("--help", :flag, "print help", :attribute_name => :help_requested)

    def standard_options
      [HELP_OPTION]
    end

    def declare_option_reader(option)
      reader_name = option.attribute_name
      reader_name += "?" if option.flag?
      ivar_name = "@#{option.attribute_name}"
      define_method(reader_name) do
        if instance_variable_defined?(ivar_name)
          instance_variable_get(ivar_name)
        elsif parent_command && parent_command.respond_to?(reader_name)
          parent_command.send(reader_name)
        else
          option.default_value
        end
      end
    end

    def declare_option_writer(option, &block)
      define_method("#{option.attribute_name}=") do |value|
        if block
          value = instance_exec(value, &block)
        end
        instance_variable_set("@#{option.attribute_name}", value)
      end
    end

  end

end
