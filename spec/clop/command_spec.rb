require 'spec_helper'
require 'stringio'

describe Clop::Command do

  before do
    $stdout = @out = StringIO.new
  end

  after do
    $stdout = STDOUT
  end

  def output
    @out.string
  end

  def self.given_command(name, &block)
    before do
      @command = Class.new(Clop::Command, &block).new(name)
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
        end.should raise_error(Clop::UsageError)
      end

    end

  end

  describe "#run" do

    before do
      @abc = %w(a b c)
      @command.run(@abc)
    end

    it "executes the #execute method" do
      output.should_not be_empty
    end

    it "provides access to the argument list" do
      output.should == @abc.inspect
    end

  end

  describe ".option" do

    before do
      @command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
    end

    it "declares option argument accessors" do
      @command.flavour.should == nil
      @command.flavour = "chocolate"
      @command.flavour.should == "chocolate"
    end

  end
  
  describe "with options" do

    before do
      @command.class.option "--flavour", "FLAVOUR", "Flavour of the month"
    end
    
    describe "#parse" do

      describe "with a value for the option" do

        before do
          @command.parse(%w(--flavour strawberry a b c))
        end

        it "extracts the option value" do
          @command.flavour.should == "strawberry"
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
          @command.parse(%w(-- --flavour strawberry))
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
      end

    end

  end

  describe "with a flag option declared" do

    given_command("hello") do

      option "--verbose", :flag, "Be heartier"

    end

    it "has a predicate reader" do
      @command.should respond_to(:verbose?)
    end

    it "does not have a non-predicate reader" do
      @command.should_not respond_to(:verbose)
    end

    it "defaults to false" do
      @command.should_not be_verbose
    end

    describe "#parse" do

      describe "with option" do

        before do
          @command.parse(%w(--verbose foo))
        end

        it "sets the option" do
          @command.should be_verbose
        end

        it "does not consume an argument" do
          @command.arguments.should == %w(foo)
        end

      end

    end

  end

  describe "with an option that has a block" do

    given_command("serve") do

      option "--port", "PORT", "Port to listen on" do |port|
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
          end.should raise_error(Clop::UsageError, /^option '--port': invalid value/)
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

end
