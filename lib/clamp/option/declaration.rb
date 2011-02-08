require 'clamp/attribute_declaration'
require 'clamp/option'

module Clamp
  class Option

    module Declaration

      include Clamp::AttributeDeclaration

      def option(switches, type, description, opts = {}, &block)
        option = Clamp::Option.new(switches, type, description, opts)
        declared_options << option
        define_accessors_for(option, &block)
      end

      def has_options?
        !documented_options.empty?
      end

      def find_option(switch)
        recognised_options.find { |o| o.handles?(switch) }
      end

      def declared_options
        @declared_options ||= []
      end

      def documented_options
        declared_options + inherited_declared_options
      end

      def recognised_options
        documented_options + standard_options
      end

      private

      def inherited_declared_options
        ancestors.inject([]) do |options, ancestor| 
          if ancestor.respond_to?(:declared_options)
            options + ancestor.declared_options
          else
            options
          end
        end
      end

      HELP_OPTION = Clamp::Option.new("--help", :flag, "print help", :attribute_name => :help_requested)

      def standard_options
        [HELP_OPTION]
      end

    end

  end
end
