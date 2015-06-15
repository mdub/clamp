require 'clamp/attribute/declaration'
require 'clamp/option/definition'

module Clamp
  module Option

    module Declaration

      include Clamp::Attribute::Declaration

      def option(switches, type, description, opts = {}, &block)
        opts[:scope] = @current_scope if @current_scope
        Option::Definition.new(switches, type, description, opts).tap do |option|
          declared_options << option
          scopes[option.scope] ||= []
          scopes[option.scope] << option if option.scope
          block ||= option.default_conversion_block
          define_accessors_for(option, &block)
        end
      end

      def scope(name, &block)
        raise Clamp::DeclarationError, "Nested scopes aren't allowed" if @current_scope
        @current_scope = name
        instance_exec(&block)
        @current_scope = nil
      end

      def scopes
        @scopes ||= {}
      end

      def find_option(switch)
        recognised_options.find { |o| o.handles?(switch) }
      end

      def declared_options
        @declared_options ||= []
      end

      def recognised_options
        declare_implicit_options
        effective_options
      end

      private

      def declare_implicit_options
        return nil if defined?(@implicit_options_declared)
        unless effective_options.find { |o| o.handles?("--help") }
          help_switches = ["--help"]
          help_switches.unshift("-h") unless effective_options.find { |o| o.handles?("-h") }
          option help_switches, :flag, "print help" do
            request_help
          end
        end
        @implicit_options_declared = true
      end

      def effective_options
        ancestors.inject([]) do |options, ancestor|
          if ancestor.kind_of?(Clamp::Option::Declaration)
            options + ancestor.declared_options
          else
            options
          end
        end
      end

    end

  end
end
