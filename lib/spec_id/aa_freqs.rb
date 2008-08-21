require 'fasta'

module SpecID ; end

class SpecID::AAFreqs
  # hash by capital one-letter amino acid symbols giving the frequency of
  # seeing that amino acid.  Frequencies should add to 1.
  attr_accessor :aafreqs

  # fasta is fasta object!
  def initialize(fasta=nil)
    if fasta
      @aafreqs = calculate_frequencies(fasta.prots)
    end
  end

  # takes an enumerable of objects responding to :aaseq and creates an aafreqs hash 
  def calculate_frequencies(objs)
    hash = {}
    total_aas = 0
    ('A'..'Z').each do |x|
      hash[x] = 0
    end
    hash['*'] = 0
    objs.each do |obj|
      aaseq = obj.aaseq
      total_aas += aaseq.size
      aaseq.split('').each do |x|
        hash[x] += 1
      end
    end
    # normalize by total amount:
    hash.each do |k,v|
      hash[k] = hash[k].to_f / total_aas
    end
    # convert all strings to symbols:
    hash.each do |k,v|
      hash[k.to_sym] = hash.delete(k)
    end
    hash
  end

  # The expected probability for seeing that amino acid in a given length.
  # This calculates a lookup table (array) from 0 to highest_length of the
  # probability of seeing at least one amino acid (given its frequency, where
  # frequency is from 0 to 1)
  def self.probability_of_length_table(frequency, max_length)
    one_minus_freq = 1.0 - frequency.to_f
    lookup = Array.new(max_length + 1)
    (0..max_length).each do |len|
      lookup[len] =  1.0 - (one_minus_freq**len);
    end
    lookup
  end

  # takes an array of peptide strings
  # gives the actual number of peptides with at least one
  # gives the expected number of peptides given the probabilities in the
  # length lookup table.
  # currently ONLY takes at_least = 1
  # depends on @aafreqs
  # returns two numbers in array [actual, expected]
  # expected is a Float!!!
  def actual_and_expected_number(peptide_aaseqs, amino_acid=:C, at_least=1)
    if at_least > 1
      raise NotImplementedError, "can only do at_least=1 right now!"
    end
    one_minus_freq = 1.0 - @aafreqs[amino_acid.to_sym]
    amino_acid_as_st = amino_acid.to_s
    probs = []
    actual = 0
    expected = 0.0
    peptide_aaseqs.each do |pep|
      expected += (1.0 - (one_minus_freq**pep.size))
      if pep.include?(amino_acid_as_st)
        actual += 1
      end
    end
    [actual, expected] 
  end

  # pep_objs respond to sequence?
  # also takes a hash of peptides keyed on :aaseq
  def actual_and_expected_number_containing_cysteines(pep_objs, cyst_freq)
    if pep_objs.is_a? Hash
      seqs = pep_objs.keys
    else
      seqs = pep_objs.map do |v|
        v.aaseq
      end
    end
    @aafreqs ||= {}
    @aafreqs[:C] = cyst_freq
    actual_and_expected_number(seqs, :C, 1)
  end

  ##
=begin

  foreach my $pep (@$peps) {
        unless ($pep->prob() >= $prob_cutoff) {next;}
        my %freq = ();
        my $aa = $pep->AA_sequence();
        my $len = length($aa);

        ## EXPECTED probability for each length
        for (my $i = 0; $i < 20; $i++) {
            ## rolling at least one 6 in n rolls is 1 - (5/6)^n.
            $expected[$cnt][$i] = 1 - (($freqs_inv[$i])**$len);
        }
        ## FILTER any peptides we've already seen
        if ($seen{$aa}) { next; } 
        else { $seen{$aa}++; }

        ## Fill in these values with zeroes:
        for (my $a = 0; $a < 20; $a++) { $pepc[$cnt][$a] = 0; }

        ## get the frequencies for each AA in each peptide:
        for (my $i = 0; $i < $len; $i++) {
            my $let = substr($aa, $i, 1);
            $tot_freq{$let}++;
            $pepc[$cnt][$an{$let}]++;
        }
        $cnt++;
    }

##############################################################
# ANALYSIS 2: Fraction of Peptides containing X Amino Acid
##############################################################

## What is the percentage of peptides containing at least 1 cysteine?
    my $atleast = 1;

    my @has;
## initialize
    for (my $i = 0; $i < 20; $i++) { $has[$i] = 0; }
    my $tot = scalar(@pepc);
    foreach my $pep (@pepc) {
        for (my $index = 0; $index < 20; $index++) {
            if ($pep->[$index] >= $atleast) {
                $has[$index]++;
            }
        }
    }


    my @exp_sum = ();  ## The total number of peptides I'd expect 
## WE simply add up the peptides' probabilities
## can think of it like this avg(peptide_prob) * #peptides = sum(pep_prob)
    foreach my $pep (@expected) {
        for (my $i = 0; $i < 20; $i++) {
            $exp_sum[$i] += $pep->[$i];
        } 
    }

    my @obs = map { $_/$tot } @has;
    my @exp = map { $_/$tot } @exp_sum;
    print STDERR "*********************************************\n";
    print "Fraction of peptides (obs and expected)\nwith at least one of the AA:\n";
    print "[AA] [Observed] [Predicted]\n";
    for (my $i = 0; $i < 20; $i++) {
        print "$AA[$i] $obs[$i] $exp[$i]\n";
    }
    print STDERR "*********************************************\n";



=end

end
