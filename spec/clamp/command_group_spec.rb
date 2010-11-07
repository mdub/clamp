require 'spec_helper'
require 'stringio'

describe Clamp::Command do

  include OutputCapture

  describe "with subcommands" do

    before do
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
    end

    it "delegates to sub-commands" do

      @command_class.run("flipflop", ["flip"])
      stdout.should =~ /FLIPPED/

      @command_class.run("flipflop", ["flop"])
      stdout.should =~ /FLOPPED/

    end

    describe "#help" do

      it "lists subcommands" do
        @help = @command_class.new("flipflop").help
        @help.should =~ /Subcommands:/
        @help.should =~ /flip +flip it/
        @help.should =~ /flop +flop it/
      end

    end

  end

  describe "each subcommand" do

    before do
      @command_class = Class.new(Clamp::Command) do

        option "--direction", "DIR", "which way"

        subcommand "walk", "step carefully in the appointed direction" do

          def execute
            puts "walking #{direction}"
          end

        end

      end
    end

    it "accepts parent's options (specified after the subcommand)" do
      @command_class.run("go", ["walk", "--direction", "north"])
      stdout.should =~ /walking north/
    end

    it "has access to command context" do

      @command_class.class_eval do
        def execute
          puts "walking #{context[:direction]}"
        end
      end

      @command_class.run("go", ["walk"], :direction => "south")
      stdout.should =~ /walking south/

    end

  end

end
