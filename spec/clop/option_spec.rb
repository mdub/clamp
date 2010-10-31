require 'spec_helper'

describe Clop::Option do

  describe "with String argument" do

    before do
      @option = Clop::Option.new("--key-file", "FILE", "SSH identity")
    end

    it "has a switch" do
      @option.switch.should == "--key-file"
    end

    it "has an argument_type" do
      @option.argument_type.should == "FILE"
    end

    it "has a description" do
      @option.description.should == "SSH identity"
    end

    describe "#attribute" do

      it "is derived from the (long) switch" do
        @option.attribute.should == "key_file"
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

      it "does not include argument_type" do
        @option.help.should == ["--verbose", "Blah blah blah"]
      end

    end
    
  end
  
end