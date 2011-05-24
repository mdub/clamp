require 'clamp/subcommand'

module Clamp
  class Subcommand

    module Declaration

      def recognised_subcommands
        @recognised_subcommands ||= []
      end

      def subcommand(name, description, subcommand_class = self, &block)
        has_subcommands!
        declare_subcommand(name, description, subcommand_class, &block)
      end

      def default_subcommand(name, description, subcommand_class = self, &block)
        has_subcommands!(name)
        declare_subcommand(name, description, subcommand_class, &block)
      end

      def has_subcommands?
        @has_subcommands
      end

      def find_subcommand(name)
        recognised_subcommands.find { |sc| sc.is_called?(name) }
      end
      
      def has_subcommands!(default = nil)
        if @has_subcommands
          if default
            raise "You must declare the default_subcommand before any other subcommands"
          end
        else
          if default
            parameter "[SUBCOMMAND]", "subcommand name", :attribute_name => :subcommand_name, :default => default
          else
            parameter "SUBCOMMAND", "subcommand name", :attribute_name => :subcommand_name
          end
          parameter "[ARGS] ...", "subcommand arguments", :attribute_name => :subcommand_arguments
          @has_subcommands = true
        end
      end
      
      private
      
      def declare_subcommand(name, description, subcommand_class = self, &block)
        if block
          # generate a anonymous sub-class
          subcommand_class = Class.new(subcommand_class, &block)
        end
        recognised_subcommands << Subcommand.new(name, description, subcommand_class)
      end

    end

  end
end
