require 'spec_helper'

require 'ms/ident/pepxml/search_hit/modification_info'

describe 'MS::Ident::Pepxml::SearchHit::ModificationInfo' do

  before do
    modaaobjs = [[3, 150.3], [6, 345.2]].map do |ar| 
      MS::Ident::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new(*ar)
    end
    hash = {
      :mod_nterm_mass => 520.2,
      :modified_peptide => "MOD*IFI^E&D",
      :mod_aminoacid_masses => modaaobjs,
    }
    #answ = "<modification_info mod_nterm_mass=\"520.2\" modified_peptide=\"MOD*IFI^E&amp;D\">\n\t<mod_aminoacid_mass position=\"3\" mass=\"150.3\"/>\n\t<mod_aminoacid_mass position=\"6\" mass=\"345.2\"/>\n</modification_info>\n"
    @obj = MS::Ident::Pepxml::SearchHit::ModificationInfo.new(hash)
  end

  it 'can produce valid pepxml xml' do
    to_match = ['<modification_info',
    ' mod_nterm_mass="520.2"',
    " modified_peptide=\"MOD*IFI^E&amp;D\"",
    "<mod_aminoacid_mass",
    " position=\"3\"",
    " mass=\"150.3\"",
    " position=\"6\"",
    " mass=\"345.2\"",
    "</modification_info>"]
    string = @obj.to_xml
    to_match.each do |re|
      string.should match(Regexp.new(Regexp.escape(re)))
    end
  end
end


