require 'spec_helper'
require 'stringio'

describe Clamp::Command, "with subcommands" do

  include OutputCapture

  it "delegates to sub-commands" do

    @command_class = Class.new(Clamp::Command) do

      subcommand "flip" do
        def execute
          puts "FLIPPED"
        end
      end

      subcommand "flop" do
        def execute
          puts "FLOPPED"
        end
      end
      
    end

    @command = @command_class.new("flipflop")
    
    @command.run("flip")
    stdout.should =~ /FLIPPED/
    
    @command.run("flop")
    stdout.should =~ /FLOPPED/
    
  end

end
