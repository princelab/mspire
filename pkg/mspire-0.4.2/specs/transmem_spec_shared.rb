
# turns all string keys into symbol keys
def string_to_symbol(hash)
  if hash.is_a? Hash
    hash.each do |k,v|
      hash[k.to_sym] = hash.delete(k)
      if v.is_a? Hash
        string_to_symbol(v)
      elsif v.is_a? Array
        v.each do |armemb|
          string_to_symbol(armemb)
        end
      end
    end
  end
end



describe "a transmem index", :shared => true do
  before(:all) do
    # expects an transmem object, @obj
  end

  it 'is a hash' do
    @obj.is_a?(Hash).should be_true
  end

  it 'responds to reference_to_key' do
    @obj.respond_to?(:reference_to_key).should be_true
  end

  it "correctly transforms headers or refs into id's" do
    @ref_to_key.each do |k,v|
      @obj.reference_to_key(k).should == v
    end
  end

  it "creates a num_certain_index that gives correct values given keys" do
    ind = @obj.num_certain_index
    @test_hash.each do |k,v|
      ind[@obj.reference_to_key(k)].should == v
    end
  end
end


describe "a calculator of transmembrane overlap", :shared => true do
  # require definition of @tm_test and @obj
  
  it "can give average overlap given a sequence (fraction)" do
    [:number, :fraction].each do |tp|
    #[:fraction, :number].each do |tp|
      hash = @tm_test
      key = hash[:mykey]
      hash[:seqs].zip(hash[:exps][tp]) do |seq,exp|
        @obj.avg_overlap(key, seq, tp).should == exp
      end
    end
  end

end


