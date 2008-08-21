
module SpecIDXML; end

require 'strscan'

require 'spec_id_xml'
require 'spec_id'


class SampleEnzyme
  include SpecIDXML

  attr_accessor :name
  # amino acids after which to cleave
  attr_accessor :cut
  # cleave at 'cut' amino acids UNLESS it is followed by 'no_cut'
  attr_accessor :no_cut
  # 'C' or 'N'
  attr_accessor :sense

  # Currently, recognize: 
  #   trypsin
  # For other enzymes, you must set :cut, :no_cut, :name, and :sense
  # will yield the object if you want to set the values that way
  def initialize(name=nil)
    @num_missed_cleavages_regex = nil
    @sense = nil
    @cut = nil
    @no_cut = nil
    @name = name
    if @name
      # set the values if we recognize this name
      send("set_#{@name}".to_sym)
    end
    if block_given?
      yield(self)
    end
  end

  def set_trypsin
    @sense = 'C'
    @cut = 'KR'
    @no_cut = 'P'
  end

  def to_pepxml
    element_xml(:sample_enzyme, [:name]) do
      short_element_xml(:specificity, [:cut, :no_cut, :sense])
    end
  end

  # returns self
  def from_pepxml_node(node)
    self.name = node['name']
    ch = node.child
    self.cut = ch['cut']
    self.no_cut= ch['no_cut']
    self.sense = ch['sense']
    self
  end

  def self.from_pepxml_node(node)
    self.new.from_pepxml_node(node)
  end

  # takes an amino acid sequence (e.g., -.PEPTIDK.L)
  # returns the number of missed cleavages
  def num_missed_cleavages(aaseq)
    raise NotImplementedError, 'need to implement for N terminal sense'  if sense == 'N'
    @num_missed_cleavages_regex = 
      if @num_missed_cleavages_regex ; @num_missed_cleavages_regex
      else
        regex_string = "[#{@cut}]"
        if @no_cut and @no_cut != ''
          regex_string << "[^#{@no_cut}]"
        end
        /#{regex_string}/
      end
    arr = aaseq.scan(@num_missed_cleavages_regex)
    num = arr.size
    if aaseq[-1,1] =~ @num_missed_cleavages_regex
      num -= 1
    end
    num
  end

  # requires full sequence (with heads and tails)
  def num_tol_term(sequence)
    raise NotImplementedError, 'need to implement for N terminal sense'  if sense == 'N'
    no_cut = @no_cut || ''
    num_tol = 0
    first, middle, last = SpecID::Pep.split_sequence(sequence)
    last_of_middle = middle[-1,1]
    first_of_middle = middle[0,1]
    if ( @cut.include?(first) && !no_cut.include?(first_of_middle) ) || first == '-'
      num_tol += 1
    end
    if @cut.include?(last_of_middle) && !no_cut.include?(last) || last == '-'
      num_tol += 1
    end
    num_tol
  end

  # returns all peptides of missed cleavages <= 'missed_cleavages'
  # so 2 missed cleavages will return all no missed cleavage peptides
  # all 1 missed cleavages and all 2 missed cleavages.
  # options:
  def digest(string, missed_cleavages=0, options={})
    raise NotImplementedError if @sense == 'N'
    s = StringScanner.new(string)
    no_cut_regex = Regexp.new("[#{@no_cut}]")
    regex = Regexp.new("[#{@cut}]")
    peps = []
    last_pos = 0
    current_pep = ''
    loop do
      if s.eos?
        break
      end
      m = s.scan_until(regex)
      if m  ## found a cut point
        last_pos = s.pos
        # is the next amino acid a no_cut?
        if string[s.pos,1] =~ no_cut_regex 
          current_pep << m
        else
          # cut it 
          current_pep << m
          peps << current_pep
          current_pep = ''
        end
      else  ## didn't find a cut point
        current_pep << string[last_pos..-1]
        peps << current_pep 
        break
      end
    end
    ## LOOP through and grab each set of missed cleavages from num down to 0
    all_sets_of_peps = []
    (0..missed_cleavages).to_a.reverse.each do |num_mc|
      all_sets_of_peps.push( *(get_missed_cleavages(peps, num_mc)) )
    end
    all_sets_of_peps 
  end

  # takes an array of peptides and returns an array containing 'num' missed
  # cleavages
  # DOES NOT contain peptides that contain < num of missed cleavages
  # (i.e., will not return missed cleaveages of 1 or 2 if num == 3
  def get_missed_cleavages(ar_of_peptide_seqs, num)
    (0...(ar_of_peptide_seqs.size - num)).to_a.map do |i|
      ar_of_peptide_seqs[i,num+1].join
    end
  end

  def self.tryptic(string, missed_cleavages=0)
    self.new("trypsin").digest(string, missed_cleavages)
  end

end
