require 'spec_helper'

require 'ms/mzml/data_array'

describe MS::Mzml::DataArray do
  it 'can be created from base64 binary data' do
    d_ar = MS::Mzml::DataArray.from_binary('eJxjYACBD/YMEOAAoTgcABe3Abg=', :float64, zlib=true)
    p d_ar
  end
end
