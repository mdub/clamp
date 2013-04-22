module Clamp
  class Subcommand

    module Execution

      # override default Command behaviour

      def execute
        # delegate to subcommand
        @subcommand.run(subcommand_arguments)
      end

      private

      def handle_remaining_arguments
        # no-op, because subcommand will handle them
      end

    end

  end
end
