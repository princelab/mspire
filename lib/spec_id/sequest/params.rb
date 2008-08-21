require 'sample_enzyme'


##
# In the future, this guy should accept any version of bioworks params file
# and spit out any param queried.
module Sequest ; end
class Sequest::Params

  Bioworks31_Enzyme_Info_Array = [
    ['No_Enzyme', 0, '-', '-'],   # 0
    ['Trypsin', 1, 'KR', '-'],  # 1
    ['Trypsin(KRLNH)', 1, 'KRLNH', '-'],  # 2
    ['Chymotrypsin', 1, 'FWYL', '-'],  # 3
    ['Chymotrypsin(FWY)', 1, 'FWY', 'P'],  # 4
    ['Clostripain', 1, 'R', '-'],  # 5
    ['Cyanogen_Bromide', 1, 'M', '-'],  # 6
    ['IodosoBenzoate', 1, 'W', '-'],  # 7
    ['Proline_Endopept', 1, 'P', '-'],  # 8
    ['Staph_Protease', 1, 'E', '-'],  # 9
    ['Trypsin_K', 1, 'K', 'P'],  # 10
    ['Trypsin_R', 1, 'R', 'P'],  # 11
    ['GluC', 1, 'ED', '-'],  # 12
    ['LysC', 1, 'K', '-'],  # 13
    ['AspN', 0, 'D', '-'],  # 14
    ['Elastase', 1, 'ALIV', 'P'],  # 15
    ['Elastase/Tryp/Chymo', 1, 'ALIVKRWFY', 'P'],  # 16
  ]

  # current attributes supported are:
  # bioworks 3.2:
  @@param_re = / = ?/o
  @@param_two_split = ';'
  @@sequest_line = /\[SEQUEST\]/o

  # the general options
  attr_accessor :opts
  # the static weights added to amino acids
  attr_accessor :mods

  # all keys and values stored as strings!
  # will accept a sequest.params file or .srf file
  def initialize(file=nil)
    if file
      parse(file)
    end
  end

  # returns hash of params up until add_U_user_amino_acid
  def grab_params(fh)
    hash = {}
    in_add_amino_acid_section = false
    add_section_re = /^\s*add_/
    prev_pos = nil
    while line = fh.gets
      if line =~ add_section_re
        in_add_amino_acid_section = true
      end
      if (in_add_amino_acid_section and !(line =~ add_section_re))
        fh.pos = prev_pos
        break
      end
      prev_pos = fh.pos
      if line =~ /\w+/
        one,two = line.split @@param_re
        two,comment = two.split @@param_two_split
        hash[one] = two.rstrip
      end
    end
    hash
  end

  # returns self
  def parse_handle(fh)
    # seek to the SEQUEST file
    loop do
      if fh.gets =~ @@sequest_line
        # double check that we are in a sequest params file:
        pos = fh.pos
        if fh.gets =~ /^first_database_name/
          fh.pos = pos
          break
        end
      end
    end
    @opts = grab_params(fh)
    @opts["search_engine"] = "SEQUEST"
    # extract out the mods
    @mods = {}
    @opts.each do |k,v|
      if k =~ /^add_/
        @mods[k] = @opts.delete(k)
      end
    end

    ## this gets rid of the .hdr postfix on indexed databases
    @opts["first_database_name"] = @opts["first_database_name"].sub(/\.hdr$/, '')
    self
  end

  ## parses file
  ## and drops the .hdr behind indexed fasta files
  ## returns self
  ## can read sequest.params file or .srf file handle
  def parse(file)
    File.open(file) do |fh|
      parse_handle(fh)
    end
    self
  end

  # returns( offset, cleave_at, except_if_after )
  # offset is an Integer specifying how far after an amino acid to cut
  # cleave_at is a string of all amino acids that should be cut at
  # except_if_after for not cutting after those
  # normal tryptic behavior would be: [1, 'KR', 'P']
  # NOTE: a '-' in a params file is returned as an '' (empty string)
  # AspN is [0,'D','']
  def enzyme_specificity
    enzyme_ar = 
      if version == '3.1'
        Bioworks31_Enzyme_Info_Array[@opts['enzyme_number'].to_i][1,3]
      elsif version >= '3.2'
        arr = enzyme_info.split(/\s+/)[2,3]
        arr[0] = arr[0].to_i
        arr
      else
        raise ArgumentError, "don't recognize anything but Bioworks 3.1--3.3"
      end
    enzyme_ar.map! do |str|
      if str == '-' ; ''
      else ; str
      end
    end
    enzyme_ar
  end

  # Returns the version of the sequest.params file
  # Returns String "3.3" if contains "fragment_ion_units"
  # Returns String "3.2" if contains "enyzme_info"
  # Returns String "3.1" if contains "enzyme_number"
  def version
    if @opts['fragment_ion_units'] ; return '3.3'
    elsif @opts['enzyme_info'] ; return '3.2'
    elsif @opts['enzyme_number'] ; return '3.1'
    end
  end

  ####################################################
  # TO PEPXML
  ####################################################
  # In some ways, this is merely translating to the older Bioworks
  # sequest.params files

  # I'm not sure if this is the right mapping for sequence_search_constraint?
  def sequence
    pseq = @opts['partial_sequence'] 
    if !pseq || pseq == "" ; pseq = "0" end
    pseq
  end

  def precursor_mass_type
    case @opts['mass_type_parent']
    when '0' ; "average" 
    when '1' ; "monoisotopic"
    else ; abort "error in mass_type_parent in sequest!"
    end
  end

  def fragment_mass_type
    fmtype = 
      case @opts['mass_type_fragment']
      when '0' ; "average"
      when '1' ; "monoisotopic"
      else ; abort "error in mass_type_fragment in sequest!"
      end
  end

  def method_missing(name, *args)
    string = name.to_s
    if @opts.key?(string)    ; return @opts[string]
    elsif @mods.key?(string) ; return @mods[string]
    else                     ; return nil
    end
  end

  ## We only need to define values if they are different than sequest.params
  ## The method_missing will look them up in the hash!

  # Returns a system independent basename
  # Splits on "\" or "/"
  def _sys_ind_basename(file)
    return file.split(/[\\\/]/)[-1]
  end

  # changes the path of the database
  def database_path=(newpath)
    db = @opts["first_database_name"]
    newpath = File.join(newpath, _sys_ind_basename(db))
    @opts["first_database_name"] = newpath
  end

  def database
    @opts["first_database_name"]
  end

  # returns the appropriate aminoacid mass lookup table (in spec_id.rb SpecID::MONO or
  # SpecID::AVG based on precursor_mass_type
  def mass_table
    case precursor_mass_type
    when 'average'
      SpecID::AVG
    when 'monoisotopic'
      SpecID::MONO
    end
  end

  # at least in Bioworks 3.2, the First number after the enzyme
  # is the indication of the enzymatic end stringency (required):
  #   1 = Fully enzymatic
  #   2 = Either end
  #   3 = N terminal only
  #   4 = C terminal only
  # So, to get min_number_termini we map like this:
  #   1 => 2
  #   2 => 1
  def min_number_termini
    termini_number = @opts["enzyme_info"].split(" ")[1]
    if termini_number == "1"
      return "2"
    elsif termini_number == "2"
      return "1"
    else
      puts "WARNING: Enzyme termini info might be imprecise!"
      return "1"
    end
  end

  # returns a SampleEnzyme object
  def sample_enzyme
    (offset, cleave_at, except_if_after) = enzyme_specificity.map do |v|
      if v == '' ; nil ; else v end
    end
    SampleEnzyme.new do |se|
      se.name = self.enzyme
      se.cut = cleave_at
      se.no_cut = except_if_after
      se.sense =
        if se.name == "No_Enzyme"
          nil
        elsif offset == 1
          'C'
        elsif offset == 0
          'N'
        end
    end
  end

  # returns the enzyme name (but no parentheses connected with the name).
  # this will likely be capitalized.
  def enzyme
    v = self.version
    basic_name = 
      if v == '3.1'
        Bioworks31_Enzyme_Info_Array[ @opts['enzyme_number'].to_i ][0]
      elsif v >= '3.2'
        @opts["enzyme_info"]
      end
    basic_name.split('(')[0]
  end

  def max_num_internal_cleavages
    @opts["max_num_internal_cleavage_sites"]
  end

  # my take on peptide_mass_units:
  # (see http://www.ionsource.com/tutorial/isotopes/slide2.htm)
  # amu = atomic mass units = (mass_real - mass_measured).abs (??abs??)
  # mmu = milli mass units (amu / 1000)
  # ppm = parts per million = 10^6 * ∆m_accuracy / mass_measured  [ where ∆m_accuracy = mass_real – mass_measured ]

  def peptide_mass_tol
    if @opts["peptide_mass_units"] != "0"
      puts "WARNING: peptide_mass_tol units need to be adjusted!"
    end
    @opts["peptide_mass_tolerance"]
  end

  def fragment_ion_tol
    @opts["fragment_ion_tolerance"]
  end

  def max_num_differential_AA_per_mod
    @opts["max_num_differential_per_peptide"]
  end

  # returns a hash by add_<whatever> of any static mods != 0
  # the values are still as strings
  def static_mods
    hash = {}
    @mods.each do |k,v|
      if v.to_f != 0.0
        hash[k] = v
      end
    end
    hash
  end

  ## @TODO: We could add some of the parameters not currently being asked for to be more complete
  ## @TODO: We could always add the Bioworks 3.2 specific params as params

  ####################################################
  ####################################################

end

