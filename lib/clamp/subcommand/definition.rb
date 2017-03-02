module Clamp
  module Subcommand

    Definition = Struct.new(:name, :description, :subcommand_class) do

      def initialize(names, description, subcommand_definition)
        @names = Array(names)
        @description = description
        @subcommand_definition = subcommand_definition
      end

      attr_reader :names, :description

      def class_from_string(string)
        if RUBY_VERSION >= '2.0.0'
          Object.const_get(string)
        else
          parts = string.split('::')
          base = parts.shift
          parts.inject(Object.const_get(base)) { |new_base, part| new_base.const_get(part) }
        end
      end

      def subcommand_class
        if @subcommand_definition.kind_of?(Hash)
          klass, path = @subcommand_definition.first
          require(path)
          class_from_string(klass)
        elsif @subcommand_definition.respond_to?(:call)
          @subcommand_definition.call
        else
          @subcommand_definition
        end
      end

      def is_called?(name)
        names.member?(name)
      end

      def help
        [names.join(", "), description]
      end

    end

  end
end
