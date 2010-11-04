require 'spec_helper'
require 'stringio'

describe Clamp::Command do

  include OutputCapture

  def self.given_command(name, &block)
    before do
      @command = Class.new(Clamp::Command, &block).new(name)
    end
  end

  given_command("cmd") do

    def execute
      print arguments.inspect
    end

  end

  describe "#help" do

    it "describes usage" do
      @command.help.should include("Usage:\n    cmd\n")
    end

  end

  describe "#parse" do

    it "sets arguments" do
      @command.parse(%w(a b c))
      @command.arguments.should == %w(a b c)
    end

    describe "with an unrecognised option" do

      it "raises a UsageError" do
        lambda do
          @command.parse(%w(--foo bar))
        end.should raise_error(Clamp::UsageError)
      end

    end

  end

  describe "#run" do

    before do
      @abc = %w(a b c)
      @command.run(@abc)
    end

    it "executes the #execute method" do
      stdout.should_not be_empty
    end

    it "provides access to the argument list" do
      stdout.should == @abc.inspect
    end

  end

  describe ".option" do

    it "declares option argument accessors" do
      @command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
      @command.flavour.should == nil
      @command.flavour = "chocolate"
      @command.flavour.should == "chocolate"
    end

    describe "with explicit :attribute_name" do

      before do
        @command.class.option "--foo", "FOO", "A foo", :attribute_name => :bar
      end

      it "uses the specified attribute_name name to name accessors" do
        @command.bar = "chocolate"
        @command.bar.should == "chocolate"
      end

      it "does not attempt to create the default accessors" do
        @command.should_not respond_to(:foo)
        @command.should_not respond_to(:foo=)
      end

    end

    describe "with :default value" do

      given_command("cmd") do
        option "--nodes", "N", "number of nodes", :default => 2
      end

      it "sets the specified default value" do
        @command.nodes.should == 2
      end

    end

  end

  describe "with options declared" do

    before do
      @command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
      @command.class.option "--color", "COLOR", "Preferred hue"
    end

    describe "#parse" do

      describe "with options" do

        before do
          @command.parse(%w(--flavour strawberry --color blue a b c))
        end

        it "extracts the option values" do
          @command.flavour.should == "strawberry"
          @command.color.should == "blue"
        end

        it "retains unconsumed arguments" do
          @command.arguments.should == %w(a b c)
        end

      end

      describe "with option-like things beyond the arguments" do

        it "treats them as positional arguments" do
          @command.parse(%w(a b c --flavour strawberry))
          @command.arguments.should == %w(a b c --flavour strawberry)
        end

      end

      describe "with an option terminator" do

        it "considers everything after the terminator to be an argument" do
          @command.parse(%w(--color blue -- --flavour strawberry))
          @command.arguments.should == %w(--flavour strawberry)
        end

      end

    end

    describe "#help" do

      it "indicates that there are options" do
        @command.help.should include("cmd [OPTIONS]")
      end

      it "includes option details" do
        @command.help.should =~ %r(--flavour FLAVOUR +Flavour of the month)
        @command.help.should =~ %r(--color COLOR +Preferred hue)
      end

    end

  end

  describe "with a flag option declared" do

    before do
      @command.class.option "--verbose", :flag, "Be heartier"
    end

    it "declares a predicate-style reader" do
      @command.should respond_to(:verbose?)
      @command.should_not respond_to(:verbose)
    end

    describe "#parse" do

      describe "with option" do

        before do
          @command.parse(%w(--verbose foo))
        end

        it "sets the flag" do
          @command.should be_verbose
        end

        it "does not consume an argument" do
          @command.arguments.should == %w(foo)
        end

      end

    end

  end

  describe "with a negatable flag option declared" do

    before do
      @command.class.option "--[no-]sync", :flag, "Synchronise"
    end

    describe "#parse" do

      describe "with --flag" do

        before do
          @command.parse(%w(--sync))
        end

        it "sets the flag" do
          @command.sync?.should be_true
        end

      end

      describe "with --no-flag" do

        before do
          @command.sync = true
          @command.parse(%w(--no-sync))
        end

        it "clears the flag" do
          @command.sync?.should be_false
        end

      end

    end

  end

  describe ".option, with a block" do

    before do
      @command.class.option "--port", "PORT", "Port to listen on" do |port|
        Integer(port)
      end
    end

    it "uses the block to validate and convert the option argument" do
      lambda do
        @command.port = "blah"
      end.should raise_error(ArgumentError)
      @command.port = "1234"
      @command.port.should == 1234
    end

    describe "#parse" do

      describe "with a valid option argument" do

        it "stores the converted value" do
          @command.parse(%w(--port 4321))
          @command.port.should == 4321
        end

      end

      describe "with an invalid option argument" do

        it "raises a UsageError" do
          lambda do
            @command.parse(%w(--port blah))
          end.should raise_error(Clamp::UsageError, /^option '--port': invalid value/)
        end

      end

    end

  end

  describe "with explicit usage" do

    given_command("blah") do

      usage "FOO BAR ..."

    end

    describe "#help" do

      it "includes the explicit usage" do
        @command.help.should include("blah FOO BAR ...\n")
      end

    end

  end

  describe "with multiple usages" do

    given_command("put") do

      usage "THIS HERE"
      usage "THAT THERE"

    end

    describe "#help" do

      it "includes both potential usages" do
        @command.help.should include("put THIS HERE\n")
        @command.help.should include("put THAT THERE\n")
      end

    end

  end

  describe ".run" do

    it "creates a new Command instance and runs it" do
      @xyz = %w(x y z)
      @command.class.run("cmd", @xyz)
      stdout.should == @xyz.inspect
    end

    describe "invoked with a context hash" do
      
      it "makes the context available within the command" do
        @command.class.class_eval do
          def execute
            print context[:foo]
          end
        end
        @command.class.run("xyz", [], :foo => "bar")
        stdout.should == "bar"        
      end
      
    end
    
    describe "when there's a UsageError" do

      before do

        @command.class.class_eval do
          def execute
            signal_usage_error "bad dog!"
          end
        end

        begin 
          @command.class.run("cmd", [])
        rescue SystemExit => e
          @system_exit = e
        end

      end

      it "outputs the error message" do
        stderr.should include "ERROR: bad dog!"
      end

      it "outputs help" do
        stderr.should include "Usage:"
      end

      it "exits with a non-zero status" do
        @system_exit.should_not be_nil
        @system_exit.status.should == 1
      end

    end

    describe "when help is requested" do

      it "outputs help" do
        @command.class.run("cmd", ["--help"])
        stdout.should include "Usage:"
      end

    end

  end

end
