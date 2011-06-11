require 'spec_helper'

describe Clamp::Option do

  describe "with String argument" do

    before do
      @option = Clamp::Option.new("--key-file", "FILE", "SSH identity")
    end

    it "has a long_switch" do
      @option.long_switch.should == "--key-file"
    end

    it "has a type" do
      @option.type.should == "FILE"
    end

    it "has a description" do
      @option.description.should == "SSH identity"
    end

    describe "#attribute_name" do

      it "is derived from the (long) switch" do
        @option.attribute_name.should == "key_file"
      end

      it "can be overridden" do
        @option = Clamp::Option.new("--key-file", "FILE", "SSH identity", :attribute_name => "ssh_identity")
        @option.attribute_name.should == "ssh_identity"
      end

    end

    describe "#default_value" do

      it "defaults to nil" do
        @option.default_value.should == nil
      end

      it "can be overridden" do
        @option = Clamp::Option.new("-n", "N", "iterations", :default => 1)
        @option.default_value.should == 1
      end

    end

    describe "#help" do

      it "combines switch, type and description" do
        @option.help.should == ["--key-file FILE", "SSH identity"]
      end

    end

  end

  describe "flag" do
    
    before do
      @option = Clamp::Option.new("--verbose", :flag, "Blah blah blah")
    end

    describe "#help" do

      it "excludes option argument" do
        @option.help.should == ["--verbose", "Blah blah blah"]
      end

    end
    
  end

  describe "negatable flag" do
    
    before do
      @option = Clamp::Option.new("--[no-]force", :flag, "Force installation")
    end

    it "handles both positive and negative forms" do
      @option.handles?("--force").should be_true
      @option.handles?("--no-force").should be_true
    end

    describe "#flag_value" do

      it "returns true for the positive variant" do
        @option.flag_value("--force").should be_true
        @option.flag_value("--no-force").should be_false
      end

    end
    
    describe "#attribute_name" do

      it "is derived from the (long) switch" do
        @option.attribute_name.should == "force"
      end

    end
    
  end

  describe "with both short and long switches" do

    before do
      @option = Clamp::Option.new(["-k", "--key-file"], "FILE", "SSH identity")
    end

    it "handles both switches" do
      @option.handles?("--key-file").should be_true
      @option.handles?("-k").should be_true
    end

    describe "#help" do

      it "includes both switches" do
        @option.help.should == ["-k, --key-file FILE", "SSH identity"]
      end

    end

  end

  describe "in subcommand" do
    before do

      @command = Class.new(Clamp::Command) do
        subcommand "foo", "FOO!" do
          option "--bar", "BAR", "Bars foo."
        end
      end

    end

    describe "Command#help" do

      it "includes help for each option exactly once" do
        subcommand = @command.new("").send(:find_subcommand, 'foo')
        subcommand_help = subcommand.subcommand_class.help("")
        subcommand_help.lines.grep(/--bar BAR/).count.should == 1
      end

    end

  end
  
end
