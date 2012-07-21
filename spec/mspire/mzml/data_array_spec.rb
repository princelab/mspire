require 'spec_helper'

require 'nokogiri'
require 'mspire/mzml/parser'

require 'mspire/mzml/data_array'

describe Mspire::Mzml::DataArray do

  let(:xml_node) do
    string = %Q{<binaryDataArray encodedLength="1588">
      <cvParam cvRef="MS" accession="MS:1000523" name="64-bit float" value=""/>
      <cvParam cvRef="MS" accession="MS:1000574" name="zlib compression" value=""/>
      <cvParam cvRef="MS" accession="MS:1000514" name="m/z array" value="" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>
      <binary>eJwt0X1MVXUcBvADykoZOi8wFYf9BBFypKi3WWByEi+VMgsFVhhyQtTkomTImyicuLfEq2WG4FvSaQoS2lYCMd7sUIGKtiZXfEnDg8jVFjnjxWkpaz6Pf332PN/v+Z6zeyVJEh0jKbIkSXK+vhpmO1Jh1Iw1TzQeVkO11QWl7si1cHsfNHIC1z1RtERDKX4tdVRD/d3I95EDkqEadhfqpsD1eD54XRq0VVLf01CyuZjHvWHF/r00KCruQG2kOh19XcIG3L2mQ/nBuo3ojWKoplcxL79Ne5Mz0P/QRiNGf4D3hcyB8r1lUNnqtgnvme8Npa12qLtKoNHZDkWzi33IMPfKPD7E3Xu+UIpJgKKjiDqO0IzRmXif1RsqicHQqJpLwy1QDc+GelAN952X2d8f5t4Vt82415AK9aZMqOzuokV/QmPhQyi1z8uCVfFZ/H4FapPyoZpUwZzYBfWp7tn8nXygUhgF5cjlzCPJUIrNhPr+Ss4P1ELNo43z25ehcLvJPPSA+5dMOdgfmA6ltMVQeK6C+p4szhfbOZ/dzv6kExov9nK/6DHnw/656P8wQ/W9OOYhO9SKK6DU3QrlOz305wdQnDfl4f6UWCjXpkDDkQ2VwJ30Qmkef8cjUPOr5/6FVs71PihKH/Hetpgt2Nv4DpR61kNxMwuq+xzQyKuC+ux67rd0Qrm3m/nXQT6/Y0w+bPCGan0wlKeZoXjlNc6fi2e2WqHinkMTHewt+6G28ig0QurYR7bx7oxuqP/9mHt7p27ld4ZRPQqKxhV0osLeP4f5JQdN2QflpEqoJTRD5e5vnBtXoX7jFt0+wHnJqG3YnxYBxeDrzLvSoD6cxTy+CMo5B6Cx6hh11bMfex8qBeMKcGdBBjQ8vqLuDVBp8ymEodOhPstCi9dAzWWjllIotxx9qhOKw8Pcf95bRX9wMjROT6VnotkrsVAvX80+0cpcl898yE6PHoSK+WtmUyWU5BNQ2/wX5wGDzBbvj/C/LfKDxpshUNTMpZ0LOZ+zBMpVb0N9cjLn31vZX93E57/Mg4qws6/4jHlPJffTjz/ta6m1kaY5oXTuCu84bvO5Fr8iPNf+ApQCFkFtYAnt2gCNgM2ciwqoVp7g/HAN+29+4Z3oDqg/ckLF6zr3dvfzzndjbfgeX18b/xd/KHlOt/F3ioBavIW++hZUYnNpYyH7VQ7moDK6oJx9TQPvhHTwPZ5OKBL6+Z7qIe6fGIGG6Vk7vmOMD1TGT4PymdlQk+ez94/jXslK9iYrVL3y2ScXQSPoCPOMRii2nKNev9PcPvr5AH151Me4U+wFjVA/qJUr1NMORdkxzsMaodRzFioFnZyvuMX+5DDUs82fYH7JAo24pVDrWkH/TYJir417X/xE559n730RykHX+Xx5L/PMfqhO8NuO9yWEQuOGGcqzopgvLoeaM5E5ycr5pONQUZvoqTbueXRC0X+Nd38cgvqpgGLk1FA60QyVwHDmJBvU/imGormX8zFTdkBTDJXioLY0EYr/UqHxjIseug/VuTEO7B22QmHOpk12eraJzmzfyXweShPm7UIeWQY1n2+hkhL3qfw/0zSmlA==</binary>
    </binaryDataArray>}
    Nokogiri::XML.parse(string, nil, 'utf-8', Mspire::Mzml::Parser::NOBLANKS).root
  end

  it 'can be created from base64 binary xml' do
    d_ar = Mspire::Mzml::DataArray.from_xml(xml_node, {})
    d_ar.is_a?(Array)
    # these are just frozen
    d_ar.size.should == 315
    d_ar.first.round(3).should == 151.962
    d_ar.last.round(3).should == 938.548
  end

  it "can be initialized like any ol' array" do
    data = [1,2,3]
    d_ar = Mspire::Mzml::DataArray.new( data )
    d_ar.should == data
  end

  describe 'an instantiated Mspire::Mzml::DataArray' do
    subject { Mspire::Mzml::DataArray.new [1,2,3] }

    it "can have a 'type'" do
      subject.type = :mz
      subject.type.should == :mz
    end

    it 'can be converted to a binary string' do
      string = subject.to_binary
      # frozen
      string.should == "eJxjYACBD/YMEOAAoTgcABe3Abg="
    end

  end

end
