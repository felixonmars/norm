module Norm
  module Attribute
    module Loading

      def self.extended(klass)
        klass.reset_dispatch!
      end

      def load(object, *args)
        send @dispatch[object.class], object, *args
      rescue NoMethodError => e
        raise e if respond_to?(@dispatch[object.class], true)
        ancestor = object.class.ancestors.detect { |mod|
          respond_to?(@dispatch[mod], true)
        }
        unless ancestor
          raise(NoMethodError, "No loader for #{object.class}", e.backtrace)
        end
        @dispatch[object.class] = @dispatch[ancestor]
        retry
      end

      def reset_dispatch!
        @dispatch = Hash.new { |dispatch, klass|
          dispatch[klass] = "load_#{(klass.name || '').gsub('::', '_')}"
        }
      end

      private

      def inherited(klass)
        klass.reset_dispatch!
      end

      def noop(object, *args)
        object
      end

    end
  end
end
