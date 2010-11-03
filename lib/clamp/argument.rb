module Clamp
  
  class Argument < Struct.new(:name, :description)
    
    def help
      [name, description]
    end
    
  end
  
end
