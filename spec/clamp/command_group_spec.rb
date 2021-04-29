# frozen_string_literal: true

require "spec_helper"

describe Clamp::Command do

  extend CommandFactory
  include OutputCapture

  context "with subcommands" do

    given_command "flipflop" do

      def execute
        puts message
      end

      subcommand "flip", "flip it" do
        def message
          "FLIPPED"
        end
      end

      subcommand "flop", "flop it\nfor extra flop" do
        def message
          "FLOPPED"
        end
      end

    end

    describe "flip command" do
      before do
        command.run(["flip"])
      end

      it "delegates to sub-commands" do
        expect(stdout).to match(/FLIPPED/)
      end
    end

    describe "flop command" do
      before do
        command.run(["flop"])
      end

      it "delegates to sub-commands" do
        expect(stdout).to match(/FLOPPED/)
      end
    end

    context "when executed with no subcommand" do

      it "triggers help" do
        expect do
          command.run([])
        end.to raise_error(Clamp::HelpWanted)
      end

    end

    describe "#help" do

      it "shows subcommand parameters in usage" do
        expect(command.help).to include("flipflop [OPTIONS] SUBCOMMAND [ARG] ...")
      end

      it "lists subcommands" do
        expect(command.help).to match(/Subcommands:\n +flip +flip it\n +flop +flop it/)
      end

      it "handles new lines in subcommand descriptions" do
        expect(command.help).to match(/flop +flop it\n +for extra flop/)
      end

    end

    describe ".find_subcommand_class" do

      it "finds subcommand classes" do
        flip_class = command_class.find_subcommand_class("flip")
        expect(flip_class.new("xx").message).to eq("FLIPPED")
      end

    end

  end

  context "with an aliased subcommand" do

    given_command "blah" do

      subcommand ["say", "talk"], "Say something" do

        parameter "WORD ...", "stuff to say"

        def execute
          puts word_list
        end

      end

    end

    describe "the first alias" do

      before do
        command.run(["say", "boo"])
      end

      it "responds to it" do
        expect(stdout).to match(/boo/)
      end

    end

    describe "the second alias" do

      before do
        command.run(["talk", "jive"])
      end

      it "responds to it" do
        expect(stdout).to match(/jive/)
      end

    end

    describe "#help" do

      it "lists all aliases" do
        help = command.help
        expect(help).to match(/say, talk .* Say something/)
      end

    end

  end

  context "with nested subcommands" do

    given_command "fubar" do

      subcommand "foo", "Foo!" do

        subcommand "bar", "Baaaa!" do

          def self.this_is_bar; end

          def execute
            puts "FUBAR"
          end

        end

      end

    end

    it "delegates multiple levels" do
      command.run(["foo", "bar"])
      expect(stdout).to match(/FUBAR/)
    end

    describe ".find_subcommand_class" do

      it "finds nested subcommands" do
        expect(command_class.find_subcommand_class("foo", "bar")).to respond_to(:this_is_bar)
      end

    end

  end

  context "with a default subcommand" do

    given_command "admin" do

      self.default_subcommand = "status"

      subcommand "status", "Show status" do

        def execute
          puts "All good!"
        end

      end

    end

    context "when executed with no subcommand" do

      it "invokes the default subcommand" do
        command.run([])
        expect(stdout).to match(/All good/)
      end

    end

  end

  context "with a default subcommand, declared the old way" do

    given_command "admin" do

      default_subcommand "status", "Show status" do

        def execute
          puts "All good!"
        end

      end

    end

    context "when executed with no subcommand" do

      it "invokes the default subcommand" do
        command.run([])
        expect(stdout).to match(/All good/)
      end

    end

  end

  context "when declaring a default subcommand after subcommands" do

    let(:command) do
      Class.new(Clamp::Command) do

        subcommand "status", "Show status" do

          def execute
            puts "All good!"
          end

        end

      end
    end

    it "is not supported" do

      expect do
        command.default_subcommand = "status"
      end.to raise_error(/default_subcommand must be defined before subcommands/)

    end

  end

  context "with subcommands, declared after a parameter" do

    given_command "with" do

      parameter "THING", "the thing"

      subcommand "spit", "spit it" do
        def execute
          puts "spat the #{thing}"
        end
      end

      subcommand "say", "say it" do
        subcommand "loud", "yell it" do
          def execute
            puts thing.upcase
          end
        end
      end

    end

    it "allows the parameter to be specified first" do
      command.run(["dummy", "spit"])
      expect(stdout.strip).to eq "spat the dummy"
    end

    it "passes the parameter down the stack" do
      command.run(["money", "say", "loud"])
      expect(stdout.strip).to eq "MONEY"
    end

    it "shows parameter in usage help" do
      command.run(["stuff", "say", "loud", "--help"])
    rescue Clamp::HelpWanted => e
      expect(e.command.invocation_path).to eq "with THING say loud"
    end

  end

  describe "each subcommand" do

    let(:command_class) do

      speed_options = Module.new do
        extend Clamp::Option::Declaration
        option "--speed", "SPEED", "how fast", default: "slowly"
      end

      Class.new(Clamp::Command) do

        option "--direction", "DIR", "which way", default: "home"

        include speed_options

        subcommand "move", "move in the appointed direction" do

          def execute
            motion = context[:motion] || "walking"
            puts "#{motion} #{direction} #{speed}"
          end

        end

      end
    end

    let(:command) do
      command_class.new("go")
    end

    it "accepts options defined in superclass (specified after the subcommand)" do
      command.run(["move", "--direction", "north"])
      expect(stdout).to match(/walking north/)
    end

    it "accepts options defined in superclass (specified before the subcommand)" do
      command.run(["--direction", "north", "move"])
      expect(stdout).to match(/walking north/)
    end

    it "accepts options defined in included modules" do
      command.run(["move", "--speed", "very quickly"])
      expect(stdout).to match(/walking home very quickly/)
    end

    it "has access to command context" do
      command = command_class.new("go", motion: "wandering")
      command.run(["move"])
      expect(stdout).to match(/wandering home/)
    end

  end

  context "with a subcommand, with options" do

    given_command "weeheehee" do
      option "--json", "JSON", "a json blob" do |option|
        print "parsing!"
        option
      end

      subcommand "woohoohoo", "like weeheehee but with more o" do
        def execute; end
      end
    end

    it "only parses options once" do
      command.run(["--json", '{"a":"b"}', "woohoohoo"])
      expect(stdout).to eq "parsing!"
    end

  end

  context "with an unknown subcommand" do

    let(:subcommand_missing) do
      Module.new do
        def subcommand_missing(_name)
          abort "there is no such thing"
        end
      end
    end

    let(:subcommand_missing_with_return) do
      Module.new do
        def subcommand_missing(_name)
          self.class.recognised_subcommands.first.subcommand_class
        end
      end
    end

    let(:command_class) do

      Class.new(Clamp::Command) do
        subcommand "test", "test subcommand" do
          def execute
            puts "known subcommand"
          end
        end

        def execute; end
      end
    end

    let(:command) do
      command_class.new("foo")
    end

    it "signals no such subcommand usage error" do
      expect { command.run(["foo"]) }.to raise_error(Clamp::UsageError, "No such sub-command 'foo'")
    end

    it "executes the subcommand missing method" do
      command.extend subcommand_missing
      expect { command.run(["foo"]) }.to raise_error(SystemExit, /there is no such thing/)
    end

    it "uses the subcommand class returned from subcommand_missing" do
      command.extend subcommand_missing_with_return
      command.run(["foo"])
      expect(stdout).to match(/known subcommand/)
    end

  end

  context "with a subcommand and required options" do

    given_command "movements" do
      option "--direction", "N|S|E|W", "bearing", required: true
      subcommand "hop", "Hop" do
        def execute
          puts "Hopping #{direction}"
        end
      end
    end

    it "allows options after the subcommand" do
      command.run(%w[hop --direction south])
      expect(stdout).to eq "Hopping south\n"
    end

  end

end
