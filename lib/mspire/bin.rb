
module Mspire
  class Bin < Range
    attr_accessor :data

    def initialize(*args)
      super(*args)
      @data = []
    end

    def inspect
      "<(" + super + ") @data=#{data.inspect}>"
    end

    def <<(val)
      @data << val
    end

    # O(m + n) speed to bin objects.
    # bin objects must respond to === .
    # the object to bin must be a value that is sortable (< > ==), or you can
    # pass in a block to get the value.
    # bins and objects must be accessible by index (e.g., bins[11]).
    # if data_capture is given, it should be a parallel array to bins, and each
    # object should respond to the '<<' method.  Otherwise, the bins themselves
    # will be used to push data onto.
    #
    # Here's a simple example of binning x,y points where we want to bin the
    # points based on the x value:
    #
    #     bins = (0...10).map {|i| Mspire::Bin.new(i, i+1, false) }
    #     points = [[2.2, 100], [3.5, 200], [8.8, 150]]
    #
    #     Mspire::Bin.bin(bins, points) {|point| point.first }
    #     # --or--:     Mspire::Bin.bin(bins, points, &:first)
    #
    # An example where we want to use a separate data store:
    #
    #
    def self.bin(bins, objects, *data_capture_obj, &block)
      obj_e = objects.each ; obj = obj_e.next  

      data_capture = data_capture_obj.first || bins

      bin_i = 0  # the bin index
      cbin = bins[bin_i]  # the current bin
      done = false
      until done
        value = (block.nil? ? obj : block.call(obj))
        if cbin.begin <= value
          until cbin === value && data_capture[bin_i] << obj
            bin_i += 1
            cbin=bins[bin_i] || (done=true && break)
          end
          obj=obj_e.next rescue done=true
        else
          while cbin.begin > value && !done
            obj=obj_e.next rescue done=true && break
            value = (block.nil? ? obj : block.call(obj))
          end
        end
      end
      data_capture
    end

  end
end
