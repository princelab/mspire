#!/usr/bin/ruby -w

require 'validator/background'
require 'table'
require 'data_sets'

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


if ARGV.size < 3 or ARGV[0] =~ /[^\d]/ or ARGV[1] =~ /[^\d]/ 
  puts "usage: #{File.basename(__FILE__)} min_index max_index <file>.yaml ..."
  puts "outputs a tab delimited table"
  exit
end

min_index = ARGV.shift
max_index = ARGV.shift
files = ARGV.to_a
min_index = min_index.to_i
max_index = max_index.to_i
points = 401

row_labels = nil

cols = files.map do |file|

  dsets = DataSets.background_datasets_from_prob_file(file)

  dsets.reject! {|v| (v.tp == 'prob') or (v.tp == 'decoy') or (v.tp == 'qval') }
  #dsets.single_badAA!('badAA (dig & exp)')

  row_labels = []

  dsets.map do |dset|
    row_labels << dset.label
    Validator::Background.new(dset.ydata).min_mesa(min_index, max_index, points)
  end
end

require 'matrix'

as_rows = Matrix[*cols].transpose
col_headers = files.map {|v| v.sub(/\.\w+$/,'')}
table = Table.new(as_rows, row_labels, col_headers)
puts table.to_s




