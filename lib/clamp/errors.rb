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

  # specific usage exceptions
  class TooManyArgumentsError < UsageError; end

  class AttributeParseError < UsageError

    def initialize(message, command, switch, original_exception)
      super(message, command)
      @switch = switch
      @original_exception = original_exception
    end

    attr_reader :switch, :original_exception

  end

  class OptionParseError < AttributeParseError; end
  class ParameterParseError < AttributeParseError; end

  class EnvVariableParseError < UsageError

    def initialize(message, command, env_variable_name, original_exception)
      super(message, command)
      @env_variable_name = env_variable_name
      @original_exception = original_exception
    end

    attr_reader :env_variable_name, :original_exception

  end

  class RequiredOptionError < UsageError

    def initialize(message, command, option)
      super(message, command)
      @option = option
    end

    attr_reader :option

  end


  class UnrecognisedAttributeError < UsageError

    def initialize(message, command, attribute_name)
      super(message, command)
      @attribute_name = attribute_name
    end

    attr_reader :attribute_name

  end

  class UnrecognisedOptionError < UnrecognisedAttributeError; end
  class UnrecognisedSubcommandError < UnrecognisedAttributeError; end

  # raise to request usage help
  class HelpWanted < RuntimeError

    def initialize(command)
      super("I need help", command)
    end

  end

end
