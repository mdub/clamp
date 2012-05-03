require 'clamp/errors'
require 'clamp/help'
require 'clamp/option/declaration'
require 'clamp/option/parsing'
require 'clamp/parameter/declaration'
require 'clamp/parameter/parsing'
require 'clamp/subcommand/declaration'
require 'clamp/subcommand/parsing'

module Clamp

  # {Command} models a shell command.  Each command invocation is a new object.
  # Command options and parameters are represented as attributes
  # (see {Command::Declaration}).
  #
  # The main entry-point is {#run}, which uses {#parse} to populate attributes based
  # on an array of command-line arguments, then calls {#execute} (which you provide)
  # to make it go.
  #
  class Command

    # Create a command execution.
    #
    # @param [String] invocation_path the path used to invoke the command
    # @param [Hash] context additional data the command may need
    #
    def initialize(invocation_path, context = {})
      @invocation_path = invocation_path
      @context = context
    end

    # @return [String] the path used to invoke this command
    #
    attr_reader :invocation_path

    # @return [Array<String>] unconsumed command-line arguments
    #
    def remaining_arguments
      @remaining_arguments
    end

    # Parse command-line arguments.
    #
    # @param [Array<String>] arguments command-line arguments
    # @return [Array<String>] unconsumed arguments
    #
    def parse(arguments)
      @remaining_arguments = arguments.dup
      parse_environment_options
      parse_options
      parse_environment_parameters
      parse_parameters
      parse_subcommand
      handle_remaining_arguments
    end

    # Run the command, with the specified arguments.
    #
    # This calls {#parse} to process the command-line arguments,
    # then delegates to {#execute}.
    #
    # @param [Array<String>] arguments command-line arguments
    #
    def run(arguments)
      parse(arguments)
      execute
    end

    # Execute the command (assuming that all options/parameters have been set).
    #
    # This method is designed to be overridden in sub-classes.
    #
    def execute
      if @subcommand
        @subcommand.execute
      else
        raise "you need to define #execute"
      end
    end

    # @return [String] usage documentation for this command
    #
    def help
      self.class.help(invocation_path)
    end

    include Clamp::Option::Parsing
    include Clamp::Parameter::Parsing
    include Clamp::Subcommand::Parsing

    protected

    attr_accessor :context

    def handle_remaining_arguments
      unless remaining_arguments.empty?
        signal_usage_error "too many arguments"
      end
    end

    private

    def signal_usage_error(message)
      e = UsageError.new(message, self)
      e.set_backtrace(caller)
      raise e
    end

    def request_help
      raise HelpWanted, self
    end

    class << self

      include Clamp::Option::Declaration
      include Clamp::Parameter::Declaration
      include Clamp::Subcommand::Declaration
      include Help

      # Create an instance of this command class, and run it.
      #
      # @param [String] invocation_path the path used to invoke the command
      # @param [Array<String>] arguments command-line arguments
      # @param [Hash] context additional data the command may need
      #
      def run(invocation_path = File.basename($0), arguments = ARGV, context = {})
        begin
          new(invocation_path, context).run(arguments)
        rescue Clamp::UsageError => e
          $stderr.puts "ERROR: #{e.message}"
          $stderr.puts ""
          $stderr.puts "See: '#{e.command.invocation_path} --help'"
          exit(1)
        rescue Clamp::HelpWanted => e
          puts e.command.help
        end
      end

    end

  end

end
