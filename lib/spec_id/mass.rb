
class Mass
  # http://expasy.org/tools/findmod/findmod_masses.html
  # still need to add the modifications
  MONO = {
    :A => 71.03711,
    :R => 156.10111,
    :N => 114.04293,
    :D => 115.02694,
    :C => 103.00919,
    :E => 129.04259,
    :Q => 128.05858,
    :G => 57.02146,
    :H => 137.05891,
    :I => 113.08406,
    :L => 113.08406,
    :K => 128.09496,
    :M => 131.04049,
    :F => 147.06841,
    :P => 97.05276,
    :S => 87.03203,
    :T => 101.04768,
    :W => 186.07931,
    :Y => 163.06333,
    :V => 99.06841,

     # uncommon
    :B => 172.048405, # average of aspartic acid and asparagine
    :U => 150.95364,   # (selenocysteine) http://www.matrix-science.com/help/aa_help.html
    :X => 118.805716,  # the average of the mono masses of the 20 amino acids
    :* => 118.805716, # same as X
    :Z => (129.04259 + 128.05858) / 2,  # average glutamic acid and glutamine

    # elements etc.
    :h => 1.00783,
    #:h_plus => 1.00728,  # this is the mass I had
    :h_plus => 1.007276,  # this is the mass used by mascot merge.pl
    :o => 15.9949146,
    :h2o => 18.01056,
  }
  AVG = {
    :A => 71.0788,
    :R => 156.1875,
    :N => 114.1038,
    :D => 115.0886,
    :C => 103.1388,
    :E => 129.1155,
    :Q => 128.1307,
    :G => 57.0519,
    :H => 137.1411,
    :I => 113.1594,
    :L => 113.1594,
    :K => 128.1741,
    :M => 131.1926,
    :F => 147.1766,
    :P => 97.1167,
    :S => 87.0782,
    :T => 101.1051,
    :W => 186.2132,
    :Y => 163.1760,
    :V => 99.1326,

    # uncommon
    :B => 172.1405, # average of aspartic acid and asparagine
    :U => 150.03,   # (selenocysteine) http://www.matrix-science.com/help/aa_help.html
    :X => 118.88603, # the average of the masses of the 20 amino acids
    :* => 118.88603, # same as X
    :Z => (129.1155+ 128.1307) / 2,  # average glutamic acid and glutamine

    # elements etc.
    :h => 1.00794,
    :h_plus => 1.00739,
    :o => 15.9994,
    :h2o => 18.01524,
  }

  # returns a fresh hash where it has been added to each amino acid the amount
  # specified in the array of a PepXML::Modifications object
  # if static_terminal_mods given than will create the following keys as
  # symbols as necessary:
  # add_C_term_protein
  # add_C_term_peptide
  # add_N_term_protein
  # add_N_term_peptide
  def self.add_static_masses(monoisotopic, static_mods, static_terminal_mods=nil)
    hash_to_use = 
      if monoisotopic
        Mass::MONO
      else
        Mass::AVG
      end
    copy_hash = hash_to_use.dup
    static_mods.each do |mod|
      copy_hash[mod.aminoacid.to_sym] += mod.massdiff
    end
    static_terminal_mods.each do |mod|
      if x = mod.protein_terminus
        # its a protein terminus modification
        case x
        when 'n'
          copy_hash[:add_N_term_protein] = mod.massdiff
        when 'c'
          copy_hash[:add_C_term_protein] = mod.massdiff
        end
      else
        # its a peptide terminus modification
        case mod.terminus
        when 'n'
          copy_hash[:add_N_term_peptide] = mod.massdiff
        when 'c'
          copy_hash[:add_C_term_peptide] = mod.massdiff
        end
      end
    end
    copy_hash
  end

  # returns an array of masses parallel to array passed in
  # If you want the mass with H+, then pass in the mass as h_plus
  # The mass hash must repond to 
  #   :h2o (water)
  #   and at least the twenty amino acids (by string or symbol)
  # The mass hash may respond to :add_N_term_peptide or :add_C_term_peptide
  # in which case these will be added to the final mass
  def self.masses(aaseqs, mass_hash=Mass::MONO, h_plus=0.0)
    final_add = mass_hash[:h2o] + h_plus
    [:add_N_term_peptide, :add_C_term_peptide].each do |sym|
      if mass_hash.key?(sym)
        final_add += mass_hash[sym]
      end
    end
    hash_by_aa_string = {}
    mass_hash.each {|k,v| hash_by_aa_string[k.to_s] = mass_hash[k] }

    aaseqs.map do  |pep_aaseqs|
      sum = 0.0
      aaseq.split('').each do |let|
        sum += hash_by_aa_string[let]
      end
      mh_plus = sum + final_add
    end
  end


end

class Mass::Calculator

  # mass_hash must respond to :h2o or 'h2o'.  This is added to represent the
  # tails of the peptide.  add_extra is outside of that (e.g., an H+)
  def initialize(mass_hash, add_extra=0.0)
    @mass_hash = mass_hash_to_s(mass_hash)
    @final_add = @mass_hash['h2o'] + add_extra
  end

  def mass_hash_to_s(mass_hash)
    new_hash = {}
    mass_hash.each do |k,v|
      new_hash[k.to_s] = v
    end
    new_hash
  end

  def masses(aaseqs)
    aaseqs.map do |aaseq|
      sum = @final_add  # <- add in the initialization
      aaseq.split('').each do |let|
        if @mass_hash.key? let
          sum += @mass_hash[let]
        else
          abort "LETTER not found in mass_hash: #{let}"
        end
      end
      sum
    end
  end

end

