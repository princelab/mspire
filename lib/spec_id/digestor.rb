
require 'spec_id/sequest/pepxml'
require 'spec_id/mass'

# A digestor must be able to respond to these methods:
class Digestor

  # min_mh_mass = min molecular mass of peptide (M+H)+
  attr_accessor :min_mh_mass
  # max_mh_mass = max molecular mass of peptide (M+H)+
  attr_accessor :max_mh_mass
  # the number of allowable missed cleavages
  attr_accessor :missed_cleavages
  # sample_enzyme = SampleEnzyme object
  attr_accessor :sample_enzyme
  # hash of masses to use (matching keys of Mass::AVG or Mass::MONO)
  # In addition, the following keys (as symbols) are recognized.
  # add_C_term_protein
  # add_C_term_peptide
  # add_N_term_protein
  # add_N_term_peptide
  attr_accessor :mass_hash

  # returns a list of peptide objects created from a digestion of the fasta
  # proteins using the sequest params (variable mods not supported yet)
  def self.digest(fasta_obj, params_obj)
    dig = self.new
    dig.set_from_params(params_obj)
    dig.create_peptide_hash(fasta_obj).values
  end

  def initialize
  end

  # takes a parameters object and fills in the necessary values
  def set_from_params(params_obj, include_variable_mods=false)
    raise NotImplementedError, "no variable mods yet" if include_variable_mods
    if params_obj.is_a? Sequest::Params 
      @sample_enzyme = params_obj.sample_enzyme
      @missed_cleavages = params_obj.max_num_internal_cleavage_sites.to_i
      (@min_mh_mass, @max_mh_mass) = params_obj.digest_mass_range.split(' ').map {|v| v.to_f }
      (static_mods, static_terminal_mods) = Sequest::PepXML::Modifications.new.create_static_mods(params_obj)
      monoisotopic_parents = case params_obj.mass_type_parent
                             when '0' ; false
                             when '1' ; true
                             end

      @mass_hash = Mass.add_static_masses(monoisotopic_parents, static_mods, static_terminal_mods)
    else 
      raise ArgumentError, "Don't recognize params object of type: #{params_obj.class}"
    end
  end

  # aka 'digestion'
  # will return a hash of SpecID::GenericPep objects (with 'aaseq' and
  # 'prots') hashed by aminoacid sequence.  The prot will be the fasta object.
  def create_peptide_hash(fasta_obj)
    pep_to_prots_hash = {}
    pep_objs = nil
    pep_aaseqs_ar = fasta_obj.map do |prot|
      @sample_enzyme.digest(prot.aaseq, @missed_cleavages)
    end
    prot_aaseqs = fasta_obj.map {|prot| prot.aaseq }
    passing_pep_seqs_ar = limit_sizes(prot_aaseqs, pep_aaseqs_ar, @min_mh_mass, @max_mh_mass, @mass_hash)
    #pep_aaseqs_ar.each_with_index do |before_peps,i|
    #  after_peps = passing_pep_seqs_ar[i]
    #  puts "before: #{before_peps.size} after: #{after_peps.size}"
    #  puts "Losing: #{(before_peps - after_peps).inspect}"
    #  puts "Keeping: #{after_peps.inspect}"
    #end
    fasta_obj.each_with_index do |prot, i|
      pep_seqs = passing_pep_seqs_ar[i]
      pep_seqs.each do |pep_seq|
        pep_obj = 
          if pep_to_prots_hash.key?(pep_seq)
            pep_to_prots_hash[pep_seq]
          else
            pep_ob = SpecID::GenericPep.new
            pep_ob.prots = []
            pep_ob.aaseq = pep_seq
            pep_to_prots_hash[pep_seq] = pep_ob
          end
        pep_obj.prots << prot
      end
    end
    #pep_to_prots_hash.each do |k,v|
    #  p v.aaseq
    #  puts v.prots.size
    #end
    pep_to_prots_hash
  end

  # min max are both in terms of the M+H(+)
  # 
  # h_plus:
  #   On this website:
  #   http://db.systemsbiology.net:8080/proteomicsToolkit/FragIonServlet.html
  #   They use the mass of 'H' not 'H+' to find the (M+H)+ weight.
  #
  #   The prot_aaseq is used if the mass_hash contains the keys
  #   :add_C_term_protein or :add_N_term_protein
  #
  #   mass_hash requires the key :h_plus or :h depending on h_plus option.
  #   prot_aaseqs is parallel to pep_aaseqs_ar where each is a group of
  #   peptides matching a protein aaseq
  #   returns another parallel array of passing peptides per protein
  def limit_sizes(prot_aaseqs, pep_aaseqs_ar, min_mh, max_mh, mass_hash, h_plus=false)
    if mass_hash.key?(:add_C_term_protein) or mass_hash.key?(:add_N_term_protein)
      raise NotImplementedError, "need to add ability to change weights of peptides from the ends of proteins"
    else
      # figure out how much must be added to each peptide
      # include the h2o, the h, and N and C terminal static mods
      h_plus_key = h_plus ? :h_plus : :h
      extra_add = mass_hash[h_plus_key]
      [:add_N_term_peptide, :add_C_term_peptide].each do |sym|
        if mass_hash.key?(sym)
          extra_add += mass_hash[sym]
        end
      end
      mc = Mass::Calculator.new(mass_hash, extra_add)
      
      masses_per_group = pep_aaseqs_ar.map do  |pep_aaseqs|
        mc.masses(pep_aaseqs)
      end

      masses_per_group.zip(pep_aaseqs_ar).map do |masses, aaseqs|
        passing = []
        aaseqs.zip(masses) do |aaseq, mh_plus|
          if ( (mh_plus >= min_mh) and (mh_plus <= max_mh) )
            passing << aaseq
          end
        end
        passing
      end
    end
  end

end
