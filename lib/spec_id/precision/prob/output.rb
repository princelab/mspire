require 'yaml'
require 'spec_id/precision/output'
require 'table'
require 'matrix'

module SpecID ; end
module SpecID::Precision ; end
class SpecID::Precision::Prob ; end
class SpecID::Precision::Prob::Output 
  include SpecID::Precision::Output

  # returns array of data arrays and parallel labels
  def to_cols_and_labels(answer_hash)
    col_labels = %w(count probability peptide)
    col_labels[1] = 'q_values' if answer_hash.key?(:q_values)

    cols = []
    cols << answer_hash[:count]
    if answer_hash.key?(:q_values)
      cols << answer_hash[:q_values]
    else
      cols << answer_hash[:probabilities]
    end
    cols << answer_hash[:aaseqs]


    # if there is a single modified peptide, we'll include the column
    if answer_hash.key?(:modified_peptides)
      cols << answer_hash[:modified_peptides]
      col_labels.push( 'modified_peptide' )
    end

    col_labels.push( 'charge' )
    cols << answer_hash[:charges]

    answer_hash[:pephits_precision].each do |ans|
      col_labels.push( "#{ans[:validator]} (prob)" )
      cols << ans[:values]
    end

    [cols, col_labels]
  end

  def csv(handle, answer_hash)
    (cols, col_labels) = to_cols_and_labels(answer_hash)
    table = Table.new(Matrix[*cols].transpose, nil, col_labels)
    handle.puts(table.to_s("\t"))
  end

  def to_plot(handle, answer_hash)
    tp = 'XYData'
    basename_noext = 
      if handle.respond_to?(:path)
        out = File.basename(handle.path).sub(/\.(\w)+$/,'')
      else
        'plot'
      end
    title = 'precision vs. num (aaseq+charge)'
    xlabel = 'num hits'
    ylabel = 'precision'
    [tp, basename_noext, title, xlabel, ylabel].each {|v| handle.puts v }
    answer_hash[:pephits_precision].each do |hash|
      handle.puts hash[:validator]    # label
      handle.puts answer_hash[:count] # x vals
      handle.puts hash[:values]       # y vals
    end
  end

  def calc_bkg_to_plot(handle, answer_hash)
    tp = 'XYData'
    basename_noext = 
    if handle.respond_to?(:path)
      out = File.basename(handle.path).sub(/\.(\w)+$/,'')
    else
        'calc_bkg_plot'
    end
    title = 'background vs. num (aaseq+charge)'
    xlabel = 'num hits'
    ylabel = 'background (false/total)'
    [tp, basename_noext, title, xlabel, ylabel].each {|v| handle.puts v }
    answer_hash[:params][:validators].each do |hash|
      handle.puts hash[:name]    # label
      handle.puts answer_hash[:count] # x vals
      handle.puts hash[:calculated_backgrounds]       # y vals
    end
  end

  def yaml(handle, answer_hash)
    handle.puts answer_hash.to_yaml
  end

end


