require 'ostruct'
require 'set'
require 'hash_by'
require 'roc'
require 'sample_enzyme'  # for others
require 'spec_id/bioworks'
require 'spec_id/sequest'

require 'spec_id/proph/prot_summary'
require 'spec_id/proph/pep_summary'  

require 'spec_id_xml'
require 'spec_id/sqt'
require 'spec_id/mass'
require 'fasta'



module ProteinReferenceable ; end

class SampleEnzyme ; end


module SpecID ; end

class GenericSpecID ; include SpecID ; end

module SpecID
  MONO = Mass::MONO
  AVG = Mass::AVG
   
  attr_accessor :peps, :prots
  # True if a high protein/peptide score is better than low, false otherwise
  # This is set automatically for known file types
  attr_accessor :hi_prob_best

  # A relative pathname of the file the specid object is derived from
  attr_accessor :filename

  # tp = file_type
  # Will return a SpecID object (really, the object corresponding to the
  # file type which mixes in SpecID [is_a?(SpecID) == true])
  # If no file is given, will return a GenericSpecID object.
  # If file is an array, this is assumed to be a group of srf files which is
  # converted into an SRFGroup Ojbect and run.
  def self.new(file=nil, tp=nil)
    # this will need to be specialized for other groups later
    if file.is_a?(Array)
      # takes an array of srf filenames
      SRFGroup.new(file)
    elsif file 
      from_file(file, tp)
    else
      GenericSpecID.new      
    end
  end

  # tp = file_type
  # a single srf file will be packaged into an SRFGroup object
  def self.from_file(file, tp=nil)
    obj = nil
    unless tp
      tp = file_type(file)
    end
    obj = case tp
    when 'srf'
      #@hi_prob_best = false
      SRFGroup.new([file])
    when 'srg'
      #@hi_prob_best = false
      SRFGroup.new(file)
    when 'bioworks'
      #@hi_prob_best = false
      Bioworks.new(file)
    when 'protproph'
      #@hi_prob_best = true
      Proph::ProtSummary.new(file)
    when 'pepproph'
      Proph::PepSummary.new(file)
    when 'sqg'
      SQTGroup.new(file)
    when 'sqt'
      SQTGroup.new([file])
    else
      abort "UNRECOGNIZED file type for #{file}"
    end
    obj
  end

  def inspect
    peps_string =
      if peps
        "peps(#)=#{peps.size}"
      else
        "peps=(nil)"
      end
    "<#{self.class} #{peps_string}>"
  end

  # given some list of SpecID::Pep based objects, returns the list of proteins
  # associated with those peptides
  # kind must be a symbol:
  # :no_update (current proteins are returned, but their peps attribute
  # is not updated)
  # :update (current proteins returned with peps attribute updated)
  # :new (new proteins are created complete with peps attribute)
  def self.protein_list(pephits, kind=:no_update)

    orig_pephits_prts = []
    if kind == :new
      new_prots = {}
      pephits.each_with_index do |pep,i|
        orig_pephits_prts[i] = pep.prots
        peps_new_prts = pep.prots.map do |prt|
          if new_prots.key? prt.reference
            already_exists = new_prots[prt.reference]
          else
            np = prt.dup
            np.peps = []
            new_prots[np.reference] = np
            np
          end
        end
        pep.prots = peps_new_prts
      end
    end

    if kind == :update
      pephits.each do |pep|
        pep.prots.each do |prt|
          prt.peps = []
        end
      end
    end

    prot_set = {}
    pephits.each do |pep|
      prts = pep.prots
      prts.each do |prt|
        prot_set[ prt.reference ] = prt 
      end
      if (kind == :update || kind == :new)
        prts.each do |prt|
          prt.peps << pep
        end
      end
    end

    ## Reset the original protein hits
    if kind == :new
      pephits.each_with_index do |pep,i|
        pep.prots = orig_pephits_prts[i]
      end
    end

    prot_set.values
  end



  # takes a comma separated list  or array and extends the last to create an
  # array of desired size
  def self.extend_args(arg, desired_size)
    arg_arr = arg
    if arg.is_a? String
      arg_arr = arg.split(',')
    end
    new_arr = []
    last_arg = arg_arr[0]
    desired_size.times do |i|
      if arg_arr[i]
        new_arr[i] = arg_arr[i]
        last_arg = new_arr[i]
      else
        new_arr[i] = last_arg
      end
    end
    new_arr
  end

  # takes an array of proteins, each having peps
  # peptide grouping is done
  # by-
  # the protein with the most unique peptides ends up taking any
  # degenerate peptides, tie goes to one with most hits total, then the one
  # that had the top xcorr(s) (before removing any peptides).All other
  # proteins with identical peptides will lose those peptides.  So, the rich
  # stay rich, and the poor get poorer.
  # returns an array of triplets where each is [prot, pep_hits,
  # uniq_aaseqs] (uniq_aaseqs is an array) where the protein contains >= 1
  # peptide.  The internal links (prot.peps and pep.prots) is NOT modified!!
  # update_prots == true will set each protein with the peptides found
  def self.occams_razor(array_of_prots, update_prots=false)
    peps_found = Set.new 

    to_sort = array_of_prots.map do |prot|
      pps = prot.peps

      peps_by_uniq_aaseq = pps.hash_by(:aaseq)
      uniq_aaseqs = Set.new( pps.map {|pep| pep.aaseq } )
      xcorrs = pps.map {|pep| pep.xcorr }

      silly = OpenStruct.new
      # 0                1         2            3     4            5
      [uniq_aaseqs.size, pps.size, xcorrs.sort, prot, uniq_aaseqs, peps_by_uniq_aaseq] 
    end
    prot_triplets = []
    to_sort.sort.reverse.each do |ar|
      prot = ar[3]
      ## overlapping set:
      common = peps_found & ar[4]
      ## find the uniq ones in our little set of peptides:
      uniq = ar[4] - common
      pep_hits = []
      if uniq.size != 0
        ## add to the found list:
        peps_found.merge(uniq)
        uniq.each do |seq|
          pep_hits.push( *(ar[5][seq]) ) 
        end
        prot_triplets << [prot, pep_hits, uniq.to_a]
        prot.peps = pep_hits if update_prots 
      end
    end
    prot_triplets
  end

  # returns number of true positives (array) and the specified output (as
  # parallel array).  Requires the classification method and a sorted array of
  # tp values and an array fp values.
  # (This is simply a wrapper around ROC#by_tps method!)
  def by_tps(classification_method, tp, fp)
    ROC.new.by_tps(classification_method, tp, fp)
  end
  
  # from the unique set of peptide hits, create a separate peptide hit for
  # each protein reference where that peptide only references that protein
  # e.g. pep.prots = [(a single protein)]
  def pep_prots
    pps = []
    peps.each do |pep|
      pep.prots.map do |prt|
        pep.dup     
        pep.prots = [prt]
        pps << pep
      end
    end
    pps
  end

  def self.prots?(ar)
    ar.first.is_a? SpecID::Prot
  end

  def self.peps?(ar)
    ar.first.is_a? SpecID::Pep
  end

  # for older stuff
  def classify_by_regex(items, regex, decoy_on_match=true, ties=:both)
    objects = 
      case items
      when :prots
        prots
      when :peps
        peps
      end
    SpecID.classify_by_prot(objects, regex, decoy_on_match, ties)
  end

  # includes the peptide hit in both
  # returns (target, decoy)
  # (for peps) ties can be :both, true (target wins), false (decoy wins)
  # regardless of ties behavior, will partition out the proteins to be
  # appropriate for the peptide
  def self.classify_by_prot(items, regex, decoy_on_match=true, ties=:both)
    if items.size == 0
      return [[],[]]
    elsif prots?(items)
      myproc = proc { |prt| 
        if prt.reference =~ regex ; !decoy_on_match
        else ; decoy_on_match end 
      }
      return classify(items, myproc)
    elsif peps?(items)
      match = [] ; nomatch = []
      items.each do |pep| 
        (match_prots, nomatch_prots) = pep.prots.partition do |prot|
          prot.reference =~ regex
        end
        if match_prots.size == 0
          nomatch << pep
        elsif nomatch_prots.size == 0
          match << pep
        else ## both have hits
          pep.prots = match_prots
          nomatch_pep = pep.dup
          nomatch_pep.prots = nomatch_prots

          # resolve ties
          case ties
          when true
            if decoy_on_match
              nomatch << pep
            else
              match << pep
            end
          when false
            if decoy_on_match
              match << pep
            else
              nomatch << pep
            end
          when :both
            match << pep
            nomatch << pep
          else ; raise ArgumentError
          end
        end
      end
      if decoy_on_match
        return [nomatch , match]
      else
        return [match, nomatch]
      end
    else
      raise ArgumentError, "arg1 is ar of objects descended from SpecID::Prot/Pep"
    end
  end



  # returns [tp, fp] based on the protein prefix for items where items =
  # (:prot|:peps)
  # this may result in a duplication of some peptides if they match both
  # normal and decoy proteins.  In this case, the protein arrays are split,
  # too, so that each points only to its breed of protein. 
  def classify_by_decoy_flag(items, flag, decoy_on_match=true, prefix=false)
    if prefix
      regex = /^#{Regexp.escape(flag)}/ 
    else
      regex = /#{Regexp.escape(flag)}/ 
    end
    classify_by_regex(items, regex, decoy_on_match)
  end

  # Returns (match, nomatch)
  # items = symbol (:prots, :peps)
  # Returns two arrays, those returning true from classify_item_by and those
  # returning false 
  def classify(items, classify_item_by)
    its = send(items)
    f = []; t = []
    its.each do |it|
      if classify_item_by.call(it)
        t << it
      else
        f << it
      end
    end
    [t,f]
  end

  # returns two arrays, true positives and false positives (determined by proc
  # classify_item_by) sorted by proc rank_item_by.  Items will be ranked from
  # lowest to highest based on the return value of rank_item_by. items is a
  # symbol (:prots or :peps)
  def rank_and_classify(items, rank_item_by, classify_item_by)
    its = send(items)
    #its.each do |it| puts it.probability.to_s ; puts it.reference end
    doublets = its.collect do |item|
      [ rank_item_by.call(item),
        classify_item_by.call(item) ]
    end
    roc = ROC.new
    tp, fp = roc.doublets_to_separate(doublets)
    return tp, fp
  end


  # returns a proc for getting all probabilities so that an ascending sort
  # will put the best scores first
  def probability_proc
    if hi_prob_best
      get_prob_proc = proc {|prt| prt.probability * -1 }
    else
      get_prob_proc = proc {|prt| prt.probability }
    end
    get_prob_proc
  end

  def separate_by_prefix(items, fp_prefix)
    its = send(items)

    if items == :prots
    elsif items == :peps
      abort "not implemented yet"
    else
      abort "no other items recognized yet"
    end
  end

  # sorts the probabilities and then
  # calcs predicted number hits and precision for protein probabilities
  # (summing probabilities)
  # one_minus_ppv = SUM(1-probX)/#prots = what is commonly and mistakenly
  # called false positive rate
  # SUM(1-probX)/#prots
  def num_hits_and_ppv_for_protein_prophet_probabilities
    current_sum_one_minus_prob = 0.0
    num_prots = []
    ppv = []
    prot_cnt = 0
    probs = prots.map {|v| v.probability}
    sorted = probs.sort.reverse
    sorted.each do |prob|
      prot_cnt += 1
      num_prots << prot_cnt
      current_sum_one_minus_prob += 1.0 - prob
      ppv << 1.0 - ( current_sum_one_minus_prob / prot_cnt )
      # current_fpr_ratio = current_sum_one_minus_prob / prot_cnt
    end
    [num_prots, ppv]
  end

  # convenience method for the common task of determining precision for
  # proteins (with decoy proteins found by false_flag)
  # returns (num_hits, precision)
  def num_hits_and_ppv_for_prob(false_flag, prefix=false)
    if prefix
      regex = /^#{Regexp.escape(false_flag)}/ 
    else
      regex = /#{Regexp.escape(false_flag)}/ 
    end
    prob_proc = probability_proc
    myproc = proc { |prt| 
      if prt.reference =~ regex ; false
      else ; true end 
    }

    real_hits, decoy_hits = rank_and_classify(:prots, prob_proc, myproc)
    
    (num_hits, num_tps, precision) = DecoyROC.new.pred_and_tps_and_ppv(real_hits, decoy_hits)
    [num_hits, precision]
  end

#  # takes the existing spec_id object and marshals it into "file.msh"
#  # a new file will always look for a file.msh to load
#  def marshal(force=false)
#    if !(File.exist? @marshal_file)| force
#      File.open(@marshal_file, 'w') {|out| Marshal.dump(@obj, out) }
#    end
#  end

  # Returns 'bioworks' if bioworks xml, 'protproph' if Protein prophet
  # 'srf' if SRF file, 'srg' if search results group file.
  def self.file_type(file)
    if file =~ /\.srg$/
      return 'srg'
    elsif file =~ /\.sqg$/
      return 'sqg'
    end
    if IO.read(file, 7,438) == 'Enzyme:'
      return 'srf'
    end
    File.open(file) do |fh|
      lines = ""
      8.times { lines << fh.readline }
      if lines =~ /<bioworksinfo>/
        return 'bioworks'
      elsif ((lines =~ /<protein_summary/) and ((lines =~ Proph::ProtSummary::Filetype_and_version_re_old) or (lines =~ Proph::ProtSummary::Filetype_and_version_re_new)))
        return 'protproph'
      elsif lines =~ /<msms_pipeline_analysis.*<peptideprophet_summary/m
        return 'pepproph'
      end
      # assumes the header of a sqt file is less than 200 lines ...
      200.times do 
        line = fh.gets
        if line
          lines << line
        else ; break
        end
      end
      if lines =~ /^H\tDatabase/ and lines =~ /^H\tSQTGenerator/
        return 'sqt'
      end
    end
  end


  ##############################################
  # These are pretty specific to Smriti's needs:

  # Given a hash of peptide arrays by some attribute key
  # Return two sorted arrays of sorted probabilities
  # The first of the min and second of the best 10 of each peptide array
  def min_and_best10(hash)
    ## choose the min probability and sort by prob
    min_peptides = hash.collect do |k,v|
      v.min {|a,b| a.peptide_probability <=> b.peptide_probability }
    end
    #puts min_peptides[0] # -> Bioworks::Pep
    min_sorted_peps = sorted_probabilities(min_peptides)
    #puts min_sorted_peps[0] # -> probability (Float)

    peptides_by_tens = [] 
    hash.each do |k,v|
      arr = v.sort_by {|pep| pep.peptide_probability }.slice(0,10)
      peptides_by_tens.push(*arr)
    end

    top_10_sorted_peps = sorted_probabilities(peptides_by_tens)
    #puts top_10_sorted_peps[0] # -> float
    #puts "size: top_10_sorted_peps.size : #{top_10_sorted_peps.size}"
    #puts "size: min_sorted_peps.size : #{min_sorted_peps.size}"
    #p top_10_sorted_peps
    #p min_sorted_peps 
    return min_sorted_peps, top_10_sorted_peps
  end

  # Returns a list of sorted probabilities given the array of peptides
  def sorted_probabilities(peptides)
    #puts peptides.first.peptide_probability.class
    #peptides.each do |pep| print pep.class.to_s + " " end
    #puts peptides.first.is_a? Array
    #abort "DFHDFD"
    peptides.collect{|pep| pep.probability }.sort
  end

  # returns a sorted lists of probabilities based on all pepprots (a peptide
  # associated with a protein)
  def pep_probs_by_pep_prots
    sorted_probabilities(peps)
  end

  ##########################################################################
  # WARNING! These might be dangerous to your health if there are multiple
  # files collected in your bioworks file
  ##########################################################################
  
  # (prob_list_by_min, prob_list_by_best10)
  # returns 2 sorted lists of probabilities based on:
  #   1. best peptide hit
  #   2. top 10 peptide hits
  # on a per scan basis
  # NOTE: you may want to hash on base_name first!
  def pep_probs_by_scan
    hash = peps.hash_by(:first_scan, :last_scan)
    return min_and_best10(hash)
  end


  #(prob_list_by_min, prob_list_by_best10)
  # same as pep_probs_by_scan but per charge state
  # NOTE: you may want to hash on base_name first!
  def pep_probs_by_scan_charge
    hash = peps.hash_by(:first_scan, :last_scan, :charge)
    return min_and_best10(hash)
  end

  # (prob_list_by_min)
  # hashes on seq-charge and returns the sorted list of probabilities of top
  # hit per seq-charge
  # NOTE: you may want to hash on base_name first!
  def pep_probs_by_seq_charge
    hash = peps.hash_by(:sequence, :charge)
    min_peptides = hash.collect do |k,v|
      v.min {|a,b| a.peptide_probability <=> b.peptide_probability }
    end
    sorted_probabilities(min_peptides)
  end

  ##########################################################################
  # USE these if you have multiple files in your bioworks.xml file 
  ##########################################################################
  # (prob_list_by_min, prob_list_by_best10)
  # returns 2 sorted lists of probabilities based on:
  #   1. best peptide hit
  #   2. top 10 peptide hits
  # on a per scan basis
  # NOTE: you may want to hash on base_name first!
  def pep_probs_by_bn_scan
    hash = peps.hash_by(:base_name, :first_scan, :last_scan)
    return min_and_best10(hash)
  end


  #(prob_list_by_min, prob_list_by_best10)
  # same as pep_probs_by_scan but per charge state
  # NOTE: you may want to hash on base_name first!
  def pep_probs_by_bn_scan_charge
    hash = peps.hash_by(:base_name, :first_scan, :last_scan, :charge)
    return min_and_best10(hash)
  end

  # (prob_list_by_min)
  # hashes on seq-charge and returns the sorted list of probabilities of top
  # hit per seq-charge
  # NOTE: you may want to hash on base_name first!
  def pep_probs_by_bn_seq_charge
    hash = peps.hash_by(:base_name, :sequence, :charge)
    min_peptides = hash.collect do |k,v|
      v.min {|a,b| a.peptide_probability <=> b.peptide_probability }
    end
    sorted_probabilities(min_peptides)
  end
end

# A Generic spectraID protein
module SpecID::Prot
  include ProteinReferenceable

  # probability is always a float!
  attr_accessor :probability, :reference, :peps

  def <=> (other)
    self.reference <=> other.reference
  end

  def inspect
    pep_string = 
      if peps
      ", @peps(#)=#{peps.size}"
      end
    "<#{self.class} @probability=#{probability}, @reference=#{reference}#{pep_string}>"
  end
 
end

module SpecID::Pep

   Non_standard_amino_acid_char_re = /[^A-Z\.\-]/

  attr_accessor :prots
  attr_accessor :probability
  # full sequence: (<firstAA>.<sequence>.<last>) with '-' for no first
  # or last.
  attr_accessor :sequence

  # the basic amino acid sequence (no leading or trailing '.' or amino acids)
  # should not contain any special symbols, etc.
  attr_accessor :aaseq
  attr_accessor :charge

  # removes nonstandard chars with Non_standard_amino_acid_char_re
  # preserves A-Z and '.' and '-'
  def self.remove_non_amino_acids(sequence)
    sequence.gsub(Non_standard_amino_acid_char_re, '')
  end

  # remove_non_amino_acids && split_sequence
  def self.prepare_sequence(val)
    nv = remove_non_amino_acids(val)
    split_sequence(nv)
  end

  def <=>(other)
    aaseq <=> other.aaseq
  end

  # Returns prev, peptide, next from sequence.  Parse errors return
  # nil,nil,nil
  #   R.PEPTIDE.A  # -> R, PEPTIDE, A
  #   R.PEPTIDE.-  # -> R, PEPTIDE, -
  #   PEPTIDE.A    # -> -, PEPTIDE, A
  #   A.PEPTIDE    # -> A, PEPTIDE, -
  #   PEPTIDE      # -> nil,nil,nil
  def self.split_sequence(val)
    peptide_prev_aa = ""; peptide = ""; peptide_next_aa = ""
    pieces = val.split('.') 
    case pieces.size
    when 3
      peptide_prev_aa, peptide, peptide_next_aa = *pieces
    when 2
      if pieces[0].size > 1  ## N termini
        peptide_prev_aa, peptide, peptide_next_aa = '-', pieces[0], pieces[1]
      else  ## C termini
        peptide_prev_aa, peptide, peptide_next_aa = pieces[0], pieces[1], '-'
      end
    when 1  ## this must be a parse error!
      peptide_prev_aa, peptide, peptide_next_aa = nil,nil,nil
    when 0
      peptide_prev_aa, peptide, peptide_next_aa = nil,nil,nil
    end
    return peptide_prev_aa, peptide, peptide_next_aa
  end

  ## 
  def self.sequence_to_aaseq(sequence)
    after_removed = remove_non_amino_acids(sequence)
    pieces = after_removed.split('.') 
    case pieces.size
    when 3
      pieces[1]
    when 2
      if pieces[0].size > 1  ## N termini
        pieces[0]
      else  ## C termini
        pieces[1]
      end
    when 1  ## this must be a parse error!
      pieces[0] ## which is the peptide itself  
    else
      abort "bad peptide sequence: #{sequence}"
    end
  end

  # This will rapidly determine the list of proteins for which given
  # peptides belong.  It is meant to be low level and fast (eventually),
  # so it asks for the data in a format amenable to this.
  # returns a mirror array where each entry is an array of Fasta::Prot
  # objects where each protein contains the sequence
  def self.protein_groups_by_sequence(peptide_strings_list, fasta_obj)
    prots = fasta_obj.prots
    prot_seqs = prots.map do |prot|
      prot.aaseq
    end

    groups = peptide_strings_list.map do |pep_seq|
      prot_index = 0
      protein_group = []
      prot_seqs.each do |prot_seq|
        if prot_seq.include? pep_seq
          protein_group << prots[prot_index]
        end
        prot_index += 1
      end
      protein_group
    end

    groups
  end

  # units can be :mmu, :amu, :ppm
  def mass_accuracy(pep, unit=:ppm, mono=true)
    # 10^6 * deltam accuracy/ m[measured]
    # i.e., theoretical mass 1000, measured 999.9: 100ppm
    # http://www.waters.com/WatersDivision/ContentD.asp?watersit=EGOO-66LRQD
    # pep.mass is the theoretical M+H of the peptide
    # this assumes that the deltacn value we're being told is correct, but I
    # have my suspicions (since the <mass> value is not accurate...)

    ######## TO COMPLETE (and add to spec_id..?)
    case unit
    when :ppm
    when :amu
    when :mmu
    end
  end

  # calls the method associated with each key and returns the value
  def values_at(*args)
    args.map do |arg|
      send(arg)
    end
  end

  def inspect

    prot_string = 
      if prots
      ", @prots(#)=#{prots.size}"
      end
    "<#{self.class} @probability=#{probability}, @sequence=#{sequence}, @aaseq=#{aaseq}, @charge=#{charge}#{prot_string}>"
  end

end

class SpecID::GenericProt
  include SpecID::Prot
end

class SpecID::GenericPep 
  include SpecID::Pep
end



