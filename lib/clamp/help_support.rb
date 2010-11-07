module Clamp

  class Argument < Struct.new(:name, :description)

    def help
      [name, description]
    end

  end

  module HelpSupport

    def declared_arguments
      @declared_arguments ||= []
    end

    def argument(name, description)
      declared_arguments << Argument.new(name, description)
    end

    def usage(usage)
      @declared_usage_descriptions ||= []
      @declared_usage_descriptions << usage
    end

    attr_reader :declared_usage_descriptions

    def derived_usage_description
      parts = declared_arguments.map { |a| a.name }
      parts.unshift("SUBCOMMAND") if has_subcommands?
      parts.unshift("[OPTIONS]") if has_options?
      parts.join(" ")
    end

    def usage_descriptions
      declared_usage_descriptions || [derived_usage_description]
    end

    def help(command_name)
      help = StringIO.new
      help.puts "Usage:"
      usage_descriptions.each_with_index do |usage, i|
        help.puts "    #{command_name} #{usage}".rstrip
      end
      detail_format = "    %-29s %s"
      unless declared_arguments.empty?
        help.puts "\nArguments:"
        declared_arguments.each do |argument|
          help.puts detail_format % argument.help
        end
      end
      unless recognised_subcommands.empty?
        help.puts "\nSubcommands:"
        recognised_subcommands.each do |subcommand|
          help.puts detail_format % subcommand.help
        end
      end
      if has_options?
        help.puts "\nOptions:"
        recognised_options.each do |option|
          help.puts detail_format % option.help
        end
      end
      help.string
    end

  end

end
