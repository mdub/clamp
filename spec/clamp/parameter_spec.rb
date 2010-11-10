require 'spec_helper'

describe Clamp::Parameter do

  describe "normal" do
    
    before do
      @argument = Clamp::Parameter.new("COLOR", "hue of choice")
    end

    it "has a name" do
      @argument.name.should == "COLOR"
    end

    it "has a description" do
      @argument.description.should == "hue of choice"
    end

    it "is required" do
      @argument.should be_required
    end
    
    describe "#attribute_name" do
      
      it "is derived from the name" do
        @argument.attribute_name.should == "color"
      end

      it "can be overridden" do
        @argument = Clamp::Parameter.new("COLOR", "hue of choice", :attribute_name => "hue")
        @argument.attribute_name.should == "hue"
      end
      
    end
    
  end

  describe "with name in square brackets" do
    
    before do
      @argument = Clamp::Parameter.new("[COLOR]", "hue of choice")
    end

    it "is optional" do
      @argument.should_not be_required
    end

    describe "#attribute_name" do
      
      it "omits the brackets" do
        @argument.attribute_name.should == "color"
      end

    end
    
  end
  
end
