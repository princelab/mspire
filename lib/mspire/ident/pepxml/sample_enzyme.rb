require 'merge'
require 'strscan'

module Mspire ; end
module Mspire::Ident ; end
class Mspire::Ident::Pepxml ; end

class Mspire::Ident::Pepxml::SampleEnzyme
  include Merge
  # an identifier
  attr_accessor :name
  # amino acids after which to cleave
  attr_accessor :cut
  # cleave at 'cut' amino acids UNLESS it is followed by 'no_cut'
  attr_accessor :no_cut
  # 'C' or 'N'
  attr_accessor :sense

  # Can pass in a name of an enzyme that is recognized (meaning there is a
  # set_<name> method), or 
  #   trypsin
  # For other enzymes, you must set :cut, :no_cut, :name, and :sense will
  def initialize(arg={})
    if arg.is_a?(String)
      @name = arg
      send("set_#{@name}".to_sym)
    else
      merge!(arg)
    end
  end

  def set_trypsin
    @sense = 'C'
    @cut = 'KR'
    @no_cut = 'P'
  end

  # if an xml builder object is given, it adds to the object and returns the
  # builder object, otherwise it returns an xml fragment string
  def to_xml(builder=nil)
    xmlb = builder || Nokogiri::XML::Builder.new
    xmlb.sample_enzyme(:name => name) do |xmlb|
      xmlb.specificity(:cut => cut, :no_cut => no_cut, :sense => sense)
    end
    builder || xmlb.doc.root.to_xml
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

  # takes an amino acid sequence (e.g. PEPTIDE).
  # returns the number of missed cleavages
  def num_missed_cleavages(aaseq)
    seq_to_scan = '  ' + aaseq + '  ' 
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

  # No arguments should contain non-standard amino acids
  def num_tol_term(prev_aa, middle, next_aa)
    raise NotImplementedError, 'need to implement for N terminal sense'  if sense == 'N'
    no_cut = @no_cut || ''
    num_tol = 0
    last_of_middle = middle[-1,1]
    first_of_middle = middle[0,1]
    if ( @cut.include?(prev_aa) && !no_cut.include?(first_of_middle) ) || prev_aa == '-'
      num_tol += 1
    end
    if @cut.include?(last_of_middle) && !no_cut.include?(next_aa) || next_aa == '-'
      num_tol += 1
    end
    num_tol
  end
end

###################################################
###################################################
###################################################
###################################################
# This is digestion methodology:

=begin
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
=end
