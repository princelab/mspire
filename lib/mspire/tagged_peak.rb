
module Mspire
  # A TaggedPeak has a sample_id attribute.  In the rest of its interface it
  # behaves like a normal Mspire::Peak.  There are no forward compatible
  # guarantees if you use the array interface, but currently the TaggedPeak is
  # arranged internally like this:
  #
  #   [x, sample_id, y]
  #
  # Note that the object is instantiated like this:
  #
  #   TaggedPeak.new( [x,y], sample_id )
  #
  # x and y value access are very fast because they are merely aliases against
  # first and last.
  class TaggedPeak < Array
    # the m/z or x value
    alias_method :x, :first
    # the intensity or y value
    alias_method :y, :last

    def x=(val)
      self[0] = val
    end

    def y=(val)
      self[2] = val
    end

    def initialize(data, sample_id)
      self[0] = data.first
      self[1] = sample_id
      self[2] = data.last
    end

    def sample_id
      self[1]
    end

    def sample_id=(val)
      self[1] = val
    end
  end
end
