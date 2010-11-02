require 'spec_helper'

describe Clop::Option do

  describe "with String argument" do

    before do
      @option = Clop::Option.new("--key-file", "FILE", "SSH identity")
    end

    it "has a long_switch" do
      @option.long_switch.should == "--key-file"
    end

    it "has an argument_type" do
      @option.argument_type.should == "FILE"
    end

    it "has a description" do
      @option.description.should == "SSH identity"
    end

    describe "#attribute_name" do

      it "is derived from the (long) switch" do
        @option.attribute_name.should == "key_file"
      end

      it "can be overridden" do
        @option = Clop::Option.new("--key-file", "FILE", "SSH identity", :attribute_name => "ssh_identity")
        @option.attribute_name.should == "ssh_identity"
      end

    end

    describe "#help" do

      it "combines switch, argument_type and description" do
        @option.help.should == ["--key-file FILE", "SSH identity"]
      end

    end

  end

  describe "flag" do
    
    before do
      @option = Clop::Option.new("--verbose", :flag, "Blah blah blah")
    end

    describe "#help" do

      it "excludes option argument" do
        @option.help.should == ["--verbose", "Blah blah blah"]
      end

    end
    
  end

  describe "negatable flag" do
    
    before do
      @option = Clop::Option.new("--[no-]force", :flag, "Force installation")
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
      @option = Clop::Option.new(["-k", "--key-file"], "FILE", "SSH identity")
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
  
end