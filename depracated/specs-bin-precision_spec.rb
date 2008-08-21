require File.dirname(__FILE__) + '/../spec_helper'

describe 'precision.rb' do
  before(:all) do
    @progname = 'precision.rb'
  end

  it_should_behave_like "a cmdline program"
end
