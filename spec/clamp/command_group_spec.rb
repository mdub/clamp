require 'spec_helper'
require 'stringio'

describe Clamp::Command do

  include OutputCapture

  def self.given_command(name, &block)
    before do
      @command = Class.new(Clamp::Command, &block).new(name)
    end
  end

  describe "with subcommands" do

    given_command "flipflop" do

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

    it "delegates to sub-commands" do

      @command.run(["flip"])
      stdout.should =~ /FLIPPED/

      @command.run(["flop"])
      stdout.should =~ /FLOPPED/

    end

    describe "#help" do
      
      it "lists subcommands" do
        @help = @command.help
        @help.should =~ /Subcommands:/
        @help.should =~ /flip +flip it/
        @help.should =~ /flop +flop it/
      end
      
    end
    
  end

  describe "with nested subcommands" do

    given_command "fubar" do

      subcommand "foo", "Foo!" do

        subcommand "bar", "Baaaa!" do
          def execute
            puts "FUBAR"
          end
        end

      end

    end

    it "delegates multiple levels" do
      @command.run(["foo", "bar"])
      stdout.should =~ /FUBAR/
    end

  end
  
  describe "each subcommand" do

    before do

      @command_class = Class.new(Clamp::Command) do

        option "--direction", "DIR", "which way"

        subcommand "walk", "step carefully in the appointed direction" do

          def execute
            if direction
              puts "walking #{direction}"
            else
              puts "wandering #{context[:default_direction]} by default"
            end
          end

        end

      end

      @command = @command_class.new("go", :default_direction => "south")

    end

    it "accepts parents options (specified after the subcommand)" do
      @command.run(["walk", "--direction", "north"])
      stdout.should =~ /walking north/
    end

    it "accepts parents options (specified before the subcommand)" do
      @command.run(["--direction", "north", "walk"])
      stdout.should =~ /walking north/
    end

    it "has access to command context" do
      @command.run(["walk"])
      stdout.should =~ /wandering south by default/
    end

  end

end
