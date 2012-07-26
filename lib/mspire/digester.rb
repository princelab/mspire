require 'strscan'

module Mspire

  # A Digester splits a protein sequence into peptides at specified sites.
  #
  #     trypsin = Mspire::Digester[:trypsin]
  #
  #     trypsin.digest('MIVIGRSIVHPYITNEYEPFAAEKQQILSIMAG')
  #     # => ['MIVIGR', 'SIVHPYITNEYEPFAAEK', 'QQILSIMAG']
  #
  # With 1 missed cleavage:
  #
  #     trypsin.digest('MIVIGRSIVHPYITNEYEPFAAEKQQILSIMAG', 1)
  #     # => ['MIVIGR','MIVIGRSIVHPYITNEYEPFAAEK','SIVHPYITNEYEPFAAEK', 
  #     #     'SIVHPYITNEYEPFAAEKQQILSIMAG', 'QQILSIMAG']
  #
  # Return the start and end sites of digestion:
  #
  #   trypsin.site_digest('MIVIGRSIVHPYITNEYEPFAAEKQQILSIMAG', 1)
  #   # => [[0,6],[0,24],[6,24],[6,33],[24,33]]
  class Digester

    # The name of the digester
    attr_reader :name

    # A string of residues at which cleavage occurs
    attr_reader :cleave_str

    # A c-terminal resitriction residue which prevents 
    # cleavage at a potential cleavage site (optional).
    attr_reader :cterm_exception

    # True if cleavage occurs at the c-terminus of a 
    # cleavage residue, false if cleavage occurs at
    # the n-terminus.
    attr_reader :cterm_cleavage

    MULTILINE_WHITESPACE = /\s*/m

    def initialize(name, cleave_str, cterm_exception=nil, cterm_cleavage=true)
      regexp = []
      0.upto(cleave_str.length - 1) {|i| regexp << cleave_str[i, 1] }

      @name = name
      @cleave_str = cleave_str
      @cleave_regexp = Regexp.new(regexp.join('|'))
      @cterm_exception = case 
                         when cterm_exception == nil || cterm_exception.empty? then nil
                         when cterm_exception.length == 1 then cterm_exception[0]
                         else
                           raise ArgumentError, "cterm exceptions must be a single residue: #{cterm_exception}"
                         end

      @cterm_cleavage = cterm_cleavage
      @scanner = StringScanner.new('')
    end

    # Returns digestion sites in sequence, as determined by the
    # cleave_regexp boundaries.  The digestion sites correspond to the
    # positions where a peptide begins and ends, such that [n, (n+1) - n]
    # corresponds to the [index, length] for peptide n.
    #
    #   d = Digester.new('Trypsin', 'KR', 'P')
    #   seq = "AARGGR"
    #   sites = d.cleavage_sites(seq)                 # => [0, 3, 6]
    #
    #   seq[sites[0], sites[0+1] - sites[0]]          # => "AAR"
    #   seq[sites[1], sites[1+1] - sites[1]]          # => "GGR"
    #
    # Trailing whitespace is included in the fragment.
    #
    #   seq = "AAR  \n  GGR"
    #   sites = d.cleavage_sites(seq)                 # => [0, 8, 11]
    #
    #   seq[sites[0], sites[0+1] - sites[0]]          # => "AAR  \n  "
    #   seq[sites[1], sites[1+1] - sites[1]]          # => "GGR"
    #
    # The digested section of sequence may be specified using offset 
    # and length.
    def cleavage_sites(seq, offset=0, length=seq.length-offset)
      return [0, 1] if seq.size == 1  # adding exceptions is lame--algorithm should just work

      adjustment = cterm_cleavage ? 0 : 1
      limit = offset + length

      positions = [offset]
      pos = scan(seq, offset, limit) do |pos|
        positions << (pos - adjustment)
      end

      # add the final position
      if (pos < limit) || (positions.length == 1)
        positions << limit
      end
      # adding exceptions is lame.. this code probably needs to be
      # refactored (corrected).
      if !cterm_cleavage && pos == limit
        positions << limit
      end
      positions
    end

    # Returns digestion sites of sequence as [start_index, end_index] pairs,
    # allowing for missed cleavages.  Digestion sites are determined using
    # cleavage_sites; as in that method, the digested section of sequence
    # may be specified using offset and length.
    # 
    # Each [start_index, end_index] pair is yielded to the block, if given,
    # and the collected results are returned.
    def site_digest(seq, max_misses=0, offset=0, length=seq.length-offset, &block) # :yields: start_index, end_index
      frag_sites = cleavage_sites(seq, offset, length)

      overlay(frag_sites.length, max_misses, 1) do |start_index, end_index|
        start_index = frag_sites[start_index]
        end_index = frag_sites[end_index]

        block ? block.call(start_index, end_index) : [start_index, end_index]
      end  
    end

    # Returns an array of peptides produced by digesting sequence, allowing for
    # missed cleavage sites. Digestion sites are determined using cleavage_sites; 
    # as in that method, the digested section of sequence may be specified using 
    # offset and length.
    def digest(seq, max_misses=0, offset=0, length=seq.length-offset)
      site_digest(seq, max_misses, offset, length).map do |s, e|
        seq[s, e-s]
      end
    end

    protected

    # The cleavage regexp used to identify cleavage sites
    attr_reader :cleave_regexp # :nodoc:

    # The scanner used to digest strings.
    attr_reader :scanner # :nodoc:

    # Scans seq between offset and limit for the cleave_regexp, skipping whitespace
    # and being mindful of exception characters. The positions of the scanner at
    # each match are yielded to the block.      
    def scan(seq, offset, limit, &block) # :nodoc:
      scanner.string = seq
      scanner.pos = offset

      while scanner.search_full(cleave_regexp, true, false)
        scanner.search_full(MULTILINE_WHITESPACE, true, false)
        pos = scanner.pos

        # skip if the next character is the exception character
        next if cterm_exception != nil && seq[pos] == cterm_exception

        # break if you scanned past the upper limit
        break if pos > limit

        block.call(pos)
      end

      scanner.pos
    end

    # Performs an overlap-collect algorithm providing the start and end 
    # indicies of spans skipping up to max_misses boundaries.
    def overlay(n, max_misses, offset, &block) # :nodoc:
      results = []
      0.upto(n-1) do |start_index|
        0.upto(max_misses) do |n_miss|
          end_index = start_index + offset + n_miss
          break if end_index == n

          results << block.call(start_index, end_index)
        end
      end
      results
    end

    #
    # Enzymes adapted from the default Mascot enzyme list.
    #

    class << self
      # takes the name of the enzyme in any case (symbol or string)
      # and accesses the constant (returns nil if none found)
      def [](enzyme_name)
        ENZYMES[ enzyme_name.to_s.downcase.gsub(/\W+/,'_').to_sym ]
      end

      # Utility method to parse a mascot enzyme configuration
      # string (tab separated) into a Digester.
      def mascot_parse(str) # :nodoc:
        name, sense, cleave_str, cterm_exception, independent, semi_specific = str.split(/ *\t */)
        cterm_cleavage = case sense
                         when 'C-Term' then true
                         when 'N-Term' then false
                         else raise ArgumentError, "unknown sense: #{sense}"
                         end

        new(name, cleave_str, cterm_exception, cterm_cleavage)
      end
    end

    # ARG_C = mascot_parse('Arg-C 	C-Term 	R 	P 	 no 	 no')
    # ENZYMES[:arg_c] = <'Arg-C' enzyme>
    MASCOT_ENZYME_CONFIG_STRINGS = {
      :arg_c => 'Arg-C 	C-Term 	R 	P 	 no 	 no',
      :asp_n => 'Asp-N 	N-Term 	BD 	  	no 	no',
      :asp_n_ambic => 'Asp-N_ambic 	N-Term 	DE 	  	no 	no',
      :chymotrypsin => 'Chymotrypsin 	C-Term 	FLWY 	P 	no 	no',
      :cnbr => 'CNBr 	C-Term 	M 	  	no 	no',
      :lys_c => 'Lys-C 	C-Term 	K 	P 	no 	no',
      :lys_c_p => 'Lys-C/P 	C-Term 	K 	  	no 	no',
      :pepsin_a => 'PepsinA 	C-Term 	FL 	  	no 	no',
      :tryp_cnbr => 'Tryp-CNBr 	C-Term 	KMR 	P 	no 	no',
      :tryp_chymo => 'TrypChymo 	C-Term 	FKLRWY 	P 	no 	no',
      :trypsin_p => 'Trypsin/P 	C-Term 	KR 	  	no 	no',
      :v8_de => 'V8-DE 	C-Term 	BDEZ 	P 	no 	no',
      :v8_e => 'V8-E 	C-Term 	EZ 	P 	no 	no',
      :trypsin => 'Trypsin 	C-Term	KR 	P 	no 	no',
      :v8_e_trypsin => 'V8-E+Trypsin 	C-Term 	EKRZ 	P 	no 	no',
      :v8_de_trypsin => 'V8-DE+Trypsin 	C-Term 	BDEKRZ 	P 	no 	no',
    }

    ENZYMES = MASCOT_ENZYME_CONFIG_STRINGS.inject(Hash.new) do |hash,(k,v)| 
      hash[k] = mascot_parse(v)
      hash
    end
  end
end
