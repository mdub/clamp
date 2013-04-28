module Clamp

  class DeclarationError < StandardError
  end

  class RuntimeError < StandardError

    def initialize(message, command)
      super(message)
      @command = command
    end

    attr_reader :command

  end

  # raise to signal incorrect command usage
  class UsageError < RuntimeError; end

  # raise to request usage help
  class HelpWanted < RuntimeError

    def initialize(command)
      super("I need help", command)
    end

  end

end
