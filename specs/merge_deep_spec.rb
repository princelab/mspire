require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require 'merge_deep'

describe 'merging one level deep' do
  it 'works' do
    base = {1=>"X", 3=>{6=>7, 8=>9}}
    another = {1=>'y', 3=>{6=>9}}
    ans = base.merge_deep(another, 1)
    ans.should == {1=>'y', 3=>{6=>9, 8=>9}}
  end
end


