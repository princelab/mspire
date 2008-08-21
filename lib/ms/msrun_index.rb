require 'ms/scan'
require 'ms/parser'

class MS::MSRunIndex
  # basename_noext is the base name of the file (with NO extensions)
  attr_accessor :scans_by_num
  attr_reader :basename_noext

  # identifies and removes .mzXML .mzXML.timeIndex and .timeIndex
  # otherwise, removes one extension and that's the filename_noext
  # Also, removes any leading path
  def basename_noext=(filename)
    ext = File.extname(filename)
    basename = File.basename(filename)
    case ext
    when '.mzXML'
      @basename_noext = basename.gsub(/\.mzXML$/, "")
    when '.timeIndex'
      @basename_noext = basename.gsub(/\.timeIndex$/, "")
      if File.extname(@basename_noext) == ".mzXML"
        @basename_noext.gsub!(/\.mzXML$/, "")
      end
    else
      @basename_noext = basename.gsub(/#{Regexp.escape(ext)}/, "")
    end
  end

  # index_file has one row for each scan:
  # ms_level scan_num time [prec_mz prec_inten]
  # also consider getting this data directly from the mzXML file
  # via the MS::MzXML::Parser.get_msrun_index command
  def set_from_index_file(index_file)
    self.basename_noext = index_file
    @scans_by_num = []
    if index_file
      File.open(index_file).each do |line|
        next if line !~ /\d/ || line =~ /^#/
        line.chomp!
        arr = line.split(" ")
        scan = MS::Scan.new(arr[1].to_i, arr[0].to_i, arr[2].to_f) 
        if scan.ms_level > 1
          scan.prec_mz = arr[3].to_f
          scan.prec_inten = arr[4].to_f
        end
        @scans_by_num[scan.num] = scan
      end
    end
    MS::Scan.add_parent_scan(@scans_by_num)
  end

  # Takes a .mzXML file or .timeIndex file (currently)
  # and creates an index of scans from it
  def initialize(file=nil)
    @scans_by_num = []
    if file
      ext = File.extname(file)
      case ext
      when '.mzXML'
        set_from_mzxml(file)
      when '.timeIndex'
        set_from_index_file(file)
      else
        raise ArgumentError, "#{self.class}.new doesn't recognize files of extension: #{ext}"
      end
    end
  end


  # returns a new 
  def set_from_mzxml(file)
    self.basename_noext = file
    @scans_by_num = MS::Parser.new(file, :scans_by_num).parse(file)
  end

  # writes the index to filename
  # each line: 
  #   ms_level scan_num time (if !ms_level=1) { prec_mz prec_intensity)
  def to_index_file(filename)
    strings = []
    @scans_by_num.each do |scan|
      if scan
        strings << scan.to_index_file_string 
      end
    end
    File.open(filename, "w") do |fh|
      fh.print strings.join("\n")
    end
  end

  # returns an array of the times of the precursor scan's parent (not its own
  # acquisition time).  The parent scan index will also retrieve the time of
  # the parent scan.
  def parent_times_by_scan_num
    by_num = []
    parent_time = nil
    @scans_by_num.each_with_index do |scan,i|
      if scan.ms_level == 1
        parent_time = scan.time
      end
      by_num[i] = parent_time
    end
    by_num
  end

end



