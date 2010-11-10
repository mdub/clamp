require 'spec_helper'

describe Clamp::Argument do

  describe "normal" do
    
    before do
      @argument = Clamp::Argument.new("COLOR", "hue of choice")
    end

    it "has a name" do
      @argument.name.should == "COLOR"
    end

    it "has a description" do
      @argument.description.should == "hue of choice"
    end
    
    describe "#attribute_name" do
      
      it "is derived from the name" do
        @argument.attribute_name.should == "color"
      end

      it "can be overridden" do
        @argument = Clamp::Argument.new("COLOR", "hue of choice", :attribute_name => "hue")
        @argument.attribute_name.should == "hue"
      end
      
    end
    
  end
  
end
