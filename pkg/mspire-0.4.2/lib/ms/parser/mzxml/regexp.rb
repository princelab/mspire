require 'strscan'

module MS::Parser::MzXML ; end

class MS::Parser::MzXML::Regexp
  @@first_scan_regexp = /<scan /o
  include MS::Parser::MzXML

  def initialize(method=:msrun, version='1.0')
    @method = method
    @version = version
  end

  def parse(file)
    send(@method, file) 
  end

  # returns a MS::MsRun Object
  def msrun(file)
    fh = File.open(file) 
    get_header(fh)

    fh.close
  end

  #def msrun(file, opts={})
  #end

  @@scan_re = /<scan.*?num="(\d+)"(.*?)<\/scan>/mo
  def self.precursor_mz_and_intensity_by_scan(file)
    prec_re = /msLevel="2".*?<precursorMz precursorIntensity="([\d\.]+)".*?>([\d\.]+)<\/precursorMz>/mo
    self.by_scan_num(file, prec_re) {|match_obj| match_obj.captures.reverse}
  end

  # (array will likely start at 1!)
  def self.by_scan_num(file, regex)
    arr = []
    File.open(file) do |fh|
      string = fh.read 
      matches = string.scan(@@scan_re)
      matches.each do |matched|
        if inner_match = regex.match(matched[1])
          index = matched[0].to_i
          arr[index] = yield(inner_match)
        end
      end
    end
    arr
  end

  # Returns array where array[scan_num] = precursorMz
  # Parent scans armme not arrayed
  # Values are strings.  Array index likely starts at 1!
  # @TODO: replace the use of a yield block
  def self.precursor_mz_by_scan(file)
    prec_re = /msLevel="2".*?<precursorMz.*?>([\d\.]+)<\/precursorMz>/mo
    self.by_scan_num(file, prec_re) {|match_obj| match_obj.captures[0]}
  end

end


class MS::Parser::MzXML::Regexp::MsRun
  @@scan_count_regexp = /scanCount="(\d+)"/o
  @@start_time_regexp = /startTime="PT([\d\.]+)S"/o
  @@end_time_regexp = /endTime="PT([\d\.]+)S"/o
  @@first_scan_regexp = /<scan /

  def initialize(version='1.0')
    @version = version
  end

  def parse(io, msrun_object)
    atts = {}
    [:scan_count, :start_time, :end_time].zip(get_header_info(io)) {|v,k| atts[k] = v }
    ###
    # HERE <------------------------------------
    abort "NEED TO FINISH WRITING SCANS EXTRACTOR!"
    get_scans(io)
    # HERE <------------------------------------

    # set the attributes
    atts.each do |k,v|
      msrun_object.send(k,v)
    end
    # need to fill in the scan_counts array
  end

  # assumes the attributes are each on a line
  def get_scans(io)
    io.each do |line|
    end
  end

  # returns [total_num_scans, start_time, end_time] and positions the handle
  # so that the next 'gets' will call a scan
  def get_header_info(io)
    scan_count = nil
    start_time = nil
    end_time = nil

    previous_position = nil
    io.each do |line|
      if line =~ @@scan_count_regexp
        scan_count = $1.dup
      end
      if line =~ @@start_time_regexp
        start_time = $1.dup
      end
      if line =~  @@end_time_regexp
        end_time = $1.dup
      end
      if line =~ @@first_scan_regexp
        io.pos = previous_position
        break
      end
      previous_position = io.pos
    end
    [scan_count, start_time, end_time]
  end

end
