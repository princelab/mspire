require 'ms/quant/protein_group_comparison'

module Ms
  module Quant
    module ProteinGroupComparison
    end
  end
end

class Ms::Quant::ProteinGroupComparison::Qspec
  include Ms::Quant::ProteinGroupComparison

  attr_accessor :qspec_results_struct

  # takes a protein group object, an array of experiment names and a qspec
  # results struct
  def initialize(protein_group, experiments, qspec_results_struct)
    super(protein_group, experiments, qspec_results_struct.counts_array)
    @qspec_results_struct = qspec_results_struct
  end
end

