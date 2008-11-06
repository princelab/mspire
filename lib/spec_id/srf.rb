require 'fileutils'

require 'spec_id'
require 'spec_id/sequest'
require 'fasta'
require 'mspire'
require 'set'

require 'core_extensions'

module BinaryReader
  Null_char = "\0"[0]  ## TODO: change for ruby 1.9 or 2.0
  # extracts a string with all empty chars at the end stripped
  # expects the filehandle to be at the proper location
  def get_null_padded_string(fh,bytes)
    st = fh.read(bytes)
    # for empty declarations
    if st[0] == Null_char
      return ''
    end
    st.rstrip!
    st
  end
end

# class to extract information from <file>_dta.log files

class SRFGroup
  include SpecID

  ## the srf objects themselves
  attr_accessor :srfs, :filenames
  ## also inherits :peps and :prots accessor

  # takes an array of filenames
  # or a single .srg filename
  # see from_srg to load a single .srg file
  # by default, the hits will be returned filtered by sequest params values.
  # [The raw SRF data is unfiltered!]
  def initialize(filenames=nil, filter_hits_by_params=true)
    @filenames = filenames
    @peps = []
    @prots = []
    @srfs = []

    # This is essentially duplicated in SQTGroup (should refactor eventually)
    global_ref_hash = {}
    if filenames
      if filenames.is_a?(String) && filenames =~ /\.srg$/
        srg_filename = filenames.dup
        @filename = srg_filename
        filenames = SRFGroup.srg_to_paths(filenames) 
        filenames.each do |file|
          if !File.exist? file
            puts "File: #{file} in #{srg_filename} does not exist!"
            puts "Please modify #{srg_filename} to point to existing files."
            abort
          end
        end
      end
      filenames.each do |file|
        @srfs << SRF.new(file, @peps, global_ref_hash)
      end
      @prots = global_ref_hash.values
      if filter_hits_by_params
        filter_by_peptide_mass_tolerance
      end
    end
  end

  # reads a srg file and delivers the path names
  def self.srg_to_paths(file)
    IO.readlines(file).grep(/\w/).map {|v| v.chomp } 
  end


  # if srfs were read in separately, then the proteins will need to be merged
  # by their reference
  def merge_different_sets(srfs)
    raise NotImplementedError, "need to implement?"
  end

  # 1. sets @prots and returns it: a new list of proteins based on which
  # peptides passed.
  # 2. updates the out_file's list of hits based on passing peptides (but not
  # the original hit id; rank is implicit in array ordering)
  # 3. updates each protein to only include peptides passing thresholds.
  # [Note, this process is how .out files are generated!]
  # 4. recalculates deltacn values completely if number of hits changed (does
  # not touch deltacn orig)
  # ASSUMES: 
  # A. all srfs have identical params objects and each has a
  # peptide_mass_tolerance filter attribute.
  # B. proteins are already unique (peptides referencing the same protein
  # reference the same object already) In practice, this means all srfs were
  # read in together.
  def filter_by_peptide_mass_tolerance
    prots_in_set = Set.new
    params = @srfs.first.params
    pmt = params.peptide_mass_tolerance.to_f
    methd = nil  # the method to 

    case params.peptide_mass_units
    when '0'
      amu_based = true
      milli_amu = false
    when '1'
      amu_based = true
      milli_amu = true
    when '2'
      amu_based = false
    end

    @srfs.each do |srf|
      srf.filtered_by_precursor_mass_tolerance = true
      srf.out_files.each do |out_file|
        hits = out_file.hits
        before = hits.size
        hits.reject! do |pep|
          do_not_keep =
            if amu_based
              if milli_amu
                (pep.deltamass.abs > (pmt/1000))
              else
                (pep.deltamass.abs > pmt)
              end
            else
              (pep.ppm.abs > pmt)
            end
          unless do_not_keep
            pep.prots.each do |prot|
              if prots_in_set.include?(prot)
                prot.peps << pep
              else
                prots_in_set.add(prot)
                prot.peps = [pep]
              end
            end
          end
          do_not_keep
        end
        if hits.size != before
          SRF::OUT::Pep.update_deltacns_from_xcorr(hits)
          out_file.num_hits = hits.size
        end
      end
    end
    @prots = prots_in_set.to_a

  end

  # returns the filename used
  # if the file exists, the name will be expanded to full path, otherwise just
  # what is given
  def to_srg(srg_filename='bioworks.srg')
    File.open(srg_filename, 'w') do |v|
      @filenames.each do |srf_file|
        if File.exist? srf_file
          v.puts File.expand_path(srf_file)
        else
          v.puts srf_file
        end
      end
    end
    srg_filename
  end
end

class SRF

  # a string 3.5, 3.3 or 3.2
  attr_accessor :version

  attr_accessor :header
  attr_accessor :dta_files
  attr_accessor :out_files
  attr_accessor :params
  # a parallel array to dta_files and out_files where each entry is:
  # [first_scan, last_scan, charge]
  attr_accessor :index
  attr_accessor :base_name
  # this is the global peptides array
  attr_accessor :peps
  MASCOT_HYDROGEN_MASS = 1.007276

  attr_accessor :filtered_by_precursor_mass_tolerance 

  # returns a Sequest::Params object
  def self.get_sequest_params(filename)
    # split the file in half and only read the second half (since we can be
    # confident that the params file will be there!)
    File.open(filename) do |handle|
      halfway = handle.stat.size / 2
      handle.seek halfway
      last_half = handle.read
      params_start_index = last_half.rindex('[SEQUEST]') + halfway
      handle.seek(params_start_index)
      Sequest::Params.new.parse_handle(handle)
    end
  end

  def dta_start_byte
    case @version
    when '3.2' ; 3260
    when '3.3' ; 3644
    when '3.5' ; 3644
    end
  end

  # peps and global_ref_hash are created as the srf files is read.  If the
  # file is read as part of a group, then these should be passed in. 
  # NOTE: if you want the hits filtered by precursor tolerance (the way they
  # might be displayed in .out files) you should probably use SRFGroup (which
  # does this by default)
  # SRF is meant to be a low level read of the file.
  def initialize(filename=nil, peps=[], global_ref_hash={})
    @dta_files = []
    @out_files = []
    if filename
      from_file(filename, peps, global_ref_hash)
    end
  end

  def round(float, decimal_places)
    sprintf("%.#{decimal_places}f", float)
  end

  # this mimicks the output of merge.pl from mascot
  # The only difference is that this does not include the "\r\n"
  # that is found after the peak lists, instead, it uses "\n" throughout the
  # file (thinking that this is preferable to mixing newline styles!)
  # note that Mass
  # if no filename is given, will use base_name + '.mgf'
  def to_mgf_file(filename=nil)
    filename =
      if filename ; filename
      else
        base_name + '.mgf'
      end
    h_plus = SpecID::MONO[:h_plus]
    File.open(filename, 'wb') do |out|
      dta_files.zip(index) do |dta, i_ar|
        chrg = dta.charge
        out.puts 'BEGIN IONS'
        out.puts "TITLE=#{[base_name, *i_ar].push('dta').join('.')}"
        out.puts "CHARGE=#{chrg}+"
        out.puts "PEPMASS=#{(dta.mh+((chrg-1)*h_plus))/chrg}"
        peak_ar = dta.peaks.unpack('e*')
        (0...(peak_ar.size)).step(2) do |i|
          out.puts( peak_ar[i,2].join(' ') )
        end
        out.puts ''
        out.puts 'END IONS'
        out.puts ''
      end
    end
  end

  # not given an out_folder, will make one with the basename
  # compress may be: :zip, :tgz, or nil (no compression)
  # :zip requires gem rubyzip to be installed and is *very* bloated
  # as it writes out all the files first!
  # :tgz requires gem archive-tar-minitar to be installed
  def to_dta_files(out_folder=nil, compress=nil)
    outdir = 
      if out_folder ; out_folder
      else base_name
      end

    case compress
    when :tgz
      begin
        require 'archive/tar/minitar'
      rescue LoadError
        abort "need gem 'archive-tar-minitar' installed' for tgz compression!\n#{$!}"
      end
      require 'archive/targz'  # my own simplified interface!
      require 'zlib'
      names = index.map do |i_ar|
        [outdir, '/', [base_name, *i_ar].join('.'), '.dta'].join('')
      end
      #Archive::Targz.archive_as_files(outdir + '.tgz', names, dta_file_data)

      tgz = Zlib::GzipWriter.new(File.open(outdir + '.tgz', 'wb'))

      Archive::Tar::Minitar::Output.open(tgz) do |outp|
        dta_files.each_with_index do |dta_file, i|
          Archive::Tar::Minitar.pack_as_file(names[i], dta_file.to_dta_file_data, outp)
        end
      end
    when :zip
      begin
        require 'zip/zipfilesystem'
      rescue LoadError
        abort "need gem 'rubyzip' installed' for zip compression!\n#{$!}"
      end
      #begin ; require 'zip/zipfilesystem' ; rescue LoadError, "need gem 'rubyzip' installed' for zip compression!\n#{$!}" ; end
      Zip::ZipFile.open(outdir + ".zip", Zip::ZipFile::CREATE) do |zfs|
        dta_files.zip(index) do |dta,i_ar|
          #zfs.mkdir(outdir)
          zfs.get_output_stream(outdir + '/' + [base_name, *i_ar].join('.') + '.dta') do |out|
            dta.write_dta_file(out)
            #zfs.commit
          end
        end
      end
    else  # no compression
      FileUtils.mkpath(outdir)
      Dir.chdir(outdir) do
        dta_files.zip(index) do |dta,i_ar|
          File.open([base_name, *i_ar].join('.') << '.dta', 'wb') do |out|
            dta.write_dta_file(out)
          end
        end
      end
    end
  end

  # the out_filename will be the base_name + .sqt unless 'out_filename' is
  # defined
  # :round => round floating point numbers
  # etc...
  def to_sqt(out_filename=nil, opts={})
    tic_dp = 2
    mh_dp = 7
    xcorr_dp = 5
    sp_dp = 2
    dcn_dp = 5

    defaults = {:db_info=>false, :new_db_path=>nil, :update_db_path=>false, :round=>false}
    opt = defaults.merge(opts)

    outfile =
      if out_filename
        out_filename
      else
        base_name + '.sqt'
      end
    invariant_ordering = %w(SQTGenerator SQTGeneratorVersion Database FragmentMasses PrecursorMasses StartTime) # just for readability and consistency
    fmt = 
      if params.fragment_mass_type == 'average' ; 'AVG'
      else ; 'MONO'
      end
    pmt =
      if params.precursor_mass_type == 'average' ; 'AVG'
      else ; 'MONO'
      end

    mass_table = params.mass_table
    static_mods = params.static_mods.map do |k,v|
      key =  k.split(/_/)[1]
      if key.size == 1
        key + '=' + (mass_table[key.to_sym] + v.to_f).to_s
      else
        key + '=' + v
      end
    end

    dynamic_mods = []
    header.modifications.scan(/\((.*?)\)/) do |match|
      dynamic_mods << match.first.sub(/ /,'=')
    end
    plural = {
      'StaticMod' => static_mods,
      'DynamicMod' => dynamic_mods,  # example as diff mod
      'Comment' => ['Created from Bioworks .srf file']
    }


    db_filename = header.db_filename
    db_filename_in_sqt = db_filename
    if opt[:new_db_path]
      db_filename = File.join(opt[:new_db_path], File.basename(db_filename.gsub('\\', '/')))
      if opt[:update_db_path]
        db_filename_in_sqt = File.expand_path(db_filename)
        warn "writing Database #{db_filename} to sqt, but it does not exist on this file system" unless File.exist?(db_filename) 
      end
    end

    apmu = 
      case params.peptide_mass_units 
      when '0' : 'amu' 
      when '1' : 'mmu'
      when '2' : 'ppm'
      end

    hh =  {
      'SQTGenerator' => 'mspire',
      'SQTGeneratorVersion' => Mspire::Version,
      'Database' => db_filename_in_sqt,
      'FragmentMasses' => fmt,
      'PrecursorMasses' => pmt,
      'StartTime' => '',  # Bioworks 3.2 also leaves this blank...
      'Alg-PreMassTol' => params.peptide_mass_tolerance,
      'Alg-FragMassTol' => params.fragment_ion_tolerance,
      'Alg-PreMassUnits' => apmu, ## mine
      'Alg-IonSeries' => header.ion_series.split(':').last.lstrip,
      'Alg-Enzyme' => header.enzyme.split(':').last,
      'Alg-MSModel' => header.model,
    }

    if opt[:db_info]
      if File.exist?(db_filename)
        reply = get_db_info_for_sqt(db_filename)
        %w(DBSeqLength DBLocusCount DBMD5Sum).zip(reply) do |label,val|
          hh[label] = val
        end
      else
        warn "file #{db_filename} does not exist, no extra db info in header!"
      end
    end

    has_hits = (self.out_files.size > 0)
    if has_hits
      # somewhat redundant with above, but we can get this without a db present!
      hh['DBLocusCount'] = self.out_files.first.db_locus_count
    end

    File.open(outfile, 'w') do |out|
      # print the header:
      invariant_ordering.each do |iv|
        out.puts ['H', iv, hh.delete(iv)].join("\t")
      end
      hh.each do |k,v|
        out.puts ['H', k, v].join("\t")
      end
      plural.each do |k,vals|
        vals.each do |val|
          out.puts ['H', k, val].join("\t")
        end
      end

      ##### SPECTRA
      time_to_process = '0.0'
      #########################################
      # NEED TO FIGURE OUT: (in spectra guy)
      #    * Lowest Sp value for top 500 spectra
      #    * Number of sequences matching this precursor ion 
      #########################################

      manual_validation_status = 'U'
      self.out_files.zip(dta_files) do |out_file, dta_file|
        # don't have the time to process (using 0.0 like bioworks 3.2)
        dta_file_mh = dta_file.mh
        out_file_total_inten = out_file.total_inten
        out_file_lowest_sp = out_file.lowest_sp
        if opt[:round]
          dta_file_mh = round(dta_file_mh, mh_dp)
          out_file_total_inten = round(out_file_total_inten, tic_dp)
          out_file_lowest_sp = round(out_file_lowest_sp, sp_dp)
        end

        out.puts ['S', out_file.first_scan, out_file.last_scan, out_file.charge, time_to_process, out_file.computer, dta_file_mh, out_file_total_inten, out_file_lowest_sp, out_file.num_matched_peptides].join("\t")
        out_file.hits.each_with_index do |hit,index|
          hit_mh = hit.mh
          hit_deltacn_orig_updated = hit.deltacn_orig_updated
          hit_xcorr = hit.xcorr
          hit_sp = hit.sp
          if opt[:round]
            hit_mh = round(hit_mh, mh_dp)
            hit_deltacn_orig_updated = round(hit_deltacn_orig_updated, dcn_dp)
            hit_xcorr = round(hit_xcorr, xcorr_dp)
            hit_sp = round(hit_sp, sp_dp)
          end
          # note that the rank is determined by the order..
          out.puts ['M', index+1, hit.rsp, hit_mh, hit_deltacn_orig_updated, hit_xcorr, hit_sp, hit.ions_matched, hit.ions_total, hit.sequence, manual_validation_status].join("\t")
          hit.prots.each do |prot|
            out.puts ['L', prot.first_entry].join("\t")
          end
        end
      end
    end # close the filehandle

  end

  # assumes the file exists and is readable
  # returns [DBSeqLength, DBLocusCount, DBMD5Sum] or nil if no file
  def get_db_info_for_sqt(dbfile)
      fasta = Fasta.new(dbfile)
      [fasta.aa_seq_length, fasta.size, fasta.md5_sum]
  end


  # returns self
  def from_file(filename, peps, global_ref_hash)
    dups = SRF.get_sequest_params(filename).print_duplicate_references
    if dups == '0'
      raise RuntimeError, <<END

***************************************************************************
Sorry, but the SRF reader cannot read this file!
.srf files must currently be created with print_duplicate_references > 0
(This is how the srf object can link peptides with proteins!)
To capture all duplicate references, set the sequest parameter
'print_duplicate_references' to 100 or greater.
***************************************************************************
END
    end

    File.open(filename, "rb") do |fh|
      @header = SRF::Header.new.from_handle(fh)      
      @version = @header.version
      
      unpack_35 = case @version
                  when '3.2'
                    false
                  when '3.3'
                    false
                  when '3.5'
                    true
                  end
      @dta_files, measured_mhs = read_dta_files(fh,@header.num_dta_files, unpack_35)
      
      @out_files = read_out_files(fh,@header.num_dta_files, global_ref_hash, measured_mhs, unpack_35)
      if fh.eof?
        warn "FILE: '#{filename}' appears to be an abortive run (no params in srf file)\nstill continuing..."
        @params = nil
        @index = []
      else
        @params = Sequest::Params.new.parse_handle(fh)
        # This is very sensitive to the grab_params method in sequest params
        fh.read(12)  ## gap between last params entry and index 
        @index = read_scan_index(fh,@header.num_dta_files)
      end
    end

    ### UPDATE SOME THINGS ON SINGLE PASS:
    @base_name = @header.raw_filename.scan(/[\\\/]([^\\\/]+)\.RAW$/).first.first
    # give each hit a base_name, first_scan, last_scan
    @index.each_with_index do |ind,i|
      mass_measured = @dta_files[i][0]
      #puts @out_files[i].join(", ")
      @out_files[i][0,3] = *ind
      pep_hits = @out_files[i][6]
      peps.push( *pep_hits )
      pep_hits.each do |pep_hit|
        pep_hit[14,4] = @base_name, *ind
        # add the deltamass
        pep_hit[11] = pep_hit[0] - mass_measured  # real - measured (deltamass)
        pep_hit[12] = 1.0e6 * pep_hit[11].abs / mass_measured ## ppm
        pep_hit[18] = self  ## link with the srf object
      end
    end
    self
  end

  # returns an index where each entry is [first_scan, last_scan, charge]
  def read_scan_index(fh, num)
    ind_len = 24
    index = Array.new(num)
    unpack_string = 'III'
    st = ''
    ind_len.times do st << '0' end  ## create a 24 byte string to receive data
    num.times do |i|
      fh.read(ind_len, st)
      index[i] = st.unpack(unpack_string)
    end
    index
  end

  # returns an array of dta_files
  def read_dta_files(fh, num_files, unpack_35)
    measured_mhs = Array.new(num_files) ## A parallel array to capture the actual mh
    dta_files = Array.new(num_files)
    start = dta_start_byte
    unless fh.pos == start
      fh.pos = start
    end

    header.num_dta_files.times do |i|
      dta_file = SRF::DTA.new.from_handle(fh, unpack_35) 
      measured_mhs[i] = dta_file[0]
      dta_files[i] = dta_file
    end
    [dta_files, measured_mhs]
  end

  # filehandle (fh) must be at the start of the outfiles.  'read_dta_files'
  # will put the fh there.
  def read_out_files(fh,number_files, global_ref_hash, measured_mhs, unpack_35)
    out_files = Array.new(number_files)
    header.num_dta_files.times do |i|
      out_files[i] = SRF::OUT.new.from_handle(fh, global_ref_hash, unpack_35)
    end
    out_files
  end

end

class SRF::Header
  include BinaryReader

  Start_byte = {
    :enzyme => 438,
    :ion_series => 694,
    :model => 950,
    :modifications => 982,
    :raw_filename => 1822,
    :db_filename => 2082,
    :dta_log_filename => 2602,
    :params_filename => 3122,
    :sequest_log_filename => 3382,
  }
  Byte_length = {
    :enzyme => 256,
    :ion_series => 256,
    :model => 32,
    :modifications => 840,
    :raw_filename => 260,
    :db_filename => 520,
    :dta_log_filename => 520,
    :params_filename => 260,
    :sequest_log_filename => 262, ## is this really 262?? or should be 260??
  }
  Byte_length_v32 = {
    :modifications => 456,
  }
 
  # a SRF::DTAGen object
  attr_accessor :version
  attr_accessor :dta_gen
  attr_accessor :enzyme
  attr_accessor :ion_series
  attr_accessor :model
  attr_accessor :modifications
  attr_accessor :raw_filename
  attr_accessor :db_filename
  attr_accessor :dta_log_filename
  attr_accessor :params_filename
  attr_accessor :sequest_log_filename

  def num_dta_files
    @dta_gen.num_dta_files
  end

  # sets fh to 0 and grabs the information it wants
  def from_handle(fh)
    st = fh.read(4) 
    @version = '3.' + st.unpack('I').first.to_s
    @dta_gen = SRF::DTAGen.new.from_handle(fh)

    ## get the rest of the info
    byte_length = Byte_length.dup
    byte_length.merge! Byte_length_v32 if @version == '3.2'

    fh.pos = Start_byte[:enzyme]
    [:enzyme, :ion_series, :model, :modifications, :raw_filename, :db_filename, :dta_log_filename, :params_filename, :sequest_log_filename].each do |param|
      send("#{param}=".to_sym, get_null_padded_string(fh, byte_length[param]) )
    end
    self
  end

end

# the DTA Generation Params
class SRF::DTAGen

  ## not sure if this is correct
  # Float
  attr_accessor :start_time
  # Float
  attr_accessor :start_mass
  # Float
  attr_accessor :end_mass
  # Integer
  attr_accessor :num_dta_files
  # Integer
  attr_accessor :group_scan
  ## not sure if this is correct
  # Integer
  attr_accessor :min_group_count
  # Integer
  attr_accessor :min_ion_threshold
  #attr_accessor :intensity_threshold # can't find yet
  #attr_accessor :precursor_tolerance # can't find yet
  # Integer
  attr_accessor :start_scan
  # Integer
  attr_accessor :end_scan

  # 
  def from_handle(fh)
    fh.pos = 0 if fh.pos != 0  
    st = fh.read(148)
    (@start_time, @start_mass, @end_mass, @num_dta_files, @group_scan, @min_group_count, @min_ion_threshold, @start_scan, @end_scan) = st.unpack('x36ex12ex4ex48Ix12IIIII')
    self
  end
end

# total_num_possible_charge_states is not correct under 3.5 (Bioworks 3.3.1)
# unknown is, well unknown...
SRF::DTA = Arrayclass.new(%w(mh dta_tic num_peaks charge ms_level unknown total_num_possible_charge_states peaks))

class SRF::DTA 
  # original
  # Unpack = "EeIvvvv"
  Unpack_32 = "EeIvvvv"
  Unpack_35 = "Ex8eVx2vvvv"

  # note on peaks (self[7])
  # this is a byte array of floats, you can get the peaks out with
  # unpack("e*")

  undef_method :inspect
  def inspect
    peaks_st = 'nil'
    if self[7] ; peaks_st = "[#{self[7].size} bytes]" end
    "<SRF::DTA @mh=#{mh} @dta_tic=#{dta_tic} @num_peaks=#{num_peaks} @charge=#{charge} @ms_level=#{ms_level} @total_num_possible_charge_states=#{total_num_possible_charge_states} @peaks=#{peaks_st} >"
  end
    
  def from_handle(fh, unpack_35)
    if unpack_35
      @unpack = Unpack_35
      @read_header = 34
      @read_spacer = 22
    else
      @unpack = Unpack_32
      @read_header = 24
      @read_spacer = 24
    end

    st = fh.read(@read_header)
    # get the bulk of the data in single unpack
    self[0,7] = st.unpack(@unpack)
    
    # Scan numbers are given at the end in an index!
    st2 = fh.read(@read_spacer)

    num_bytes_to_read = num_peaks * 8  
    st3 = fh.read(num_bytes_to_read)
    self[7] = st3
    self
  end

  def to_dta_file_data
     string = "#{mh.round_to(6)} #{charge}\r\n"
     peak_ar = peaks.unpack('e*')
     (0...(peak_ar.size)).step(2) do |i|
       # %d is equivalent to floor, so we round by adding 0.5!
       string << "#{peak_ar[i].round_to(4)} #{(peak_ar[i+1] + 0.5).floor}\r\n"
       #string << peak_ar[i,2].join(' ') << "\r\n"
     end
     string
  end

  # write a class dta file to the io object
  def write_dta_file(io)
    io.print to_dta_file_data
  end

end

SRF::OUT =  Arrayclass.new( %w(first_scan last_scan charge num_hits computer date_time hits total_inten lowest_sp num_matched_peptides db_locus_count) )
# 0=first_scan, 1=last_scan, 2=charge, 3=num_hits, 4=computer, 5=date_time, 6=hits, 7=total_inten, 8=lowest_sp, 9=num_matched_peptides, 10=db_locus_count

class SRF::OUT
  Unpack_32 = '@36vx2Z*@60Z*'
  Unpack_35 = '@36vx4Z*@62Z*'

  undef_method :inspect
  def inspect
    hits_s = 
      if self[6]
        ", @hits(#)=#{hits.size}"
      else
        ''
      end
    "<SRF::OUT  first_scan=#{first_scan}, last_scan=#{last_scan}, charge=#{charge}, num_hits=#{num_hits}, computer=#{computer}, date_time=#{date_time}#{hits_s}>"
  end
    
  def from_handle(fh, global_ref_hash, unpack_35)
    ## EMPTY out file is 96 bytes
    ## each hit is 320 bytes
    ## num_hits and charge:
    st = fh.read(96)

    self[3,3] = st.unpack( (unpack_35 ? Unpack_35 : Unpack_32) )
    self[7,4] = st.unpack('@8eex4Ix4I')
    num_hits = self[3]

    ar = Array.new(num_hits)
    if ar.size > 0
      num_extra_references = 0
      num_hits.times do |i|
        ar[i] = SRF::OUT::Pep.new.from_handle(fh, global_ref_hash, unpack_35)
        num_extra_references += ar[i].num_other_loci
      end
      SRF::OUT::Pep.read_extra_references(fh, num_extra_references, ar, global_ref_hash)
      ## The xcorrs are already ordered by best to worst hit
      ## ADJUST the deltacn's to be meaningful for the top hit:
      ## (the same as bioworks and prophet)
      SRF::OUT::Pep.set_deltacn_from_deltacn_orig(ar)
      #puts ar.map  {|a| a.deltacn }.join(", ")
    end
    self[6] = ar
    self
  end



end


# deltacn_orig - the one that sequest originally reports (top hit gets 0.0)
# deltacn - modified to be that of the next best hit (by xcorr) and the last
# hit takes 1.1.  This is what is called deltacn by bioworks and pepprophet
# (at least for the first few years).  If filtering occurs, it will be
# updated.  
# deltacn_orig_updated - the latest updated value of deltacn.
# Originally, this will be equal to deltacn_orig.  After filtering, this will
# be recalculated.  To know if this will be different from deltacn_orig, query
# match.srf.filtered_by_precursor_mass_tolerance.  If this is changed, then
# deltacn should also be changed to reflect it. 
# mh - the theoretical mass + h
# prots are created as SRF prot objects with a reference and linked to their
# peptides (from global hash by reference)
# ppm = 10^6 * ∆m_accuracy / mass_measured  [ where ∆m_accuracy = mass_real – mass_measured ]
# This is calculated for the M+H mass!
# num_other_loci is the number of other loci that the peptide matches beyond
# the first one listed
# srf = the srf object this scan came from

SRF::OUT::Pep = Arrayclass.new(%w( mh deltacn_orig sp xcorr id num_other_loci rsp ions_matched ions_total sequence prots deltamass ppm aaseq base_name first_scan last_scan charge srf deltacn deltacn_orig_updated) )

# 0=mh 1=deltacn_orig 2=sp 3=xcorr 4=id 5=num_other_loci 6=rsp 7=ions_matched 8=ions_total 9=sequence 10=prots 11=deltamass 12=ppm 13=aaseq 14=base_name 15=first_scan 16=last_scan 17=charge 18=srf 19=deltacn 20=deltacn_orig_updated

class SRF::OUT::Pep
  include SpecID::Pep

  # creates the deltacn that is meaningful for the top hit (the deltacn_orig
  # or the second best hit and so on).
  # assumes sorted
  def self.set_deltacn_from_deltacn_orig(ar)
    (1...ar.size).each {|i| ar[i-1].deltacn = ar[i].deltacn_orig }
    ar[-1].deltacn = 1.1
  end

  # (assumes sorted)
  # recalculates deltacn from xcorrs and sets deltacn_orig_updated and deltacn
  def self.update_deltacns_from_xcorr(ar)
    if ar.size > 0
      top_score = ar.first[3]
      other_scores = (1...(ar.size)).to_a.map do |i|
        1.0 - (ar[i][3]/top_score)
      end
      ar.first[20] = 0.0
      (0...(ar.size-1)).each do |i|
        ar[i][19] = other_scores[i]    # deltacn
        ar[i+1][20] = other_scores[i]  # deltacn_orig_updated
      end
      ar.last[19] = 1.1
    end
  end

  def self.read_extra_references(fh, num_extra_references, pep_hits, global_ref_hash)
    p num_extra_references
    num_extra_references.times do
      # 80 bytes total (with index number)
      pep = pep_hits[fh.read(8).unpack('x4I').first - 1]

      ref = fh.read(80).unpack('A*').first
      pep[10] << pep.new_protein(ref[0,38], pep, global_ref_hash)
    end
    #  fh.read(6) if unpack_35
  end

  # x2=???
  #Unpack_35 = '@64Ex8ex12eeIx22vx2vvx8Z*@246Z*'
  ### NOTE: 
  # I need to verify that this is correct (I mean the 'I' after x18)
  Unpack_35 = '@64Ex8ex12eeIx18Ivx2vvx8Z*@246Z*'
  # translation: @64=(64 bytes in to the record), E=mH, x8=8unknown bytes, e=deltacn,
  # x12=12unknown bytes, e=sp, e=xcorr, I=ID#, x18=18 unknown bytes, v=rsp,
  # v=ions_matched, v=ions_total, x8=8unknown bytes, Z*=sequence, 240Z*=at
  # byte 240 grab the string (which is proteins).
  #Unpack_32 = '@64Ex8ex12eeIx18vvvx8Z*@240Z*'
  Unpack_32 = '@64Ex8ex12eeIx14Ivvvx8Z*@240Z*'
  Unpack_four_null_bytes = 'a*'
  Unpack_Zstar = 'Z*'
  Read_35 = 426
  Read_32 = 320

  FourNullBytes_as_string = "\0\0\0\0"
  #NewRecordStart = "\0\0" + 0x3a.chr + 0x1a.chr + "\0\0"
  NewRecordStart = 0x01.chr + 0x00.chr
  Sequest_record_start = "[SEQUEST]"

  undef_method :inspect
  def inspect
    st = %w(aaseq sequence mh deltacn_orig sp xcorr id rsp ions_matched ions_total prots deltamass ppm base_name first_scan last_scan charge deltacn).map do |v| 
      if v == 'prots'
        "#{v}(#)=#{send(v.to_sym).size}"
      elsif v.is_a? Array
        "##{v}=#{send(v.to_sym).size}"
      else
        "#{v}=#{send(v.to_sym).inspect}"
      end
    end
    st.unshift("<#{self.class}")
    if srf
      st.push("srf(base_name)=#{srf.base_name.inspect}")
    end
    st.push('>')
    st.join(' ')
    #"<SRF::OUT::Pep @mh=#{mh}, @deltacn=#{deltacn}, @sp=#{sp}, @xcorr=#{xcorr}, @id=#{id}, @rsp=#{rsp}, @ions_matched=#{ions_matched}, @ions_total=#{ions_total}, @sequence=#{sequence}, @prots(count)=#{prots.size}, @deltamass=#{deltamass}, @ppm=#{ppm} @aaseq=#{aaseq}, @base_name=#{base_name}, @first_scan=#{first_scan}, @last_scan=#{last_scan}, @charge=#{charge}, @srf(base_name)=#{srf.base_name}>"
  end
  # extra_references_array is an array that grows with peptides as extra
  # references are discovered.
  def from_handle(fh, global_ref_hash, unpack_35)
    unpack = 
      if unpack_35 ; Unpack_35
      else ; Unpack_32
      end

    ## get the first part of the info
    st = fh.read(( unpack_35 ? Read_35 : Read_32) ) ## read all the hit data

    self[0,10] = st.unpack(unpack)

    # set deltacn_orig_updated 
    self[20] = self[1]

    # we are slicing the reference to 38 chars to be the same length as
    # duplicate references
    self[10] = [new_protein(self[10][0,38], self, global_ref_hash)]
    
    self[13] = SpecID::Pep.sequence_to_aaseq(self[9])

    fh.read(6) if unpack_35

    self
  end

  def new_protein(reference, peptide, global_ref_hash)
    if global_ref_hash.key? reference
      global_ref_hash[reference].peps << peptide
    else
      global_ref_hash[reference] = SRF::OUT::Prot.new(reference, [peptide])
    end
    global_ref_hash[reference] 
  end

 end

SRF::OUT::Prot = Arrayclass.new( %w(reference peps) )

class SRF::OUT::Prot
  include SpecID::Prot
  # we shouldn't have to do this because this is inlcuded in SpecID::Prot, but
  # under some circumstances it won't work without explicitly calling it.
  include ProteinReferenceable 

  tmp = $VERBOSE ; $VERBOSE = nil
  def initialize(reference=nil, peps=[])
    #super(@@arr_size)
    super(self.class.size)
    #@reference = reference
    #@peps = peps
    self[0,2] = reference, peps
  end
  $VERBOSE = tmp

  #  "<SRF::OUT::Prot reference=\"#{@reference}\">"
  
  undef_method :inspect
  def inspect
    "<SRF::OUT::Prot @reference=#{reference}, @peps(#)=#{peps.size}>"
  end
end





