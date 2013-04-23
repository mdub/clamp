require 'clamp/subcommand/execution'

module Clamp
  class Subcommand

    module Parsing

      protected

      def parse_subcommand
        return false unless self.class.has_subcommands?
        self.extend(Subcommand::Execution)
      end

      private

      def default_subcommand_name
        self.class.default_subcommand || request_help
      end

      def find_subcommand(name)
        self.class.find_subcommand(name) ||
        signal_usage_error("No such sub-command '#{name}'")
      end

    end

  end
end
