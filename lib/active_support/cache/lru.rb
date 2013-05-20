# Most of the logic here was based on the dalli gem
module ActiveSupport
  module Cache
    class Lru
      attr_reader :silence, :options
      alias_method :silence?, :silence

      def initialize(options)
        @options = options
        @sized_list = SizedList.new @options[:max_size]
      end

      # Silence the logger.
      def silence!
        @silence = true
        self
      end

      # Silence the logger within a block.
      def mute
        previous_silence, @silence = defined?(@silence) && @silence, true
        yield
      ensure
        @silence = previous_silence
      end

      def fetch(name, options=nil)
        if block_given?
          entry = instrument(:read, name, options) do |payload|
            payload[:super_operation] = :fetch if payload
            read(name, options)
          end

          if !entry.nil?
            instrument(:fetch_hit, name, options) { |payload| }
            entry
          else
            result = instrument(:generate, name, options) do |payload|
              yield
            end
            write(name, result, options)
            result
          end
        else
          read(name, options)
        end
      end

      def read(name, options=nil)
        instrument(:read, name, options) do |payload|
          entry = @sized_list[name]
          payload[:hit] = !!entry if payload
          entry
        end
      end

      def write(name, value, options=nil)
        instrument(:write, name, options) do |payload|
          @sized_list[name] = value
        end
      end

      def exist?(name, options=nil)
        @sized_list.exist? name
      end

      def delete(name, options=nil)
        raise 'not implemented'
      end

      def read_multi(*names)
        {}.tap do |results|
          names.each do |n|
            if v = @sized_list[n]
              results[n] = v
            end
          end
        end
      end

      def increment(name, amount = 1, options=nil)
        if v = @sized_list[name]
          @sized_list[name] = v + amount
        end
      end

      def decrement(name, amount = 1, options=nil)
        if v = @sized_list[name]
          @sized_list[name] = v - amount
        end
      end

      def reset
        @sized_list = SizedList.new @options[:max_size]
      end
      alias clear reset

      protected

      def instrument(operation, key, options=nil)
        log(operation, key, options)

        if ActiveSupport::Cache::Store.instrument
          payload = { :key => key }
          payload.merge!(options) if options.is_a?(Hash)
          ActiveSupport::Notifications.instrument("cache_#{operation}.active_support", payload){ yield(payload) }
        else
          yield(nil)
        end
      end

      def log(operation, key, options=nil)
        return unless logger && logger.debug? && !silence?
        logger.debug("Cache #{operation}: #{key}#{options.blank? ? "" : " (#{options.inspect})"}")
      end

      def logger
        Rails.logger
      end
    end
  end
end
