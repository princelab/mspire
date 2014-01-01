require 'spec_helper'

require 'mspire/isotope/distribution'

describe 'Mspire::Isotope::Distribution class methods' do

  def similar_distributions(a_dist, b_dist)
    b_dist.zip(a_dist) do |b,a| 
      expect(a).to be_within(1e-9).of b
    end
  end

  before(:all) do
    @nist = Mspire::Isotope::NIST::BY_ELEMENT
    @norm = Mspire::Isotope::Distribution::NORMALIZE
    @pcut = nil # percent cutoff
  end

  before do 
    @first = [1.0, 0.08919230588715311, 0.017894161377222138, 0.0013573997600723345, 0.0001398330738144181]
  end

  # can also be used on a real MolecularFormula object
  subject { 'C102H120O15' }

  describe 'normalizing isotope distributions' do


    it 'defaults to normalizing by total signal with no cutoff' do
      dist = Mspire::Isotope::Distribution.calculate( subject, normalize: @norm, percent_cutoff: @pcut, isotope_table: @nist )
      expect(dist.size).to eq(253)
      similar_distributions dist[0,5], [0.31740518639058685, 0.35635707398291416, 0.20793431846543858, 0.08373257192958428, 0.026084566135229446]
    end

    it 'can normalize by first peak' do
      dist = Mspire::Isotope::Distribution.calculate( subject, normalize: :first, percent_cutoff: @pcut, isotope_table: @nist )
      dist.size.should == 253
      dist[0].should == 1.0
      dist[1].should_not == 1.0
    end

    it 'can normalize by the max peak' do
      dist = Mspire::Isotope::Distribution.calculate( subject, normalize: :max, percent_cutoff: @pcut, isotope_table: @nist )
      dist.size.should == 253
      dist[0].should_not == 1.0
      dist[1].should == 1.0
    end

    it 'can cutoff based on percent of total signal' do
      Mspire::Isotope::Distribution.calculate(subject, normalize: :max, percent_cutoff: 100, isotope_table: @nist).should == []
      similar_distributions Mspire::Isotope::Distribution.calculate(subject, normalize: :max, percent_cutoff: 20, isotope_table: @nist), [0.8906942209481861, 1.0, 0.5834999040187656]
      similar_distributions Mspire::Isotope::Distribution.calculate(subject, normalize: :max, percent_cutoff: 5, isotope_table: @nist), [0.8906942209481861, 1.0, 0.5834999040187656, 0.23496817670469172]
      Mspire::Isotope::Distribution.calculate(subject, normalize: :max, percent_cutoff: 0.0001, isotope_table: @nist).size.should == 11
    end

    it 'can cutoff based on a given number of peaks' do
      Mspire::Isotope::Distribution.calculate(subject, normalize: :max, peak_cutoff: 0, isotope_table: @nist).should == []
      similar_distributions Mspire::Isotope::Distribution.calculate(subject, normalize: :total, peak_cutoff: 4, isotope_table: @nist), [0.3287710818944283, 0.3691177894299527, 0.2153801947039964, 0.08673093397162249]
      expect(Mspire::Isotope::Distribution.calculate(subject, normalize: :max, peak_cutoff: 1, isotope_table: @nist)).to eql([1.0])
    end

    xspecify 'prefers the lowest of cutoffs'  ## need to test

  end

  describe 'calculating an isotope distribution spectrum' do

    it 'gives neutral masses if no charge' do
      spec = Mspire::Isotope::Distribution.spectrum( subject, normalize: @norm, percent_cutoff: @pcut, isotope_table: @nist )
      [:mzs, :intensities].each {|att| spec.send(att).size.should == 253 }
      spec.mzs[0,5].should == [1584.8627231418, 1585.8713880574, 1586.8800529730001, 1587.8887178886002, 1588.8973828042003]
      similar_distributions spec.intensities[0,5], [0.31740518639058685, 0.35635707398291416, 0.20793431846543858, 0.08373257192958428, 0.026084566135229446]
    end

    it 'gives proper m/z values if the molecule is charged' do
      charged_molecule = Mspire::MolecularFormula.from_any( subject )
      charged_molecule.charge = -3
      spec = Mspire::Isotope::Distribution.spectrum( charged_molecule, normalize: @norm, percent_cutoff: @pcut, isotope_table: @nist )
      [:mzs, :intensities].each {|att| spec.send(att).size.should == 253 }
      spec.mzs[0,5].should == [-528.2881229806, -528.6243446191334, -528.9605662576668, -529.2967878962, -529.6330095347334]
    end
  end
end
