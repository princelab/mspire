
module Mspire
  module Quant
  end
end

module Mspire::Quant::ProteinGroupComparison

  # a protein group object
  attr_accessor :protein_group

  # an array of experiment names
  attr_accessor :experiments

  # parallel array to experiments with the measured values
  attr_accessor :values

  def initialize(protein_group, experiments, values)
    (@protein_group, @experiment, @values) = protein_group, experiments, values
  end
end

class Mspire::Quant::ProteinGroupComparison::SpectralCounts
  include Mspire::Quant::ProteinGroupComparison
end

class Mspire::Quant::ProteinGroupComparison::UniqAAzCounts
  include Mspire::Quant::ProteinGroupComparison
end
