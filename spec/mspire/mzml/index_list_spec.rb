require 'spec_helper'

require 'mspire/mzml'
require 'mspire/mzml/index_list'

describe 'non-indexed uncompressed peaks, mzML file' do
  subject { TESTFILES + "/mspire/mzml/openms.noidx_nocomp.12.mzML" }

  describe 'Mspire::Mzml getting the IndexList' do
    before do
      @io = File.open(subject)
    end
    after do
      @io.close
    end

    it 'works for an un-indexed file' do
      mzml = Mspire::Mzml.new(@io)
      index_list = mzml.index_list
      spectrum_idx = index_list[:spectrum]
      spectrum_idx.name.should == :spectrum
      spectrum_idx.should == [5755, 6616, 9244, 10077, 12706, 13539, 16168, 17001, 19630, 20463, 23092, 23926]
      spectrum_idx.ids.should == [
        "scan=10929", "scan=10930", "scan=10931", 
        "scan=10932", "scan=10933", "scan=10934", 
        "scan=10935", "scan=10936", "scan=10937", 
        "scan=10938", "scan=10939", "scan=10940"
      ]
      # right now, the behavior is to expect a chromatogram index, even if
      # there are no chromatograms... is that the right behavior???
      chromatogram_idx = index_list[:chromatogram]
      chromatogram_idx.name.should == :chromatogram
      chromatogram_idx.should == []
      chromatogram_idx.ids.should == []
    end
  end
end


describe 'indexed, compressed peaks, mzML file' do
  subject { TESTFILES + "/mspire/mzml/j24z.idx_comp.3.mzML"  }


  describe 'Mspire::Mzml getting the IndexList' do
    before do
      @io = File.open(subject)
    end
    after do
      @io.close
    end

    correct_index_list = lambda do |index_list|
      spectrum_idx = index_list[:spectrum]
      spectrum_idx.name.should == :spectrum
      spectrum_idx.should == [4398, 219667, 227895]
      spectrum_idx.ids.should == [
        "controllerType=0 controllerNumber=1 scan=1", 
        "controllerType=0 controllerNumber=1 scan=2", 
        "controllerType=0 controllerNumber=1 scan=3"
      ]
      chromatogram_idx = index_list[:chromatogram]
      chromatogram_idx.name.should == :chromatogram
      chromatogram_idx.should == [239184]
      chromatogram_idx.ids.should == ["TIC"]
    end

    it 'works for an indexed file' do
      mzml = Mspire::Mzml.new(@io)
      index_list = mzml.index_list
      correct_index_list.call(index_list)
    end

    it 'can create the index manually, if requested' do
      mzml = Mspire::Mzml.new(@io)
      index_list =  mzml.create_index_list
      correct_index_list.call(index_list)
    end

    describe 'an Mspire::Mzxml::IndexList' do
      before do
        @inner_io = File.open(subject)
        mzml = Mspire::Mzml.new(@inner_io)
        @index_list = mzml.index_list
      end
      after do
        @inner_io.close
      end
      it 'can access indices like an array' do
        @index_list[0].should_not be_nil
        @index_list[1].should_not be_nil
        @index_list.map(&:name).should == [:spectrum, :chromatogram]
      end
      it 'can access indices like a hash' do
        @index_list[:spectrum].should_not be_nil
        @index_list[:chromatogram].should_not be_nil
      end
    end

    describe 'an Mspire::Mzxml::Index' do
      before do
        @inner_io = File.open(subject)
        mzml = Mspire::Mzml.new(@inner_io)
        @spec_index = mzml.index_list[:spectrum]
      end
      after do
        @inner_io.close
      end
      it 'can create a scan to index hash' do
        @spec_index.create_scan_to_index.should == {1=>0, 2=>1, 3=>2}
      end
      it 'returns nil if there are no scans defined in the id (scan=XX)' do
        @spec_index.ids.map! { "no scan here" }
        @spec_index.create_scan_to_index.should be_nil
      end
      it 'returns false if there are non-unique scan numbers' do
        @spec_index.ids.map! { "scan=1" }
        @spec_index.create_scan_to_index.should == false
      end
    end
  end
end

