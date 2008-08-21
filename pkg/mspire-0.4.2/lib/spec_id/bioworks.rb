

require 'sample_enzyme'
require 'xmlparser'
require 'spec_id'
require 'zlib'
require 'hash_by'
require 'arrayclass'
require 'fasta'

## have to pre-declare some guys
module ProteinReferenceable; end
module SpecID; end
module SpecID::Prot; end
module SpecID::Pep; end
module SpecIDXML; end

class Bioworks
  include SpecID

  # Regular expressions
  @@bioworksinfo_re = /<bioworksinfo>(.*)<\/bioworksinfo>/o
  @@modifications_re = /<modifications>(.*)<\/modifications>/o
  @@protein_re = /<protein>/o
  @@origfilename_re = /<origfilename>(.*)<\/origfilename>/o
  @@origfilepath_re = /<origfilepath>(.*)<\/origfilepath>/o


  attr_accessor :peps, :prots, :version, :global_filename, :origfilename, :origfilepath
  # a string of modifications e.g., "(M* +15.99491) (S@ +14.9322) "
  attr_accessor :modifications

  def hi_prob_best ; false end

  # -> prints to file filename1.sqt, filename2.sqt
  # @TODO: sqt file output
  def to_sqt(params_file)
    ## hash peps by filename 
    ## hash prots by peptide
  end

  # returns the number of prots.  Raises an Exception if open and closing xml
  # tags don't agree
  def num_prots(file)
    re = /(<protein>)|(<\/protein>)/mo
    begin_tags = 0
    end_tags = 0
    IO.read(file).scan(re) do |match| 
      if match.first
        begin_tags += 1
      else
        end_tags += 1
      end
    end
    if begin_tags != end_tags 
      puts "WARNING: #{file} doesn't have matching closing tags"
      puts "for the <protein> tag.  Returning # of beginning tags."
    end
    begin_tags
  end



  # Outputs the bioworks browser excel format (tab delimited) to file.
  # Useful if you have more than ~65,000 lines (can export bioworks.xml 
  # and then convert to excel format).
  # Currently, the only things not precisely identical are:
  #   1. The peptide hit counts (although the first number [total # peptides] is accurate)
  #   2. The precise ordering of peptides within each protein.  When dealing with output from multiple runs, peptides with runs with exactly the  same scan numbers are not guaranteed to be in the same order.
  def to_excel(file)
    update_peptide_hit_counts
    arr = []
    arr << ['', 'Reference', '', '', '', 'Score', 'Coverage', 'MW', 'Accession', 'Peptide (Hits)', '', ' ']
    arr << ['', '"File, Scan(s)"', 'Peptide', 'MH+', 'z', 'XC', 'DeltaCn', 'Sp', 'RSp', 'Ions', 'Count', ' ']
    @prots.each_with_index do |prot,index|
      line_arr = prot.get(:consensus_score, :coverage, :weight, :accession)
      if line_arr[1] == "0.0" then line_arr[1] = "" end
      line_arr.unshift('', '', '')
      line_arr.unshift('"' + prot.reference.split('|')[-1] + '"')
      line_arr.unshift(index+1)
      pep_hit_counts = prot.peptide_hit_counts
      pep_hit_counts_string = pep_hit_counts[0].to_s + ' (' + pep_hit_counts[1..-1].join(" ") + ')' 
      line_arr.push( pep_hit_counts_string )
      line_arr.push("")
      line_arr.push(" ")
      arr.push( line_arr )
      prot.peps.sort_by{|obj| [obj.first_scan.to_i, obj.last_scan.to_i] }.each do |pep|

        pep_arr = pep.get(:sequence, :mass, :charge, :xcorr, :deltacn, :sp, :rsp, :ions)
        count = pep.count
        if count == '0' then count = "" end
        pep_arr.push(count)
        pep_arr.push(' ')
        pep_arr.unshift('"' + pep.file + '"')
        pep_arr.unshift( '' )
        arr.push( pep_arr )
      end
    end
    File.open(file, "w") do |out|
      arr.each do |line|
        out.print(line.join("\t"), "\n")
      end
    end

  end

  # for output to excel format or other things, updates each protein
  # with a peptide hit count array based on ranking of xcorr per dta file
  # where each array is the total number of peptide hits, then rank 1,2,3,4,5
  # @TODO: Can't get this to check out yet.  Perhaps they use normalized
  # Xcorr?
  def update_peptide_hit_counts
    @prots.each do |prot|
      prot.peptide_hit_counts[0] = prot.peps.size
    end
    hash = peps.hash_by(:file)
    hash.sort.each do |k,v|
      sorted = v.sort_by {|obj| obj.xcorr.to_f }
      peps, prot_groups = _uniq_peps_by_sequence_charge(sorted) ## but not on prot!!!!!uniq_peps_by_sequence_charge!

      prot_groups.each_with_index do |prot_group, i|
        prot_group.each do |prot|
          prot.peptide_hit_counts[i+1] += 1 if prot.peptide_hit_counts[i+1]
        end
      end
    end
  end

  # returns (peptides, proteins) where peptides is the unique list of peps
  # and proteins is a parallel array of arrays of represented proteins
  # note that each pep will contain its original prot it belongs to, even
  # though the parallel protein actually represents the proteins it belongs
  # to.
  # assumes that each peptide points to all its proteins in pep.prots
  def _uniq_peps_by_sequence_charge(peps)
    new_arr = []
    prot_arr = []
    index_accounted_for = []
    (0...peps.size).each do |i|
      next if index_accounted_for.include?(i)
      new_arr << peps[i]
      prot_arr.push( peps[i].prots )
      ((i+1)...peps.size).each do |j|
        pep1, pep2 = peps[i], peps[j]
        if pep1.sequence == pep2.sequence && pep1.charge == pep2.charge
          prot_arr.last.push( *(pep2.prots) )
          index_accounted_for << j
        end
      end
    end
    return new_arr, prot_arr
  end

  def initialize(file=nil)
    @peps = nil
    if file
      @filename = file
      parse_xml(file)
      #parse_xml_by_xmlparser(file)
    end
  end

  def parse_xml_by_xmlparser(file)
    parser = Bioworks::XMLParser.new
    File.open(file) do |fh|
      #3.times do fh.gets end  ## TEMPFIX
      parser.parse(fh)
    end
    #puts "ETETWSST"
    #p parser.prots
    @prots = parser.prots
  end

  # This is highly specific to Bioworks 3.2 xml export.  In other words,
  # unless the newlines, etc. are duplicated, this parser will fail! Not
  # robust, but it is faster than xmlparser (which is based on the speedy
  # expat)
  def parse_xml(file)
    fh = nil
    if file =~ /\.gz$/
      fh = Zlib::GzipReader.open(file)  
    else
      fh = File.open(file)
    end
    @origfilename = get_regex_val(fh, @@origfilename_re)
    @origfilepath = get_regex_val(fh, @@origfilepath_re)
    if @origfilename
      @global_filename = @origfilename.gsub(File.extname(@origfilename), "")
    end
    @version = get_regex_val(fh, @@bioworksinfo_re)
    @modifications = get_regex_val(fh, @@modifications_re)
    @prots, @peps = get_prots_from_xml_stream(fh)
    fh.close
  end

  ## returns proteins and peptides
  def get_prots_from_xml_stream(fh)
    uniq_pephit_hash = {}
    prots = []
    while line = fh.gets
      if line =~ @@protein_re
        prot =  Bioworks::Prot.new
        prot.bioworks = self
        prot.set_from_xml_stream(fh, uniq_pephit_hash)
        prots << prot
      end
    end
    [prots, uniq_pephit_hash.values] 
  end

  # gets the regex and stops (and rewinds if it hits a protein)
  # if no regex is found, returns nil and rewinds the filehandle
  def get_regex_val(fh, regex)
    ver = nil
    last_pos = fh.pos
    while line = fh.gets
      if line =~ regex
        ver = $1.dup     
        break
      elsif line =~ @@protein_re
        fh.seek last_pos
        break
      end
      last_pos = fh.pos
    end
    unless ver then fh.rewind end
    ver
  end

  # Outputs sequest xml files (pepxml) for the trans-proteomics pipeline
  def to_pepxml
    string = xml_version
    string 
  end

end

# Implements fast parsing via XMLParser (wrapper around Expat)
# It is actually slower (about %25 slower) than regular expression parsing
class Bioworks::XMLParser < XMLParser
  @@at = '@'
  attr_accessor :prots

  def initialize
    @current_obj = nil
    @current_hash = {}
    @current_name = nil
    @current_data = nil
    @prots = []
  end

  def startElement(name, attrs)
    case name
    when "peptide"
      curr_prot = @current_obj
      if @current_obj.class == Bioworks::Prot
        @current_obj.set_from_xml_hash_xmlparser(@current_hash)
      else
        curr_prot = @current_obj.prot  ## unless previous was a peptide
      end
      peptide = Bioworks::Pep.new
      peptide.prot = curr_prot
      curr_prot.peps << peptide
      @current_obj = peptide
      @current_hash = {}
    when "protein"
      @current_obj = Bioworks::Prot.new
      @current_hash = {}
      @prots << @current_obj
    else
      @current_name = name  
    end
  end

  def endElement(name)
    case name
    when "peptide"
      @current_obj.set_from_hash_given_text(@current_hash)
    when "protein"
    else
      @current_hash[name] = @current_data
    end
  end
  
  def character(data)
    @current_data = data
  end

end

module Bioworks::XML
  # The regular expression to grab attributes from the bioworks xml format
  @@att_re = /<([\w]+)>(.*)<\/[\w]+>/o
end

class Bioworks::Prot
  include ProteinReferenceable
  include SpecID::Prot
  include Bioworks::XML

  @@end_prot_re = /<\/protein>/o
  @@pep_re = /<peptide>/o
  @@atts = %w(reference protein_probability consensus_score sf unified_score coverage pi weight accession peps) 
  attr_accessor :reference, :protein_probability, :consensus_score, :sf, :unified_score, :coverage, :pi, :weight, :accession, :peps, :bioworks, :peptide_hit_counts

  def initialize
    @peps = []
    @peptide_hit_counts = [0,0,0,0,0,0]
  end


  # returns array of values of the attributes given (as symbols)
  def get(*args)
    args.collect do |arg|
      send(arg)
    end
  end

  def set_from_xml_stream(fh, uniq_pephit_hash)
    hash = {}
    @peps = []
    while line = fh.gets
      if line =~ @@att_re
        hash[$1] = $2
      elsif line =~ @@pep_re
        ## Could do a look ahead to grab the file and sequence to check
        ## uniqueness to increase speed here.
        pep = Bioworks::Pep.new.set_from_xml_stream(fh)
        # normal search results files have a global filename
        # while multi-consensus do not
        pep[12] ||= bioworks.global_filename

        ## figure out uniqueness 
        ky = [pep.base_name, pep.first_scan, pep.charge, pep.sequence]
        if uniq_pephit_hash.key? ky
          pep = uniq_pephit_hash[ky]
        else
          ## insert the new protein
          pep.prots = []
          uniq_pephit_hash[ky] = pep
        end
        pep.prots << self
        @peps << pep
        
      elsif line =~ @@end_prot_re
        set_from_xml_hash(hash)
        break
      else
        puts "Bad parsing on: #{line}"
        puts "EXITING!"
        exit
      end
    end
    self
  end

  def set_from_xml_hash_xmlparser(hash)
    hash.delete("sequestresults")
    hash.delete("bioworksinfo")
    hash["sf"] = hash.delete("Sf")
    hash["pi"] = hash.delete("pI")
    set_from_xml_hash(hash)
  end

  # changes the sf to Sf and pI to pi
  def set_from_xml_hash(hash)
    @reference = hash["reference"]
    @protein_probability = hash["protein_probability"].to_f
    #@probability = @protein_probability.to_f
    @consensus_score = hash["consensus_score"].to_f
    @sf = hash["Sf"].to_f
    @unified_score = hash["unified_score"].to_f
    @coverage = hash["coverage"].to_f
    @pi = hash["pI"].to_f
    @weight = hash["weight"].to_f
    @accession = hash["accession"]
  end
end

Bioworks::Pep = Arrayclass.new( %w(sequence mass deltamass charge xcorr deltacn sp rsp ions count tic prots base_name first_scan last_scan peptide_probability file _num_prots _first_prot aaseq) )
# 0=sequence 1=mass 2=deltamass 3=charge 4=xcorr 5=deltacn 6=sp 7=rsp 8=ions 9=count 10=tic 11=prots 12=base_name 13=first_scan 14=last_scan 15=peptide_probability 16=file 17=_num_prots 18=_first_prot 19=aaseq

class Bioworks::Pep
  include SpecID::Pep
  include Bioworks::XML
  include SpecIDXML

  @@file_split_first_re = /, /o
  @@file_split_second_re = / - /o
  #@@att_re = /<(.*)>(.*)<\/(.*)>/
  @@end_pep_re = /<\/peptide>/o
  @@file_one_scan_re = /(.*), (\d+)/o
  @@file_mult_scan_re = /(.*), (\d+) - (\d+)/o
  ## NOTE! the mass is really the theoretical MH+!!!!
  ## NOTE! ALL values stored as strings, except peptide_probability!

  #ions is a string 'x/y'

  ## other accessors:
  def probability ; self[15] end
  def mh ; self[1] end

  # This is not a true ppm since it should be divided by the actual mh instead
  # of the theoretical (but it is as close as we can get for this object)
  def ppm 
    1.0e6 * (self[2].abs/self[1])
    #1.0e6 * (self.deltamass.abs/self.mh)
  end

  # returns array of values of the attributes given (as symbols)
  def get(*args)
    args.collect do |arg|
      send(arg)
    end
  end




  #def peptide_probability=(prob)
  #  @peptide_probability = prob.to_f
  #end

  # takes arguments in one of two forms:
  #   1. file, first_scan[ - last_scan]
  #   2. scan[ - last_scan]
  # returns base_name, first_scan, last_scan 
  # base_name will be set for #1, nil for #2
  def self.extract_file_info(arg)
    last_scan = nil
    (base_name, first_scan) = arg.split(@@file_split_first_re)
    unless first_scan
      first_scan = base_name
      base_name = nil
    end
    first_scan = first_scan.split(@@file_split_second_re)
    if first_scan.size > 1
      (first_scan, last_scan) = first_scan
    else
      first_scan = first_scan[0]
      last_scan = first_scan
    end
    [base_name, first_scan, last_scan]
  end

  tmp_verb = $VERBOSE
  $VERBOSE = nil
  def file=(arg)
    ## Set these vals by index:
    #puts "AERRG: #{arg}"
    self[16] = arg
    self[12,3] = self.class.extract_file_info(arg)
  end
  $VERBOSE = tmp_verb
  
  undef_method :inspect
  def inspect
    "<Bioworks::Pep sequence: #{sequence}, mass: #{mass}, deltamass: #{deltamass}, charge: #{charge}, xcorr: #{xcorr}, deltacn: #{deltacn}, prots(count):#{prots.size}, base_name: #{base_name}, first_scan: #{first_scan}, last_scan: #{last_scan}, file: #{file}, peptide_probability: #{peptide_probability}, aaseq:#{aaseq}>"


  end

  # if cast == true, then all the data will be cast
  def set_from_hash_given_text(hash)
    self[0,11] = [hash["sequence"], hash["mass"].to_f, hash["deltamass"].to_f, hash["charge"].to_i, hash["xcorr"].to_f, hash["deltacn"].to_f, hash["sp"].to_f, hash["rsp"].to_i, hash["ions"], hash["count"].to_i, hash["tic"].to_i]
    self.file = hash["file"]
    self[15] = hash["peptide_probability"].to_f
    self[19] = SpecID::Pep.sequence_to_aaseq(self[0])  ## aaseq
  end

  def set_from_xml_stream(fh)
    hash = {}
    while line = fh.gets
      if line =~ @@att_re
        #hash[$1] = $2.dup
        hash[$1] = $2
        #puts "IN PEP: " + $1 + ": " + $2
      elsif line =~ @@end_pep_re
        set_from_hash_given_text(hash)
        #puts "SELF[12]: #{self[12]}"
        #puts "SELF[12]: #{self[12]}"
        break
      else
        puts "Bad parsing on: #{line}"
        puts "EXITING!"
        exit
      end
    end
    self
  end

end





