require 'spec_helper'

require 'mspire/paramable'
require 'mspire/cv/param'
require 'mspire/user_param'
require 'mspire/mzml/referenceable_param_group'

class ParamableObject
  include Mspire::Paramable
end

describe 'Mspire::Paramable' do

  subject do
    paramable = ParamableObject.new.describe_many!(['MS:1000007', ['MS:1000511', 2]])
    paramable.user_params << Mspire::UserParam.new('hello', 477)
    paramable.ref_param_groups << Mspire::Mzml::ReferenceableParamGroup.new('id1').describe!('MS:1000512', 'filter string')
    paramable
  end

  it 'can be initialized with different types of params' do
    subject.cv_params.size.should == 2
    subject.ref_param_groups.size.should == 1
    subject.user_params.size.should == 1
  end

  it '#params grabs all params' do
    params = subject.params
    params.size.should == 4
    params.map(&:class).uniq.size.should == 2
  end

  it '#params? asks if there are any' do
    subject.params?.should be_true
  end

  it '#accessionable_params returns those with accession numbers' do
    subject.accessionable_params.size.should == 3
  end

  it '#param finds the value or true if param name exists' do
    # doesn't take accessions!
    subject.fetch('MS:1000511').should be_false
    subject.fetch('ms level').should == 2
    subject.fetch('inlet type').should be_true
  end

  it '#params? tells if has any' do
    subject.params?.should be_true
    mine = subject.dup
    [:cv_params, :user_params, :ref_param_groups].each do |key|
      mine.send("#{key}=", []) 
    end
    mine.params?.should be_false
  end
end

