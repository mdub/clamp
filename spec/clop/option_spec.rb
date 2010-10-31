require 'spec_helper'

describe Clop::Option do

  def help_string(part1, part2)
    sprintf("%-32s%s", part1, part2)
  end

  describe "with String argument" do

    before do
      @option = Clop::Option.new("--source", "URL", "Source of data")
    end

    it "has a switch" do
      @option.switch.should == "--source"
    end

    it "has an argument_type" do
      @option.argument_type.should == "URL"
    end

    it "has a description" do
      @option.description.should == "Source of data"
    end

    it "requires an argument" do
      @option.requires_argument?.should == true
    end
    
    describe "#attribute" do

      it "is derived by removing the leading dashes from the option name" do
        @option.attribute.should == "source"
      end

    end

    describe "#help" do

      it "combines switch, argument_type and description" do
        @option.help.should == help_string("--source URL", "Source of data")
      end

    end

  end

  describe "flag" do
    
    before do
      @option = Clop::Option.new("--verbose", :flag, "Blah blah blah")
    end

    it "does not require an argument" do
      @option.requires_argument?.should be_false
    end

    describe "#help" do

      it "does not include argument_type" do
        @option.help.should == help_string("--verbose", "Blah blah blah")
      end

    end
    
  end
  
end