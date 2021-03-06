class SizedList
  include Enumerable

  attr_reader :max_size

  # Basic Stats
  attr_accessor :enable_time_based_stats

  attr_reader :hits,
              :misses,
              :writes,
              :evictions,
              :last_time_between_evictions

  def initialize(max_size)
    @max_size = max_size
    @items = {}
    self.reset_stats
  end

  def reset_stats
    @hits = 0
    @misses = 0
    @writes = 0
    @evictions = 0
    @total_eviction_time = 0.0
    @last_time_between_evictions = 0.0
    @last_evicted_at = nil
  end

  def get(key)
    if value = @items[key]
      @hits += 1
      used! key
    else
      @misses += 1
    end
    value
  end
  alias [] get

  def set(key, value)
    @writes += 1 unless exist?(key)
    @items[key] = value
    if @items.size > @max_size
      @evicted = true
      remove_least_recently_used!
    else
      @evicted = false
    end
    used! key
    nil
  end
  alias []= set

  def delete(key)
    @items.delete key
  end

  def each
    @items.each do |k, v|
      yield v
    end
  end

  def size
    @items.size
  end

  def keys
    @items.keys
  end

  def values
    @items.values
  end

  def evicted?
    !! @evicted
  end

  def exist?(key)
    @items.has_key? key
  end
  alias exists? exist?

  def eviction_frequency
    return 0.0 unless @enable_time_based_stats && @evictions > 1
    @total_eviction_time / @evictions
  end

  private

  # Bump the specified k/v pair to the end of the list,
  # marking it as least-recently-used.
  def used!(key)
    @items[key] = @items.delete(key)
  end

  def remove_least_recently_used!
    @evictions += 1

    if @enable_time_based_stats
      now = Time.now
      if @last_evicted_at
        @last_time_between_evictions = now - @last_evicted_at
        @total_eviction_time += @last_time_between_evictions
      end
      @last_evicted_at = now
    end

    @items.delete @items.first[0]
  end
end
