#!/usr/bin/ruby -w

require 'data_sets'
require 'validator/background'
require 'table'
require 'optparse'

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

opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} [options] min_index max_index <file>.yaml ..."
  op.separator "outputs a tab delimited table"
  op.separator "OPTIONS: "
  op.on("-y", "--yaml", "outputs yaml format by filename info") {|v| opt[:yaml] = v }
end

opts.parse!

if ARGV.size < 3 or ARGV[0] =~ /[^0-9]/ or ARGV[1] =~ /[^0-9]/
  puts opts.to_s
  exit
end

min_index = ARGV.shift
max_index = ARGV.shift
files = ARGV.to_a
min_index = min_index.to_i
max_index = max_index.to_i
points = 3

row_labels = nil

cols = files.map do |file|
  dsets = DataSets.load_backgrounds_from_filter_file(file)
  row_labels = []

  dsets.reject! {|v| v.tp == 'decoy' }
  #dsets.single_badAA!('badAA (dig & exp)')

  dsets.map do |dset|
    row_labels << dset.label
    Validator::Background.new(dset.ydata).min_mesa(min_index, max_index, points)
  end
end




require 'matrix'

as_rows = Matrix[*cols].transpose
col_headers = files.map {|v| v.sub(/\.\w+$/,'')}
table = Table.new(as_rows, row_labels, col_headers)
if opt[:yaml]
  # dcn, label, hash_by, hs, inv_shuff
  ar = [DSLabel.hash_key_labels + ['label']]
  hash = {}
  cols.zip(col_headers) do |col, file_label|
    label = DSLabel.new(file_label)
    hash_key_all = label.hash_key
    col.zip(row_labels) do |val, rl|
      hash_key =  hash_key_all + [rl]
      hash[hash_key] = val
    end
  end
  ar.push(hash)
  puts ar.to_yaml
else
  puts table.to_s
end




