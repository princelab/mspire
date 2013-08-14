require 'spec_helper'

require 'mspire/isotope'

describe 'Mspire::Isotope constants' do
  it 'has all the common isotopes: Mspire::Isotope::ISOTOPES' do
    # frozen
    Mspire::Isotope::ISOTOPES.size.should == 288
    hydrogen_isotopes = Mspire::Isotope::ISOTOPES.select {|iso| iso.element == :H }
    hydrogen_isotopes.size.should == 2

    { atomic_number: 1, element: :H, mass_number: 1, atomic_mass: 1.00782503207, relative_abundance: 0.999885, average_mass: 1.00794, mono: true }.each do |k,v|
      hydrogen_isotopes.first.send(k).should == v
    end
    {atomic_number: 1, element: :H, mass_number: 2, atomic_mass: 2.0141017778, relative_abundance: 0.000115, average_mass: 1.00794, mono: false}.each do |k,v|
      hydrogen_isotopes.last.send(k).should == v
    end
    u = Mspire::Isotope::ISOTOPES.last
    {atomic_number: 92, element: :U, mass_number: 238, atomic_mass: 238.0507882, relative_abundance: 0.992742, average_mass: 238.02891, mono: true}.each do |k,v|
      u.send(k).should == v
    end
  end
  it 'has all common isotopes by element: Mspire::Isotope::BY_ELEMENT' do
    [{atomic_number: 6, element: :C, mass_number: 12, atomic_mass: 12.0, relative_abundance: 0.9893, average_mass: 12.0107, mono: true}, {atomic_number: 6, element: :C, mass_number: 13, atomic_mass: 13.0033548378, relative_abundance: 0.0107, average_mass: 12.0107, mono: false}].zip(Mspire::Isotope::BY_ELEMENT[:C]) do |hash, iso|
      hash.each do |k,v|
        iso.send(k).should == v
      end
    end
    Mspire::Isotope::BY_ELEMENT[:H].size.should == 2
  end
end
