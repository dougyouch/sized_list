class SizedList
  include Enumerable

  attr_reader :max_size

  def initialize(max_size)
    @max_size = max_size
    @used = []
    @items = {}
  end

  def get(key)
    if value = @items[key]
      used! key
    end
    value
  end
  alias [] get

  def set(key, value)
    @items[key] = value
    remove_least_recently_used! if @items.size > @max_size
    used! key
    nil
  end
  alias []= set

  def each
    @items.each do |k, v|
      yield v
    end
  end

  def size
    @items.size
  end

  def keys
    @used
  end

  def values
    @items.values
  end

  def exist?(key)
    @items.has_key? key
  end
  alias exists? exist?

  private

  def used!(key)
    if @used.first == key
      # no-op
    elsif @used.last == key
      @used.unshift @used.pop
    else
      @used.reject! { |k| k == key }
      @used.unshift key
    end
  end

  def remove_least_recently_used!
    key = @used.pop
    @items.delete key
  end
end
