
class Bin < Range
  attr_accessor :data
  def initialize(*args)
    super(*args)
    @data = []
  end

  def inspect
    "<(" + super + ") @data=#{data.inspect}>"
  end

  # O(m + n) speed to bin objects.
  # bin objects must respond to === and bin.data must respond to '<<'
  # objs must respond to .value for binning
  # bins and objs must be accessible by index (e.g., bins[11])
  def self.bin!(bins, objs, &block)
    bin_e = bins.each ; obj_e = objs.each
    bin = bin_e.next  ; obj = obj_e.next

    done = false
    until done
      value = (block.nil? ? obj : block.call(obj))
      if bin.begin <= value
        until bin === value && bin.data << obj
          bin=bin_e.next rescue done=true && break
        end
        obj=obj_e.next rescue done=true
      else
        while bin.begin > value && !done
          obj=obj_e.next rescue done=true && break
          value = (block.nil? ? obj : block.call(obj))
        end
      end
    end
    bins
  end

end
