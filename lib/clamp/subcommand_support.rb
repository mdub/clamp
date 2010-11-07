module Clamp

  class Subcommand < Struct.new(:name, :description, :subcommand_class)

    def help
      [name, description]
    end

  end

  module SubcommandSupport

    def recognised_subcommands
      @recognised_subcommands ||= []
    end

    def subcommand(name, description, subcommand_class = nil, &block)
      if block
        if subcommand_class
          raise "no sense providing a subcommand_class AND a block"
        else
          subcommand_class = Class.new(Command, &block)
        end
      end
      recognised_subcommands << Subcommand.new(name, description, subcommand_class)
    end

    def has_subcommands?
      !recognised_subcommands.empty?
    end

    def find_subcommand(name)
      recognised_subcommands.find { |sc| sc.name == name }
    end

  end

end
