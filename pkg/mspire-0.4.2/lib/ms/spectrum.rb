require 'base64'
require 'bsearch'
require 'ms'

class MS::Spectrum

  Unpack_network_float = 'g*'
  Unpack_network_double = 'G*'
  Unpack_little_endian_float = 'e*'
  Unpack_little_endian_double = 'E*'

  # m/z's
  attr_accessor :mzs  
  # intensities
  attr_accessor :intensities

  #######################
  ## CLASS METHODS:
  #######################
  
  # an already decoded string (ready to be unpacked as floating point numbers)
  def self.string_to_array(string, precision=32, network_order=true)
    unpack_code = 
      if network_order
        if precision == 32
          Unpack_network_float
        elsif precision == 64
          Unpack_network_double
        end
      else ## little endian
        if precision == 32
          Unpack_little_endian_float
        elsif precision == 64
          Unpack_little_endian_double
        end
      end
    string.unpack(unpack_code)
  end

  # takes a base64 string and returns an array
  def self.base64_to_array(b64_string, precision=32, network_order=true)
    self.string_to_array(Base64.decode64(b64_string), precision, network_order)
  end


  def self.mzs_and_intensities_from_base64_peaks(b64_string, precision=32, network_order=true)
    data = base64_to_array(b64_string, precision, network_order)
    sz = data.size/2
    mz_ar = Array.new(sz)
    intensity_ar = Array.new(sz)
    ndata = []
    my_ind = 0
    data.each_with_index do |dat,ind|
      if (ind % 2) == 0  # even
        mz_ar[my_ind] = dat
      else
        intensity_ar[my_ind] = dat 
        my_ind += 1
      end
    end
    [mz_ar, intensity_ar]
  end

  # takes a base64 peaks string and sets spectrum
  # returns self for chaining
  def self.from_base64_peaks(b64_string, precision=32, network_order=true)
    (mz_ar, intensity_ar) = self.mzs_and_intensities_from_base64_peaks(b64_string, precision, network_order)
    self.new(mz_ar, intensity_ar)
  end

  def self.from_base64_pair(mz_string, mz_precision, mz_network_order, intensity_string, intensity_precision, intensity_network_order)
    mz_ar = base64_to_array(mz_string, mz_precision, mz_network_order)
    inten_ar = base64_to_array(intensity_string, intensity_precision, intensity_network_order)
    self.new(mz_ar, inten_ar)
  end

  def initialize(mz_ar=[], intensity_ar=[])
    @mzs = mz_ar
    @intensities = intensity_ar
  end

  def has_mz_data?
    @mzs && (@mzs.size > 0) && (@mzs.first.is_a?(Numeric))
  end

  def has_intensity_data?
    @intensities && (@intensities.size > 0) && (@intensities.first.is_a?(Numeric))
  end

  # returns the index of the first value matching that m/z.  the argument m/z
  # may be less precise than the actual m/z (rounding to the same precision
  # given) but must be at least integer precision (after rounding)
  # implemented as binary search (bsearch from the web)
  def index(mz)
    mz_ar = mzs
    return_val = nil
    ind = mz_ar.bsearch_lower_boundary{|x| x <=> mz }
    if mz_ar[ind] == mz
      return_val = ind
    else 
      # do a rounding game to see which one is it, or nil
      # find all the values rounding to the same integer in the locale
      # test each one fully in turn
      mz = mz.to_f
      mz_size = mz_ar.size
      if ((ind < mz_size) and equal_after_rounding?(mz_ar[ind], mz))
        return_val = ind
      else # run the loop
        up = ind
        loop do
          up += 1
          if up >= mz_size
            break
          end
          mz_up = mz_ar[up]
          if (mz_up.ceil  - mz.ceil >= 2)
            break
          else
            if equal_after_rounding?(mz_up, mz)
              return_val = up
              return return_val
            end
          end
        end
        dn= ind
        loop do
          dn -= 1
          if dn < 0
            break
          end
          mz_dn = mz_ar[dn]
          if (mz.floor - mz_dn.floor >= 2)
            break
          else
            if equal_after_rounding?(mz_dn, mz)
              return_val = dn
              return return_val
            end
          end
        end
      end
    end
    return_val
  end
  
  # uses index function and returns the intensity at that value
  def intensity_at_mz(mz)
    if x = index(mz)
      intensities[x]
    else
      nil
    end
  end

  # less_precise should be a float
  # precise should be a float
  def equal_after_rounding?(precise, less_precise)
    # determine the precision of less_precise
    exp10 = precision_as_neg_int(less_precise)
    #puts "EXP10: #{exp10}"
    answ = ((precise*exp10).round == (less_precise*exp10).round)
    #puts "TESTING FOR EQUAL: #{precise} #{less_precise}"
    #puts answ
    (precise*exp10).round == (less_precise*exp10).round
  end

  # returns 1 for ones place, 10 for tenths, 100 for hundredths
  # to a precision exceeding 1e-6
  def precision_as_neg_int(float)
    neg_exp10 = 1
    loop do
      over = float * neg_exp10
      rounded = over.round
      if (over - rounded).abs <= 1e-6
        break
      end
      neg_exp10 *= 10
    end
    neg_exp10
  end

  ######
  # NOT REALLY USING RIGHT NOW:
  ######

  # takes a base64 peaks string and returns an array of [m/z,intensity] doublets
  # mzXML as network ordered
  def base64_peaks_to_pairs(string, precision=32)
    data = base64_peaks_to_array(string, precision)
    ndata = []
    data.each_with_index do |dat,ind|
      if (ind % 2) == 0  # even
        arr = Array.new(2)
        arr[0] = dat
        ndata.push( arr )
      else
        ndata.last[1] = dat 
      end
    end
    ndata
  end

end

# This implements a spectrum that stores itself as string data and only
# evaluates the information when it is called
class MS::Spectrum::LazyString < MS::Spectrum

  undef mzs=
  undef intensities=

  # beware that this converts the information in @mz_string every time it is
  # called
  def mzs
    MS::Spectrum.string_to_array(@mz_string, @mz_precision, @mz_network_order)
  end

  # beware that this converts the information in @intensity_string every time
  # it is
  def intensities
    MS::Spectrum.string_to_array(@intensity_string, @intensity_precision, @intensity_network_order)
  end

  # this takes a decoded base64 string that is then interpreted when
  # information is accessed
  def initialize(mz_string, mz_precision, mz_network_order, intensity_string, intensity_precision, intensity_network_order)
    @mz_string = mz_string
    @mz_precision = mz_precision
    @mz_network_order = mz_network_order
    @intensity_string = intensity_string
    @intensity_precision = intensity_precision
    @intensity_network_order = intensity_network_order
  end
  
  # from mzXML files where information is held in peaks (m/z, intensity,
  # m/z...)
  def self.from_base64_peaks(b64_string, precision=32, network_order=true)
    # decode
    string = Base64.decode64(b64_string)
    # split into two strings:
    bytes_per_number = precision / 8 
    s_size = string.size
    num_numbers = s_size / bytes_per_number
    mz_pieces = Array.new(num_numbers)
    intensity_pieces = Array.new(num_numbers)
    index = 0
    (0...string.size).step(bytes_per_number) do |i|
      if index % 2 == 0
        mz_pieces[index] = string[i,bytes_per_number]
      else
        intensity_pieces[index] = string[i,bytes_per_number]
      end
      index += 1
    end
    self.new(mz_pieces.join, precision, network_order, intensity_pieces.join, precision, network_order)
  end

  # from mzML and mzData style files where mz and intensity information are
  # kept in different strings.
  def self.from_base64_pair(b64_mz_string, mz_precision, mz_network_order, b64_intensity_string, intensity_precision, intensity_network_order)
    self.new(Base64.decode64(b64_mz_string), mz_precision, mz_network_order,  Base64.decode64(b64_intensity_string), intensity_precision, intensity_network_order)
  end

  def has_mz_data?
    @mz_string.is_a?(String) && @mz_precision && !@mz_network_order.nil?
  end

  def has_intensity_data?
    @intensity_string.is_a?(String) && @intensity_precision && !@intensity_network_order.nil?
  end

end

module MS::Spectrum::LazyIO
  def self.new(*args)
    if args.size == 5  # mzXMl
      MS::Spectrum::LazyIO::Peaks.new(*args)
    elsif args.size == 9   # other
      MS::Spectrum::LazyIO::Pair.new(*args)
    else
      raise RunTimeError, "must give 5 or 7 args for peak data and pair data respectively"
    end
  end
end


# stores an io object and the start and end indices and only evaluates the
# spectrum when information is requested
class MS::Spectrum::LazyIO::Pair < MS::Spectrum
  include MS::Spectrum::LazyIO

  undef mzs=
  undef intensities=

  def initialize(io, mz_start_index, mz_num_bytes, mz_precision, mz_network_order, intensity_start_index, intensity_num_bytes, intensity_precision, intensity_network_order)
    @io = io

    @mz_start_index = mz_start_index
    @mz_num_bytes = mz_num_bytes
    @mz_precision = mz_precision
    @mz_network_order = mz_network_order

    @intensity_start_index = intensity_start_index
    @intensity_num_bytes = intensity_num_bytes
    @intensity_precision = intensity_precision
    @intensity_network_order = intensity_network_order

  end

  # beware that this converts the information on disk every time it is called.  
  def mzs
    @io.pos = @mz_start_index
    b64_string = @io.read(@mz_num_bytes)
    MS::Spectrum.base64_to_array(b64_string, @mz_precision, @mz_network_order)
  end

  # beware that this converts the information in @intensity_string every time
  # it is called.
  def intensities
    @io.pos = @intensity_start_index
    b64_string = @io.read(@intensity_num_bytes)
    MS::Spectrum.base64_to_array(b64_string, @intensity_precision, @intensity_network_order)
  end

  def has_mz_data?
    (!@io.closed?) && @mz_start_index && @mz_num_bytes && @mz_precision && !@mz_network_order.nil?
  end

  def has_intensity_data?
    (!@io.closed?) && @intensity_start_index && @intensity_num_bytes && @intensity_precision && !@intensity_network_order.nil?
  end

end

class MS::Spectrum::LazyIO::Peaks < MS::Spectrum
  include MS::Spectrum::LazyIO

  undef mzs=
  undef intensities=

  def initialize(io, start_index, num_bytes, precision, network_order)
    @io = io
    @start_index = start_index
    @num_bytes = num_bytes
    @precision = precision
    @network_order = network_order
  end

  # returns two arrays: an array of m/z values and an array of intensity
  # values.  This is the preferred way to access mzXML file information under
  # lazy evaluation
  def mzs_and_intensities
    @io.pos = @start_index
    b64_string = @io.read(@num_bytes)
    MS::Spectrum.mzs_and_intensities_from_base64_peaks(b64_string, @precision, @network_order)
  end

  # when using 'io' lazy evaluation on files with m/z and intensity data
  # interwoven (i.e., mzXML) it is more efficient to call 'mzs_and_intensities'
  # if you are using both mz and intensity data. 
  def mzs
    # TODO: this can be made slightly faster
    mzs_and_intensities.first
  end

  # when using 'io' lazy evaluation on files with m/z and intensity data
  # interwoven (i.e., mzXML) it is more efficient to call
  # 'mzs_and_intensities'
  # if you are using both mz and intensity data. 
  def intensities
    # TODO: this can be made slightly faster
    mzs_and_intensities.last  
  end


  def has_mz_data?
    (!@io.closed?) && @start_index && @num_bytes && @precision && !@network_order.nil?
  end

  def has_intensity_data?
    (!@io.closed?) && @start_index && @num_bytes && @precision && !@network_order.nil?
  end

end
