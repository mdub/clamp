require 'clamp/attribute_declaration'
require 'clamp/option'

module Clamp
  class Option

    module Declaration

      include Clamp::AttributeDeclaration

      def option(switches, type, description, opts = {}, &block)
        option = Clamp::Option.new(switches, type, description, opts)
        my_declared_options << option
        define_accessors_for(option, &block)
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

    end

  end
end
