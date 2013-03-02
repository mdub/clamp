require 'clamp/attribute_declaration'
require 'clamp/option'

module Clamp
  class Option

    module Declaration

      include Clamp::AttributeDeclaration

      def option(switches, type, description, opts = {}, &block)
        option = Clamp::Option.new(switches, type, description, opts, &block)
        declared_options << option
        define_accessors_for(option)
        option
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

      protected

      def effective_options
        initial_options = parent_command.nil? ? [] : parent_command.effective_options
        accumulated_options = ancestors.inject(initial_options) do |options, ancestor|
          if ancestor.kind_of?(Clamp::Option::Declaration)
            options + ancestor.declared_options
          else
            options
          end
        end
        accumulated_options.each { |opt| define_accessors_for(opt) }
        accumulated_options
      end

    end

  end
end
