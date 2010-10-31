require 'spec_helper'

describe Clop::Option do

  def help_string(part1, part2)
    sprintf("%-32s%s", part1, part2)
  end

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
        @option.help.should == help_string("--key-file FILE", "SSH identity")
      end

    end

  end

  describe "flag" do
    
    before do
      @option = Clop::Option.new("--verbose", :flag, "Blah blah blah")
    end

    describe "#help" do

      it "does not include argument_type" do
        @option.help.should == help_string("--verbose", "Blah blah blah")
      end

    end
    
  end
  
end