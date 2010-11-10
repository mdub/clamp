require 'spec_helper'

describe Clamp::Parameter do

  describe "normal" do

    before do
      @parameter = Clamp::Parameter.new("COLOR", "hue of choice")
    end

    it "has a name" do
      @parameter.name.should == "COLOR"
    end

    it "has a description" do
      @parameter.description.should == "hue of choice"
    end

    describe "#attribute_name" do

      it "is derived from the name" do
        @parameter.attribute_name.should == "color"
      end

      it "can be overridden" do
        @parameter = Clamp::Parameter.new("COLOR", "hue of choice", :attribute_name => "hue")
        @parameter.attribute_name.should == "hue"
      end

    end

    describe "#consume" do

      it "consumes one argument" do
        @arguments = %w(a b c)
        @parameter.consume(@arguments).should == "a"
        @arguments.should == %w(b c)
      end

      describe "with no arguments" do

        it "raises an Argument error" do
          @arguments = []
          lambda do
            @parameter.consume(@arguments)
          end.should raise_error(ArgumentError)
        end

      end

    end

  end

  describe "optional (name in square brackets)" do

    before do
      @parameter = Clamp::Parameter.new("[COLOR]", "hue of choice")
    end

    describe "#attribute_name" do

      it "omits the brackets" do
        @parameter.attribute_name.should == "color"
      end

    end

    describe "#consume" do

      it "consumes one argument" do
        @arguments = %w(a b c)
        @parameter.consume(@arguments).should == "a"
        @arguments.should == %w(b c)
      end

      describe "with no arguments" do

        it "returns nil" do
          @arguments = []
          @parameter.consume(@arguments).should == nil
        end

      end

    end

  end

  describe "list (name followed by ellipsis)" do

    before do
      @parameter = Clamp::Parameter.new("FILE ...", "files to process")
    end

    describe "#attribute_name" do

      it "indicates multiplicity" do
        @parameter.attribute_name.should == "file_list"
      end

    end

    describe "#consume" do

      it "consumes all the remaining arguments" do
        @arguments = %w(a b c)
        @parameter.consume(@arguments).should == %w(a b c)
        @arguments.should == []
      end

      describe "with no arguments" do

        it "raises an Argument error" do
          @arguments = []
          lambda do
            @parameter.consume(@arguments)
          end.should raise_error(ArgumentError)
        end

      end

    end
  end

end
