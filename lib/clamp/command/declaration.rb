require 'clamp/option/declaration'
require 'clamp/positional_argument/declaration'
require 'clamp/subcommand/declaration'

module Clamp
  class Command
    
    module Declaration
      include Option::Declaration
      include PositionalArgument::Declaration
      include Subcommand::Declaration
    end

  end
end
