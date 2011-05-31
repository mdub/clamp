require 'spec_helper'

describe Clamp::Command do

  extend CommandFactory
  include OutputCapture

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

  describe "with an aliased subcommand" do

    given_command "blah" do

      subcommand ["say", "talk"], "Say something" do

        parameter "WORD ...", "stuff to say"

        def execute
          puts word_list
        end

      end

    end

    it "responds to both aliases" do

      @command.run(["say", "boo"])
      stdout.should =~ /boo/

      @command.run(["talk", "jive"])
      stdout.should =~ /jive/

    end

    describe "#help" do

      it "lists all aliases" do
        @help = @command.help
        @help.should =~ /say, talk .* Say something/
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

  describe "with a default subcommand" do

    given_command "admin" do

      default_subcommand "status", "Show status" do

        def execute
          puts "All good!"
        end

      end

    end

    it "delegates multiple levels" do
      @command.run([])
      stdout.should =~ /All good/
    end

  end

  describe "each subcommand" do

    before do

      @command_class = Class.new(Clamp::Command) do

        option "--direction", "DIR", "which way", :default => "home"

        subcommand "move", "move in the appointed direction" do

          def execute
            motion = context[:motion] || "walking"
            puts "#{motion} #{direction}"
          end

        end

      end

      @command = @command_class.new("go")

    end

    it "accepts parents options (specified after the subcommand)" do
      @command.run(["move", "--direction", "north"])
      stdout.should =~ /walking north/
    end

    it "accepts parents options (specified before the subcommand)" do
      @command.run(["--direction", "north", "move"])
      stdout.should =~ /walking north/
    end

    it "has access to command context" do
      @command = @command_class.new("go", :motion => "wandering")
      @command.run(["move"])
      stdout.should =~ /wandering home/
    end

  end

  describe "each explicit subcommand" do

    before do
      class InitCommand < Clamp::Command

        def execute
          msg = "running init subcommand"
          msg = msg.upcase unless quiet?
          puts msg
        end

      end

      class MainCommand < Clamp::Command

        option "--quiet", :flag, "Don't print in upper case.", :default => false

        subcommand "init", "Initialize the repository", InitCommand

      end

      @command = MainCommand.new("git")
    end

    it "accepts subcommands" do
      @command.run(["init"])
      stdout.should =~ /RUNNING INIT SUBCOMMAND/
    end

    it "accepts parents options (specified after the subcommand)" do
      @command.run(["init", "--quiet"])
      stdout.should =~ /running init subcommand/
    end

    it "accepts parents options (specified before the subcommand)" do
      @command.run(["--quiet", "init"])
      stdout.should =~ /running init subcommand/
    end

  end
end
