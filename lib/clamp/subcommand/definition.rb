module Clamp
  module Subcommand

    class Definition < Struct.new(:name, :description, :subcommand_class)

      def initialize(names, description, subcommand_definition)
        @names = Array(names)
        @description = description
        @subcommand_definition = subcommand_definition
      end

      attr_reader :names, :description

      def subcommand_class
        if @subcommand_definition.kind_of?(Hash)
          klass, path = @subcommand_definition.first
          require(path)
          Object.const_get(klass)
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
