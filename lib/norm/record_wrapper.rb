module Norm
  class RecordWrapper

    def initialize(record_class, wrapper, *args)
      @record_class = record_class
      @wrapper      = wrapper
      @args         = args
    end

    def load_attribute(name, value)
      @record_class.load_attribute(name, value)
    end

    def new(attributes = {})
      @wrapper.new(@record_class.new(attributes), *@args)
    end

    def from_repo(attributes)
      new(attributes).tap { |record| record.stored! }
    end

  end
end
