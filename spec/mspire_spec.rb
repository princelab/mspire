require 'spec_helper'

require 'mspire'

describe Mspire do
  it 'has a VERSION constant derived from upper level VERSION file' do
    Mspire::VERSION.should match(/^\d+\.\d+\.\d+(\.\d+)?$/)
  end
end
