module Clamp
  class Subcommand

    module Execution

      # override default Command behaviour

      def execute
        # delegate to subcommand
        @subcommand.run(remaining_arguments)
      end

      def handle_remaining_arguments
        # no-op, because subcommand will handle them
      end

    end

  end
end
