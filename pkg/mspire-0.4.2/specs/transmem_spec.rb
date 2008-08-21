require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require File.expand_path( File.dirname(__FILE__) + '/transmem_spec_shared' )
require 'transmem'

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

describe TransmemIndex, "determining filetypes" do
  before(:each) do
    @files = %w(toppred.small.out toppred.xml.out phobius.small.small.txt phobius.small.noheader.txt).map {|f| Tfiles + '/' + f }
    @types = %w(toppred toppred phobius phobius).map {|v| v.to_sym }
    @classes = %w(TopPred TopPred Phobius Phobius).map {|v| v.to_sym }
  end
  it 'figures out the filetype' do
    @files.zip(@types) do |file,tp|
      TransmemIndex.filetype(file).should == tp
    end
  end
  it 'given a file to initalize, returns the right object' do
    objects = @files.zip(@classes) do |file,base_klass|
      obj = TransmemIndex.new(file)
      base = Kernel.const_get(base_klass)
      klass = base.const_get(:Index)
      obj.class.should == klass
    end
  end
end



describe TransmemIndex, "methods" do
  it 'calculates the num of overlapping chars in start/stop seqs' do
    ##########0         1         2         3         4         5         6
    ##########01234567890123456789012345678901234567890123456789012345678901
    ##########   ****         ****                       **   ***
    string = 'ABCDEFG ABCDEFG ABCDEFG CATTITY ABCD EFG CD BCDEFGTTITY BCDEFG'
    ########## ^^^^^^  ^^^^^^  ^^^^^^                     ^^^^^^      ^^^^^^
    #         
    substring = 'BCDEFG'
    ranges = [(3..6), (16..19), (43..44), (48..50)]
    expected = [4, 0, 3, 3, 0]
    class TMshell ; include TransmemIndex ; end
    TMshell.new.num_overlapping_chars(string, ranges, substring).should == expected
  end
end


