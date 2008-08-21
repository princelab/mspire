#!/usr/bin/ruby -w

require 'generator'
require 'optparse'

require 'fasta'
require 'sample_enzyme'
require 'spec_id/digestor'
require 'spec_id/mass'
require 'vec'

opt = {}
opt[:missed_cleavages] = 0 # ~ parts per million
opt[:bin_size] = 0.001  # ~ parts per million
opt[:min] = 300.0
opt[:max] = 4500.0
opt[:h_plus] = 1.0

opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} *.fasta"
  op.separator "Outputs a close estimate of number of peptides per bin."
  op.separator "Uses m+H+ as the peptide mass."
  op.separator "[for speed, assumes that there is a peptide mass close to the extremes]"
  op.on("-b", "--bin_size <F>", Float, "size of bins [#{opt[:bin_size]}]") {|v| opt[:bin_size] = v }
  op.on("-x", "--max <F>", Float, "max mass to accept [#{opt[:max]}]") {|v| opt[:max] = v }
  op.on("-n", "--min <F>", Float, "min mass to accept [#{opt[:min]}]") {|v| opt[:min] = v }
  op.on("-h", "--h_plus <F>", Float, "value of H+ to use [#{opt[:h_plus]}]") {|v| opt[:h_plus] = v }
  op.on("-m", "--missed_cleavages <N>", Integer, "num missed cleavages [#{opt[:missed_cleavages]}]") {|v| opt[:missed_cleavages] = v }
end

opts.parse!

if ARGV.size == 0
  puts opts.to_s
  exit
end

min_mass = opt[:min]
max_mass = opt[:max]

ARGV.each do |file|
  fasta = Fasta.new(file)
  uniq_aaseqs = fasta.map do |prot|
    SampleEnzyme.tryptic(prot.aaseq, opt[:missed_cleavages])
  end.flatten.uniq

  masses = Mass::Calculator.new(Mass::MONO, opt[:h_plus]).masses(uniq_aaseqs)
  passing_masses = Mass::Calculator.new(Mass::MONO, opt[:h_plus]).masses(uniq_aaseqs).select do |mh|
    ((mh >= min_mass) and (mh <= max_mass))
  end

  ## warn if the masses aren't close to the end points
  if (max_mass - passing_masses.max) > 1.0
    warn "highest mass is not that close to max: #{passing_masses.max}"
  end
  if (passing_masses.min - min_mass) > 1.0
    warn "lowest mass is not that close to min: #{passing_masses.min}"
  end

  num_bins = (max_mass - min_mass) / opt[:bin_size]

  (bins, freqs) = VecD.new(passing_masses).histogram(num_bins)

  # report
  puts "#{file}: #{freqs.avg}"

end
