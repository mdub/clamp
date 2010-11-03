module Clamp
  
  class Subcommand < Struct.new(:name, :description, :subcommand_class)

    def help
      [name, description]
    end

  end
  
end
