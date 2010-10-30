require 'spec_helper'

describe Clop::Option do

  describe "simple" do
    
    before do
      @option = Clop::Option.new("--source", "URL", "Source of data")
    end
    
    describe "#attribute" do
      
      it "is derived by removing the leading dashes from the option name" do
        @option.attribute.should == "source"
      end
      
    end
    
    def help_string(part1, part2)
      sprintf("%-32s%s", part1, part2)
    end
    
    describe "#help" do

      it "combines option name, argument_type and description" do
        @option.help.should == help_string("--source URL", "Source of data")
      end
      
    end
    
  end
  
end
