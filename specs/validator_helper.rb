require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

class ValidatorHelper
  def self.precision_from_partition_array(ar)
    (num_tp, num_fp) = ar.map {|v| v.size}
    num_tp.to_f / (num_tp + num_fp)
  end
end

module ValidatorHelper::Decoy
  def self.precision_from_partition_array(ar)
    (num_maybe_true, num_decoy) = ar.map {|v| v.size}
    num_tp = num_maybe_true - num_decoy
    num_fp = num_maybe_true - num_tp
    num_tp.to_f / (num_tp + num_fp)
  end
end

describe 'a validator', :shared => true do
  before(:each) do
    @empty_peps = []
  end
  it 'gives 1.0 for zero peptides (w/ pephit_precision)' do 
    @validator.pephit_precision(@empty_peps).should == 1.0
    
  end
  it 'gives 1.0 for zero peptides (w/ increment_pephits_precision)' do
    @validator.increment_pephits_precision(@empty_peps).should == 1.0
  end

end


