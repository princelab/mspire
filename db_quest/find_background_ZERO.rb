#!/usr/bin/ruby -w

require 'vec'
require 'table'

$val_keys_are_symbols = true

class String
  def to_symm
    if $val_keys_are_symbols
      to_sym
    else
      self
    end
  end
end

def tmm_key(val)
  parts = []
  parts[0] = if val['transmem_file'.to_symm] =~ /phobius/
    'phob'
  else
    'tpred'
  end
  parts[1] = val['min_num_tms'.to_symm]
  parts[2] = val['no_include_tm_peps'.to_symm]
  parts.join('-')
end

def bad_aa_key(val)
  if val['frequency'.to_symm] and val['frequency'.to_symm] > 0.0
    'badAA est'
  else
    'badAA dig'
  end
end

def bias_key(val)
  if val['file'.to_symm] =~ /mrna/
    'bias mrna'
  else
    'bias prot'
  end
end



if ARGV.size == 0
  puts "usage: #{File.basename(__FILE__)} <file>.yaml ..."
  puts "outputs the initial calculated background"
  exit
end

row_labels = nil
files = ARGV.to_a
cols = files.map do |file|
  docs = []
  File.open(file) do |fh|
    YAML.load_documents(fh) do |doc|
      docs << doc  
    end
  end

  hash = Hash.new {|hash,k| hash[k] = [] }
  docs.each do |doc|
    vals = doc['params']['validators']
    one_badAA = true
    vals.each do |val| 
      if val['type'.to_symm] =~ /(badAA|tmm|bias)/
        hash_key = 
        case  $1.dup
        when 'tmm'
          tmm_key(val)
        when 'badAA'
          bad_aa_key(val)
        else # bias
          bias_key(val)
        end
      hash[hash_key] << val['calculated_background'.to_symm]
      end
    end
  end


  row_labels = []
  hash.delete('badAA dig')
  hash['badAA dig & est'] = hash.delete('badAA est')

  hash.sort.map do |k,v|
    row_labels << k
    v[0]
  end
end


col_labels = files.map{|v| v.sub(/\.\w+$/,'')}
data = Matrix[*cols].transpose

table = Table.new(data, row_labels, col_labels)
puts table.to_s

