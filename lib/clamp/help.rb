module Clamp

  module Help

    def usage(usage)
      @declared_usage_descriptions ||= []
      @declared_usage_descriptions << usage
    end

    attr_reader :declared_usage_descriptions

    def derived_usage_description
      parts = parameters.map { |a| a.name }
      parts.unshift("SUBCOMMAND") if has_subcommands?
      parts.unshift("[OPTIONS]") if has_options?
      parts.join(" ")
    end

    def usage_descriptions
      declared_usage_descriptions || [derived_usage_description]
    end

    def help(invocation_path)
      help = StringIO.new
      help.puts "Usage:"
      usage_descriptions.each_with_index do |usage, i|
        help.puts "    #{invocation_path} #{usage}".rstrip
      end
      detail_format = "    %-29s %s"
      if has_parameters?
        help.puts "\nParameters:"
        parameters.each do |parameter|
          help.puts detail_format % parameter.help
        end
      end
      if has_subcommands?
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
