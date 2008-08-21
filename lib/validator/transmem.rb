require 'validator'
require 'validator/digestion_based'
require 'transmem'
require 'fasta'
require 'spec_id/digestor'
require 'spec_id/sequest/params'
require 'spec_id/sequest/pepxml'


module Validator::Transmem ; end

# objects of this class can calculate pephit_precision given an array of
# SpecID::Pep objects using the pephit_precision method.
class Validator::Transmem::Protein < Validator::DigestionBased
  include Precision::Calculator

  # a hash keyed by index reference which is true if >= min_num_tms
  attr_accessor :transmem_by_ti_key
  attr_accessor :transmem_index

  # min_num_tms: Integer (1...), the min # certain transmembrane segments to
  # consider the protein a transmembrane protein
  attr_reader :min_num_tms

  # soluble_fraction: *true/false
  attr_accessor :soluble_fraction

  # correct_wins: *true/false,
  #   if the peptide is found in some proteins that are transmembrane and some
  #   that are not, then if soluble_fraction==true, this peptide will be
  #   considered non-transmembrane.  If soluble_fraction==false, then this
  #   will be considered transmembrane.
  attr_accessor :correct_wins

  # no_include_tm_peps: false or Float (0.0-1.0), peptides that have a
  #   fraction of amino acids that fall inside transmembrane sequences greater
  #   than or equal to the value of the argument will not be considered in the final
  #   calculation of peptide hit precision.  (A transmembrane segment is
  #   likely to have very different properties than the rest of the peptides,
  #   so the assumption of equally flyable peptides is broken unless these are
  #   removed)  nil or false will skip this filter.  A reasonable value is
  #   probably 0.7.
  attr_accessor :no_include_tm_peps

  # if nil, then this will be calculated whe pephit_precision is called.
  attr_accessor :transmem_status_hash

  # the file used (toppred or phobius file)
  attr_accessor :transmem_file

  DEFAULTS = Validator::DigestionBased::DEFAULTS.merge( { :min_num_tms => 1, :soluble_fraction  =>  true, :correct_wins  =>  true, :no_include_tm_peps => false, :transmem_status_hash => nil} )

  # expects a toppred.out file (see transmem/toppred)
  # other types of transmembrane predictions)
  # fasta_obj is a Fasta object.
  # sequest_params_obj is a Sequest::Params object.
  # OPTIONS:
  #   (see Validator::Transmem::Protein::DEFAULTS for defaults)
  #   
  #   no_include_tm_peps: *false
  #   
  # NOTE: if fasta_obj and sequest_params_obj are not passed in then
  #   'false_to_total_ratio' must be set later.
  def initialize(a_transmem_file, options={})
    @transmem_file = a_transmem_file
    opts = self.class::DEFAULTS.merge(options)

    (@min_num_tms, @soluble_fraction, @correct_wins, @no_include_tm_peps, @background, @transmem_status_hash, @false_to_total_ratio, fasta) = opts.values_at(:min_num_tms, :soluble_fraction, :correct_wins, :no_include_tm_peps, :background, :transmem_status_hash, :false_to_total_ratio, :fasta)

    # fasta object is used to update hte phobius index if given
    # a hash by reference => true/false (depending on min_num_tms)
    @transmem_index = TransmemIndex.new(@transmem_file, fasta)
    @transmem_by_ti_key = create_transmem_by_ti_key_hash(@transmem_index, @min_num_tms)
  end

  # Designates each protein as transmembrane or not depending on :min_num_tms
  # The hash is keyed by the TransmemIndex key.
  def create_transmem_by_ti_key_hash(transmem_index, min_num_tms)
    _transmem_by_ti_key = {}
    num_certain_hash = transmem_index.num_certain_index
    num_certain_hash.each do |id, num_certain|
      if num_certain >= min_num_tms
        _transmem_by_ti_key[id] = true
      else
        _transmem_by_ti_key[id] = false
      end
    end
    _transmem_by_ti_key
  end

  # returns a hash where each protein (and peptide if given peps) is indexed
  # with itself with true/false/nil depending on transmembrane status.  If
  # given peptides, and :no_include_tm_peps is not false, will also set the
  # attribute for peptides.
  # the attribute (:no_include_tm_peps)
  # NOTE: if given a list of peptides, this implementation will not overwrite a
  # protein if it already has a true/false for transmem.  This is so that a
  # lookup does not have to be performed if the value is already defined as
  # the assumption is that many peptides will point to the same protein.
  def create_transmem_status_hash(peps)
    thash = {}
    peps.each do |pep|
      pep.prots.each do |prot|
        if !thash.key?(prot)
          #prot.transmem == nil
          thash[prot] = @transmem_by_ti_key[@transmem_index.reference_to_key(prot.reference)]
        end
      end
      if @no_include_tm_peps
        thash[pep] = pep_is_transmem?(pep)   
      end
    end
    thash
  end

  # sets the false_to_total_ratio and returns self for chaining.
  # peps will usually be the peptides created by calling:
  #     peps = Digestor.digest( fasta_obj, sequest_params_obj )
  def set_false_to_total_ratio(peps)
    tm_hash = create_transmem_status_hash(peps)
    (tps, fps) = partition(peps, tm_hash)
    @false_to_total_ratio = fps.size.to_f / (tps.size + fps.size) 
    self
  end

  def pephit_precision(peps)
    if !@transmem_status_hash
      @transmem_status_hash = create_transmem_status_hash(peps)
    end
    super(peps)
  end

  # regardless of transmembrane status of proteins peptide belongs to, asks
  # what the avg overlap is with transmembrane sequences.
  def pep_is_transmem?(pep)
    prts = pep.prots
    prts_w_keys = 0
    sum_of_fractions = 0.0
    prts.each do |prot| 
      key = @transmem_index.reference_to_key(prot.reference)
      ans = @transmem_index.avg_overlap(key, pep.aaseq, :fraction)
      if ans
        sum_of_fractions += ans
        prts_w_keys += 1
      end
    end
    if prts_w_keys > 0
      avg_of_fractions = sum_of_fractions / prts_w_keys
      avg_of_fractions >= @no_include_tm_peps
    else
      nil
    end
  end

  # each peptide must have prots and the prots must respond true/false to
  # the 'transmem' method
  # if given a hash, it will override the @transmem_status_hash
  def partition(peps, transmem_status_hash=nil)
    # The fast way to do this is to play with the logic
    # For the insoluble fraction we calculate as if incorrect wins
    # and swap the tp's and fp's (I've verified that this is correct
    # empirically)

    # the code could be cleaner here, but efforts to minimize calls in the
    # inner loops create this structure...
    tm_hash = transmem_status_hash || @transmem_status_hash

    my_peps = 
      if @no_include_tm_peps
        # remove all thos peps with fractional overlap >= @no_include
        # [1,2,3,4].reject {|n| n >= 3}  #-> [1, 2]
        # remove pep.transmem == true and pep.transmem == nil
        
        if tm_hash
          peps.reject do |pep|
            tm_hash[pep] != false 
          end
        else
          peps.reject do |pep|
            pep_is_transmem?(pep) != false 
          end
        end
      else
        peps
      end
    cw = @correct_wins
    sf = @soluble_fraction
    if !sf
      cw = !cw
    end

    tp = []
    fp = []

    if cw
      my_peps.each do |pep|
        one_prot_is_not_transmem = false
        not_all_nil = false
        if tm_hash
          pep.prots.each do |prot|
            tm_status = tm_hash[prot]
            if tm_status == false
              one_prot_is_not_transmem = true  
              break
            elsif tm_status == true
              not_all_nil = true
            end
          end
        else
          pep.prots.each do |prot|
            tm_status = @transmem_by_ti_key[@transmem_index.reference_to_key(prot.reference)]
            if tm_status == false
              one_prot_is_not_transmem = true  
              break
            elsif tm_status == true
              not_all_nil = true
            end
          end
        end
        if one_prot_is_not_transmem
          tp << pep
        else
          if not_all_nil
            fp << pep
          end
        end
      end
    else
      my_peps.each do |pep|
        one_prot_is_transmem = false
        not_all_nil = false
        if tm_hash
          pep.prots.each do |prot|
            tm_status = tm_hash[prot]
            if tm_status == true
              one_prot_is_transmem = true  
              break
            elsif tm_status == false
              not_all_nil = true
            end
          end
        else
          pep.prots.each do |prot|
            tm_status = @transmem_by_ti_key[@transmem_index.reference_to_key(prot.reference)]
            if tm_status == true
              one_prot_is_transmem = true  
              break
            elsif tm_status == false
              not_all_nil = true
            end
          end
        end
        if one_prot_is_transmem
          fp << pep
        else
          if not_all_nil
            tp << pep
          end
        end
      end
    end
    if !sf # swap
      fp,tp = tp,fp
      cw = !cw
    end
    #puts "PARTITION ARRAY"
    #p [tp, fp].map{|v| v.size}
    [tp, fp]
  end

end

