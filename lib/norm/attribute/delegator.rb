module Norm
  module Attribute
    class Delegator

      def initialize(delegate, *args)
        @delegate, @args = delegate, args
      end

      def load(object, *args)
        @delegate.load(object, *@args, *args)
      end

    end
  end
end
