module Clamp

  class Argument < Struct.new(:name, :description)

    def help
      [name, description]
    end

    def attribute_name
      @attribute_name ||= name.downcase.tr('-', '_')
    end

    def default_value
      nil
    end

    def flag?
      false
    end

  end

end
