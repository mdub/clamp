require 'clamp/subcommand'

module Clamp
  class Subcommand

    module Declaration

      def recognised_subcommands
        @recognised_subcommands ||= []
      end

      def subcommand(name, description, subcommand_class = self, &block)
        has_subcommands!
        if block
          # generate a anonymous sub-class
          subcommand_class = Class.new(subcommand_class, &block)
        end
        recognised_subcommands << Subcommand.new(name, description, subcommand_class)
      end

      def has_subcommands?
        !recognised_subcommands.empty?
      end

      def find_subcommand(name)
        recognised_subcommands.find { |sc| sc.is_called?(name) }
      end
      
      def has_subcommands!
        unless @has_subcommands
          parameter "[SUBCOMMAND]", "subcommand name", :attribute_name => :subcommand_name
          parameter "[ARGS] ...", "subcommand arguments", :attribute_name => :subcommand_arguments
          @has_subcommands = true
        end
      end

    end

  end
end
