
require 'ms/scan'
require 'ms/parser'
require 'ms/msrun_index'
require 'ms/converter/mzxml'

#require 'ms/parser/mzxml'
#require 'ms/parser/mzdata'

module MS; end
class MS::MSRun

  MSRunDefaultOpts = { :lazy => :string }
 
  attr_accessor :start_time, :end_time
  attr_accessor :scans
  # (just for reference) the type of file this is (as symbol)
  attr_accessor :filetype
  # (just for reference) the version string of this type of file
  attr_accessor :version
  # the total number of scans
  attr_writer :scan_count


  #### # [note: precursor intensities not guaranteed to exist unless :
  # TODO: may need to eliminate unavailable precursor intensities if they
  # doing lazy evaluation??  or it becomes lazy too??

  # OPTIONS:
  #   :lazy => :string | :not | :no_spectra | :io
  #            :string = (default) stores each spectrum as a base64 decoded
  #            string that is further processed into Arrays of Floats when m/z
  #            or intensity information is access.  This lazy evaluation
  #            should work on most files.
  #            :not = all information is read into memory and parsed into
  #            objects.  Should only be used for small-medium files (< 80MB on
  #            a machine with 2GB memory)
  #            :no_spectra = if no peak information is required use this to
  #            avoid the overhead of parsing and creating spectra.
  #            :io = stores the io object and indices into spectrum data.
  #            When spectral information is requested (m/z or intensity
  #            information) then the spectrum is read from the io object and
  #            evaluated (requires an open io object when spectrum information
  #            is requested)
  def initialize(file_or_io=nil, opts={})
    if opts[:lazy] == :io
      if !file_or_io.is_a?(IO)
        raise ArgumentError, "Caller must provide an IO object (rather than filename) if using {:lazy => :io}"
      end
    end
    myopts = MSRunDefaultOpts.merge(opts)
    myopts[:msrun] = self
    if file_or_io
      filetype_and_version = MS::Parser.filetype_and_version(file_or_io)
      parser = MS::Parser.new(filetype_and_version, :msrun, myopts)
      parser.parse(file_or_io, myopts)
      #MS::Parser.new(filetype_and_version, :msrun).parse(file, myopts)
      (@filetype, @version) = filetype_and_version
    end
  end

  # This will automatically use :lazy => :io, open the file, and close it
  # after the block returns.
  #     MS::MSRun.open("file.mzXML") do |ms|
  #       ms.scans.each {|scan| ... do something }
  #     end
  def self.open(filename, opts={})
    File.open(filename) do |fh|
      ms = MS::MSRun.new(fh, {:lazy => :io}.merge(opts))
      yield(ms)
    end
  end

  # returns an array, whose indices provide the number of scans in each index level the ms_levels, [0] = all the scans, [1] = mslevel 1, [2] = mslevel 2,
  # ...
  def scan_counts
    ar = []
    ar[0] = 0
    scans.each do |sc|
      level = sc.ms_level
      unless ar[level]
        ar[level] = 0
      end
      ar[level] += 1
      ar[0] += 1
    end
    ar
  end

  def scan_count(mslevel=0)
    if mslevel == 0
      @scan_count 
    else
      num = 0
      scans.each do |sc|
        if sc.ms_level == mslevel
          num += 1
        end
      end
      num
    end
  end

  # for level 1, finds first scan and asks if it has start_mz/end_mz
  # attributes.  for other levels, asks for start_mz/ end_mz and takes the
  # min/max.  If start_mz and end_mz are not found, goes through every scan
  # finding the max/min first and last m/z. returns [start_mz (rounded down to
  # nearest int), end_mz (rounded up to nearest int)]
  def start_and_end_mz(mslevel=1)
    if mslevel == 1
      # special case for mslevel 1 (where we expect scans to be same length)
      scans.each do |sc|
        if sc.ms_level == mslevel
          if sc.start_mz && sc.end_mz
            return [sc.start_mz, sc.end_mz]
          end
          break
        end
      end
    end
    hi_mz = nil
    lo_mz = nil
    # see if we have start_mz and end_mz for the level we want
    # set the initial hi_mz and lo_mz in any case
    have_start_end_mz = false
    scans.each do |sc|
      if sc.ms_level == mslevel
        if sc.start_mz && sc.end_mz
          lo_mz = sc.start_mz
          hi_mz = sc.end_mz
        else
          mz_ar = sc.spectrum.mzs
          hi_mz = mz_ar.last
          lo_mz = mz_ar.first
        end
        break
      end
    end
    if have_start_end_mz
      scans.each do |sc|
        if sc.ms_level == mslevel
          if sc.start_mz < lo_mz
            lo_mz = sc.start_mz
          end
          if sc.end_mz > hi_mz
            hi_mz = sc.end_mz
          end
        end
      end
    else
      # didn't have the attributes (find by brute force)
      scans.each do |sc|
        if sc.ms_level == mslevel
          mz_ar = sc.spectrum.mzs
          if mz_ar.last > hi_mz
            hi_mz = mz_ar.last
          end
          if mz_ar.last < lo_mz
            lo_mz = mz_ar.last
          end
        end
      end
    end
    [lo_mz.floor, hi_mz.ceil]
  end

  # returns an array of precursor mz by scan number
  # returns only the m/z of the FIRST precursor if multiple
  def precursor_mz_by_scan_num
    ar = Array.new(@scans.size + 1)
    @scans.each do |scan|
      if prec = scan.precursor
        ar[scan.num] = prec.mz
      else
        ar[scan.num] = nil
      end
    end
    ar
  end

  # returns an array of times and parallel array of spectra objects.
  # ms_level = 0  then all spectra and times
  # ms_level = 1 then all spectra of ms_level 1
  def times_and_spectra(ms_level=0)
    spectra = []
    if ms_level == 0
      times = @scans.map do |scan|
        spectra << scan.spectrum  
        scan.time
      end
      [times, spectra]
    else  # choose a particular ms_level
      times = []
      @scans.each do |scan|
        if ms_level == scan.ms_level
          spectra << scan.spectrum  
          times << scan.time
        end
      end
      [times, spectra]
    end
  end

  # same as the instance method (creates an object without spectrum and calls
  # instance method of the same name)
  def self.precursor_mz_by_scan_num(file)
    self.new(file, :lazy => :no_spectra, :fix_bad_tags => true).precursor_mz_by_scan_num
  end

  # only adds the parent if one is not already present!
  def self.add_parent_scan(scans, add_intensities=false)
    #start = Time.now
    prev_scan = nil
    parent_stack = [nil]
    ## we want to set the level to be the first mslevel we come to
    prev_level = scans.first.ms_level
    scans.each do |scan|
      #next unless scan  ## the first one is nil, (others?)
      level = scan.ms_level
      if prev_level < level
        parent_stack.unshift prev_scan
      end
      if prev_level > level
        (prev_level - level).times do parent_stack.shift end
      end
      if scan.ms_level > 1
        precursor = scan.precursor
        #precursor.parent = parent_stack.first  # that's the next line's
        precursor[2] = parent_stack.first unless precursor[2]
        #precursor.intensity
        if add_intensities
          precursor[1] = precursor[2].spectrum.intensity_at_mz(precursor[0])
        end
      end
      prev_level = level
      prev_scan = scan
    end
    #puts "TOOK #{Time.now - start} secs"
  end

end



