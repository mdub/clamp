require 'spec_helper'

describe Clop::OptionHandler do

  before do
    @handler = Clop::OptionHandler.new("--source", "URL", "Source of data")
  end

  it "has an option" do
    @handler.option.should == "--source"
  end

  it "has an argument_type" do
    @handler.argument_type.should == "URL"
  end

  it "has a description" do
    @handler.description.should == "Source of data"
  end
  
  describe "#attribute" do

    it "is derived by removing the leading dashes from the option name" do
      @handler.attribute.should == "source"
    end

  end

  def help_string(part1, part2)
    sprintf("%-32s%s", part1, part2)
  end

  describe "#help" do

    it "combines option name, argument_type and description" do
      @handler.help.should == help_string("--source URL", "Source of data")
    end

  end

end
