require 'arrayclass'
require 'ms/precursor'

module MS ; end

#                               0   1        2    3        4      5          6 
MS::Scan = Arrayclass.new( %w(num ms_level time start_mz end_mz precursor spectrum) )

# time in seconds
# everything else in float/int

class MS::Scan
  #@@order = %w(num ms_level time start_mz end_mz prec_mz prec_inten parent spectrum)
  #attr_accessor :num, :ms_level, :time, :start_mz, :end_mz, :prec_mz, :prec_inten, :parent, :spectrum

  #def initialize(ar=nil)
  # @@order.zip(ar) do |x,v|
  #   send((x+'=').to_sym, v)
  # end
  #end

  def to_s
    "<Scan num=#{num} ms_level=#{ms_level} time=#{time}>"
  end

  undef_method :inspect
  def inspect
    atts = %w(num ms_level time start_mz end_mz) 
    display = atts.map do |att|
      if val = send(att.to_sym)
        "#{att}=#{val}"
      else
        nil
      end
    end
    display.compact!
    spec_display = 
      if spectrum
        spectrum.mzs.size
      else
        'nil'
      end
    "<MS::Scan:#{__id__} " + display.join(", ") + " precursor=#{precursor.inspect}" + " spectrum(size)=#{spec_display}" + " >"
  end

  # returns the string (space delimited): "ms_level num time [prec_mz prec_inten]"
  def to_index_file_string
    arr = [ms_level, num, time]
    if precursor then arr << precursor.mz end
    if x = precursor.intensity then arr << x end
    arr.join(" ")
  end

  # adds the attribute parent to each scan with a parent
  # (level 1 = no parent; level 2 = prev level 1, etc.
  def self.add_parent_scan(scans)
    prev_scan = nil
    parent_stack = [nil]
    ## we want to set the level to be the first mslevel we come to
    prev_level = 1
    scans.each do |scan|
      if scan then prev_level = scan.ms_level; break; end
    end
    scans.each do |scan|
      next unless scan  ## the first one is nil, (others?)
      level = scan.ms_level
      if prev_level < level
        parent_stack.unshift prev_scan
      end
      if prev_level > level
        (prev_level - level).times do parent_stack.shift end
      end
      scan.parent = parent_stack.first
      prev_level = level
      prev_scan = scan
    end
  end

end


