require 'spec_helper'
require 'stringio'

describe Clamp::Command, "with subcommands" do

  include OutputCapture

  it "delegates to sub-commands" do

    @command_class = Class.new(Clamp::Command) do

      subcommand "flip", "flip it" do
        def execute
          puts "FLIPPED"
        end
      end

      subcommand "flop", "flop it" do
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

  it "has access to parent command state" do

    @command_class = Class.new(Clamp::Command) do

      option "--direction", "DIR", "which way"

      subcommand "walk", "step carefully in the appointed direction" do
        
        def execute
          puts "walking #{parent_command.direction}"
        end
        
      end

    end

    @command_class.new("go").run(["--direction", "north", "walk"])

    stdout.should =~ /walking north/

  end

end
