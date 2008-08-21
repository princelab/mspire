#!/usr/bin/ruby -w

REGEXP = /^INV_/
#REGEXP = /^SHUFF_/
puts "USING #{REGEXP.inspect} as regular expression for decoys"

def has_decoy?(ar)
  ar.each do |lilar|
    if (lilar.all? {|v| v == true})
      return true
    end
  end
  return false
end

class Pep
  attr_accessor :is_decoy_ar, :probability, :prots
end

ARGV.each do |file|
  probs = []
  bad_matches = 0
  lines = IO.readlines(file)
  peps = []
  current_pep = nil
  lines.each do |line|
    if line =~ /<search_hit hit_rank="1".*protein="(.*?)" num_tot/
      current_pep = Pep.new 
      peps.push( current_pep)
      current_pep.prots = [$1.dup] 
      if $1 =~ REGEXP
        current_pep.is_decoy_ar = [true]
      else
        current_pep.is_decoy_ar = [false]
      end
    elsif line =~ /<alternative_protein protein="(.*?)"/
      current_pep.prots.push($1.dup)
      if $1 =~ REGEXP
        current_pep.is_decoy_ar.push(true)
      else
        current_pep.is_decoy_ar.push(false)
      end
    elsif line =~ /peptideprophet_result probability="([\-\d\.]+)"/
      current_pep.probability = $1.to_f
    end
  end

  before = peps.size
  peps = peps.reject {|v| v.probability == -1.0}
  puts "BAD MATCHES: #{before - peps.size}" if peps.size != before

  base = file.sub(/\.[\w]+$/,'')

  sorted_peps = peps.sort_by{|v| v.probability}.reverse

  ## do precision
  current_sum_one_minus_prob = 0.0

  # this should work!
  #objs.inject(0.0) {|sum,obj| sum + (1.0 - obj.probability) }

  cnt = 0
  precisions = sorted_peps.map do |pep|
    cnt += 1
    # SUM(1-probX)/#objs
    current_sum_one_minus_prob += 1.0 - pep.probability
    1.0 - (current_sum_one_minus_prob / cnt)
  end

  # replace precisions with adjusted precision of just the target hits
  is_decoy = peps.map {|v| v.is_decoy_ar }

  if has_decoy?(is_decoy)
    puts "FOUND decoy!"
  
    ##### CHECKKKKKKKKK>>>>>>>>>>>>>>>>>>>>>>
    #indices = [] ; sorted_peps.each_with_index do |pep,x|
    #  if (pep.is_decoy_ar.all? {|v| v == true})
    #    puts "PROTS: #{pep.prots.join(", ")}"
    #    puts "INDEX: #{x}"
    #  end
    #end
    ##### DONE CHECKKKKKKKKK>>>>>>>>>>>>>>>>>>>>>>


    # adjust the probabilities for only target hits
    new_precs = []
    precisions.zip(sorted_peps) do |prec,pep|
      if !(pep.is_decoy_ar.all? {|v| v == true})
        new_precs << (2.0*prec)/(prec + 1.0)
      end
    end
    precisions = new_precs
  end

  xvals = (1...(precisions.size)).to_a

  sprobs = sorted_peps.map {|v| v.probability }

  File.open(base+ '.to_plot', 'w') do |out|
    out.puts ['XYData', base, base, 'num hits', 'prob or precision', 'prob', xvals.join(' '), sprobs.join(' '), 'precision', xvals.join(' '), precisions.join(' ')].join("\n")
  end

end
