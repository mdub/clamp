require 'clamp/subcommand'

module Clamp
  class Subcommand

    module Declaration

      def recognised_subcommands
        @recognised_subcommands ||= []
      end

      def subcommand(name, description, subcommand_class = self, &block)
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

      attr_writer :default_subcommand

      def default_subcommand(*args)
        unless args.empty?
          raise "Sorry, default_subcommand syntax has changed; check the README."
        end
        @default_subcommand
      end

    end

  end
end
