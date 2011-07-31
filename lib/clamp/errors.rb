module Clamp
  
  class Error < StandardError

    def initialize(message, command)
      super(message)
      @command = command
    end

    attr_reader :command

  end

  # raise to signal incorrect command usage
  class UsageError < Error; end

  # similar to UsageError, but triggers help before exiting
  class UsageErrorWithHelp < UsageError; end

  # raise to request usage help
  class HelpWanted < Error

    def initialize(command)
      super("I need help", command)
    end

  end
end
