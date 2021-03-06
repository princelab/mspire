require 'mspire/quant/protein_group_comparison'

module Mspire
  module Quant
    module ProteinGroupComparison
    end
  end
end

class Mspire::Quant::ProteinGroupComparison::Qspec
  include Mspire::Quant::ProteinGroupComparison

  attr_accessor :qspec_results_struct

  # takes a protein group object, an array of experiment names and a qspec
  # results struct
  def initialize(protein_group, experiments, qspec_results_struct)
    super(protein_group, experiments, qspec_results_struct.counts_array)
    @qspec_results_struct = qspec_results_struct
  end
end

