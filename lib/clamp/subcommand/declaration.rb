module Clamp

  class Subcommand < Struct.new(:name, :description, :subcommand_class)

    def help
      [name, description]
    end

    module Declaration

      def recognised_subcommands
        @recognised_subcommands ||= []
      end

      def subcommand(name, description, subcommand_class = self, &block)
        has_subcommands!
        if block
          # generate a anonymous sub-class
          subcommand_class = Class.new(subcommand_class, &block)
        end
        recognised_subcommands << Subcommand.new(name, description, subcommand_class)
      end

      def has_subcommands?
        !recognised_subcommands.empty?
      end

      def find_subcommand(name)
        recognised_subcommands.find { |sc| sc.name == name }
      end
      
      def has_subcommands!
        unless method_defined?(:subcommand_name)
          parameter "SUBCOMMAND", "subcommand name", :attribute_name => :subcommand_name
          parameter "[ARGS] ...", "subcommand arguments", :attribute_name => :subcommand_arguments
        end
      end

    end

  end

end
