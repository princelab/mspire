
# taken from rails (will be in Ruby 1.9??)

module Enumerable
  def index_by
    inject({}) do |accum, elem|
      accum[yield(elem)] = elem
      accum
    end
  end
end
