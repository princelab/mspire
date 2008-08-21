require 'spec_id'
require 'arrayclass'
require 'set'

class SQTGroup
  include SpecID   # inherits prots and peps accessors

  attr_accessor :sqts, :filenames

  # if filenames is a String, then it should be a filename to a file ending in
  # '.sqg' (meta text file with list of .sqt files) else it should be an array
  # of sqt filenames
  def initialize(filenames=nil)
    @filenames = filenames
    @prots = []
    @peps = []
    @sqts = []

    global_ref_hash = {}
    ## This is duplicated in SRFGroup (should refactor eventually)
    if filenames
      if filenames.is_a?(String) && filenames =~ /\.sqg$/
        srg_filename = filenames.dup
        @filename = srg_filename
        @filenames = IO.readlines(filenames).grep(/\w/).map {|v| v.chomp } 
        @filenames.each do |file|
          if !File.exist? file
            puts "File: #{file} in #{srg_filename} does not exist!"
            puts "Please modify #{srg_filename} to point to existing files."
            abort
          end
        end
      end
      @filenames.each do |file|
        @sqts << SQT.new(file, @peps, global_ref_hash)
      end

      @prots = global_ref_hash.values
    end
  end

  # NOTE THAT this is copy/paste from srf.rb, should be refactored...
  # returns the filename used
  # if the file exists, the name will be expanded to full path, otherwise just
  # what is given
  def to_sqg(sqg_filename='bioworks.sqg')
    File.open(sqg_filename, 'w') do |v|
      @filenames.each do |sqt_file|
        if File.exist? sqt_file
          v.puts File.expand_path(sqt_file)
        else
          v.puts sqt_file
        end
      end
    end
    sqg_filename
  end

end

class SQT
  PercolatorHeaderMatch = /^Percolator v/
  Delimiter = "\t"
  attr_accessor :header
  attr_accessor :spectra
  attr_accessor :base_name
  # boolean
  attr_accessor :percolator_results

  def initialize(filename=nil, peps=[], global_ref_hash={})
    if filename
      from_file(filename, peps, global_ref_hash)
    end
  end

  # if the file contains the header key '/$Percolator v/' then the results
  # will be interpreted as percolator results
  def from_file(filename, peps=[], global_ref_hash={}, percolator_results=false)
    @percolator_results = percolator_results
    @base_name = File.basename( filename.gsub('\\','/') ).sub(/\.\w+$/, '')
    File.open(filename) do |fh| 
      @header = SQT::Header.new.from_handle(fh)
      if @header.keys.any? {|v| v =~ PercolatorHeaderMatch }
        @percolator_results = true
      end
      @spectra = SQT::Spectrum.spectra_from_handle(fh, @base_name, peps, global_ref_hash, @percolator_results)
    end
  end

end

# Inherits from hash, so all header stuff can be accessed by key.  Multiline
# values will be pushed into an array.
# All header values are stored as (newline-removed) strings!
class SQT::Header < Hash
  Leader = 'H'

  # These will be in arrays no matter what: StaticMod, DynamicMod, Comment
  # Any other keys repeated will be shoved into an array; otherwise a string
  Arrayed = %w(DyanmicMod StaticMod Comment).to_set

  HeaderKeys = {
    :sqt_generator => 'SQTGenerator',
    :sqt_generator_version => 'SQTGeneratorVersion',
    :database => 'Database',
    :fragment_masses => 'FragmentMasses',
    :precursor_masses => 'PrecursorMasses',
    :start_time => 'StartTime',
    :db_seq_length => 'DBSeqLength',
    :db_locus_count => 'DBLocusCount',
    :db_md5sum => 'DBMD5Sum',
    :peptide_mass_tolerance => 'Alg-PreMassTol',
    :fragment_ion_tolerance => 'Alg-FragMassTol',
    # nonstandard (mine)
    :peptide_mass_units => 'Alg-PreMassUnits',
    :ion_series => 'Alg-IonSeries',
    :enzyme => 'Alg-Enzyme',
    # nonstandard (mine)
    :ms_model => 'Alg-MSModel',
    :static_mods => 'StaticMod',
    :dynamic_mods => 'DynamicMod',
    :comments => 'Comment'
  }


  KeysToAtts = HeaderKeys.invert

  HeaderKeys.keys.each do |ky|
    attr_accessor ky
  end

  def from_handle(fh)
    Arrayed.each do |ky|
      self[ky] = []
    end
    pos = fh.pos 
    lines = []
    loop do 
      line = fh.gets
      if line && (line[0,1] == SQT::Header::Leader )
        lines << line
      else # reset the fh.pos and we're done
        fh.pos = pos
        break
      end
      pos = fh.pos 
    end
    from_lines(lines)
  end

  def from_lines(array_of_header_lines)
    array_of_header_lines.each do |line|
      line.chomp!
      (ky, *rest) = line.split(SQT::Delimiter)[1..-1]
      # just in case they have any tabs in their field
      value = rest.join(SQT::Delimiter)
      if Arrayed.include?(ky)
        self[ky] << value
      elsif self.key? ky  # already exists
        if self[ky].is_a? Array
          self[ky] << value
        else
          self[ky] = [self[ky], value]
        end
      else  # normal
        self[ky] = value
      end
    end
    KeysToAtts.each do |ky,methd|
      self.send("#{methd}=".to_sym, self[ky])
    end
    self
  end

end

# all are cast as expected (total_intensity is a float)
# mh = observed mh
SQT::Spectrum = Arrayclass.new(%w[first_scan last_scan charge time_to_process node mh total_intensity lowest_sp num_matched_peptides matches])

# 0=first_scan 1=last_scan 2=charge 3=time_to_process 4=node 5=mh 6=total_intensity 7=lowest_sp 8=num_matched_peptides 9=matches

class SQT::Spectrum
  Leader = 'S'

  # assumes the first line starts with an 'S'
  def self.spectra_from_handle(fh, base_name, peps=[], global_ref_hash={}, percolator_results=false)
    spectra = []
    
    while line = fh.gets
      case line[0,1]
      when SQT::Spectrum::Leader
        spectrum = SQT::Spectrum.new.from_line( line )
        spectra << spectrum
        matches = []
        spectrum.matches = matches
      when SQT::Match::Leader
        match_klass = if percolator_results
                        SQT::Match::Percolator
                      else
                        SQT::Match
                      end
        match = match_klass.new.from_line( line )
        match[10,3] = spectrum[0,3]
        match[15] = base_name
        matches << match
        peps << match
        loci = []
        match.loci = loci
        matches << match
      when SQT::Locus::Leader
        line.chomp!
        key = line.split(SQT::Delimiter)[1]
        locus =
          if global_ref_hash.key?(key)
            global_ref_hash[key]
          else
            locus = SQT::Locus.new.from_line( line )
            locus.peps = []
            global_ref_hash[key] = locus
          end
        locus.peps << match
        loci << locus
      end
    end
    # set the deltacn:
    set_deltacn(spectra)
    spectra
  end

  def self.set_deltacn(spectra)
    spectra.each do |spec|
      matches = spec.matches
      if matches.size > 0

        (0...(matches.size-1)).each do |i|
          matches[i].deltacn = matches[i+1].deltacn_orig 
        end
        matches[-1].deltacn = 1.1
      end
    end
    spectra
  end


  # returns an array -> [the next spectra line (or nil if eof), spectrum]
  def from_line(line)
    line.chomp!
    ar = line.split(SQT::Delimiter)
    self[0] = ar[1].to_i
    self[1] = ar[2].to_i
    self[2] = ar[3].to_i
    self[3] = ar[4].to_f
    self[4] = ar[5]
    self[5] = ar[6].to_f
    self[6] = ar[7].to_f
    self[7] = ar[8].to_f
    self[8] = ar[9].to_i
    self[9] = []
    self
  end
end

# SQT format uses only indices 0 - 9
SQT::Match = Arrayclass.new(%w[rxcorr rsp mh deltacn_orig xcorr sp ions_matched ions_total sequence manual_validation_status first_scan last_scan charge deltacn aaseq base_name loci])

# 0=rxcorr 1=rsp 2=mh 3=deltacn_orig 4=xcorr 5=sp 6=ions_matched 7=ions_total 8=sequence 9=manual_validation_status 10=first_scan 11=last_scan 12=charge 13=deltacn 14=aaseq 15=base_name 16=loci

# rxcorr = rank by xcorr
# rsp = rank by sp
# NOTE:
# deltacn_orig
# deltacn is the adjusted deltacn (like Bioworks - shift all scores up and
# give the last one 1.1)
class SQT::Match
  include SpecID::Pep
  Leader = 'M'

  # same as 'loci'
  def prots
    self[16]
  end

  def from_line(line)
    line.chomp!
    ar = line.split(SQT::Delimiter)
    self[0] = ar[1].to_i
    self[1] = ar[2].to_i
    self[2] = ar[3].to_f
    self[3] = ar[4].to_f
    self[4] = ar[5].to_f
    self[5] = ar[6].to_f
    self[6] = ar[7].to_i
    self[7] = ar[8].to_i
    self[8] = ar[9]
    self[9] = ar[10]
    self[14] = SpecID::Pep.sequence_to_aaseq(self[8])
    self
  end
end


class SQT::Match::Percolator < SQT::Match
  # we will keep access to these old terms since we can then access routines
  # that sort on xcorr...
  #undef_method :xcorr
  #undef_method :xcorr=
  #undef_method :sp
  #undef_method :sp=

  def percolator_score
    self[4]
  end
  def percolator_score=(score)
    self[4] = score
  end
  def negative_q_value
    self[5]
  end
  def negative_q_value=(arg)
    self[5] = arg
  end
  def q_value
    -self[5]
  end
  # for compatibility with scripts that want this guy
  def probability
    -self[5]
  end
end

SQT::Locus = Arrayclass.new(%w[locus description peps])

class SQT::Locus
  include SpecID::Prot
  Leader = 'L'
 
  def first_entry ; self[0] end
  def reference ; self[0] end

  def from_line(line)
    line.chomp!
    ar = line.split(SQT::Delimiter)
    self[0] = ar[1]
    self[1] = ar[2]
    self
  end

end
