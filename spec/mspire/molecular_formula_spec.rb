require 'spec_helper'

require 'mspire/molecular_formula'

MF = Mspire::MolecularFormula
describe Mspire::MolecularFormula do

  describe 'initialization' do

    it 'is initialized with Hash' do
      data = {H: 22, C: 12, N: 1, O: 3, S: 2}
      mf = Mspire::MolecularFormula.new(data)
      mf.to_hash.should == {:H=>22, :C=>12, :N=>1, :O=>3, :S=>2}
      mf.to_hash.should == data
    end

    it 'can be initialized with charge, too' do
      mf = Mspire::MolecularFormula["H22BeC12N1O3S2Li2", 2]
      mf.to_hash.should == {:H=>22, :Be=>1, :C=>12, :N=>1, :O=>3, :S=>2, :Li=>2}
      mf.charge.should == 2
    end

    it 'from_string or ::[] to make from a capitalized string formula' do
      Mspire::MolecularFormula.from_string("H22BeC12N1O3S2Li2").to_hash.should == {:H=>22, :Be=>1, :C=>12, :N=>1, :O=>3, :S=>2, :Li=>2}

      mf = Mspire::MolecularFormula['Ni7Se3', 1]
      mf.charge.should == 1
      mf.to_hash.should == {:Ni=>7, :Se=>3}

      # there is no such thing as the E element, so this is going to get the
      # user in trouble.  However, this is the proper interpretation of the
      # formula.
      Mspire::MolecularFormula['Ni7SE3'].to_hash.should == {:Ni=>7, :S=>1, :E=>3}
    end

    describe 'correct to_s' do
      subject {
        Mspire::MolecularFormula.new({:C=>669, :H=>1129, :O=>185, :N=>215, :S=>4, :P=>0, :Se=>0})
      }
      it 'to_s gives output' do
        subject.to_s.should == "C669H1129N215O185S4"
      end
    end

    describe 'conversion' do

      subject {
        data = {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
        Mspire::MolecularFormula.new(data)
      }

      it 'the string output is a standard molecular formula' do
        subject.to_s.should == "BeC12H22NO3S2"
      end

      it 'can be converted to a hash' do
        subject.to_hash.should == {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
      end
    end

    describe 'equality' do
      subject {
        data = {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
        Mspire::MolecularFormula.new(data)
      }
      it 'is only equal if the charge is equal' do
        another = subject.dup
        another.should == subject
        another.charge = 2
        another.should_not == subject
      end
    end

    describe 'arithmetic' do
      subject {
        data = {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
        Mspire::MolecularFormula.new(data, 2)
      }
      it 'can do non-destructive arithmetic' do
        orig = subject.dup
        reply = subject + MF["H2C3P2", 2]
        reply.to_hash.should == {H: 24, C: 15, N: 1, O: 3, S: 2, Be: 1, P: 2}
        reply.charge.should == 4
        subject.should == orig

        reply = subject - MF["H2C3P2", 2]
        reply.to_hash.should == {H: 20, C: 9, N: 1, O: 3, S: 2, Be: 1, P: -2}
        reply.charge.should == 0
        subject.should == orig

        by2 = subject * 2
        by2.to_hash.should == {H: 44, C: 24, N: 2, O: 6, S: 4, Be: 2}
        by2.charge.should == 4
        subject.should == orig

        reply = by2 / 2
        reply.to_hash.should == {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
        reply.charge.should == 2
        subject.should == orig
      end

      it 'can do destructive arithmetic' do
        orig = subject.dup
        subject.sub!(MF["H2C3"]).to_hash.should == {H: 20, C: 9, N: 1, O: 3, S: 2, Be: 1}
        subject.should_not == orig
        subject.add!(MF["H2C3"]).to_hash.should == {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
        subject.should == orig

        by2 = subject.mul!(2)
        subject.should_not == orig
        by2.to_hash.should == {H: 44, C: 24, N: 2, O: 6, S: 4, Be: 2}
        by2.div!(2).to_hash.should == {H: 22, C: 12, N: 1, O: 3, S: 2, Be: 1}
        by2.to_hash.should == orig
      end

    end

    describe 'mass and mz' do
      # (for all these, checked to make sure in close ballpark, but not
      # necessarily exact, unless otherwise stated)
      
      before do
        @exact = 65.02654910101
        @avg = 65.07332
        @e = 0.0005486  # set with -> Mspire::Mass::ELECTRON
        @exact_plus_2e = @exact + (2*@e)
      end

      subject {
        data = {H: 3, C: 4, N: 1}
        Mspire::MolecularFormula.new(data, -2)
      }

      specify '#mass (of an uncharged molecule) -> the exact mass' do
        subject.charge = 0
        subject.mass.should == @exact # BMRB databank says: 65.0265491015
      end

      specify '#mass -> the exact mass (adjusts for electrons)' do
        subject.mass.should == @exact_plus_2e
      end

      specify '#mass (no charge adjustment)' do
        subject.mass(false).should == @exact # BMRB databank says: 65.0265491015
      end

      specify '#avg_mass' do
        subject.avg_mass.should == (@avg + 2*@e)

        # changes the value
        subject.charge = 0
        subject.avg_mass.should == @avg # BMRB databank says: 65.073320
      end

      specify '#mz -> the m/z ratio' do
        subject.mz.should == (@exact_plus_2e / -2.0)
        subject.charge = +2
        subject.mz.should == ((@exact - 2*@e) / 2.0)
      end

      specify '#mz(true, false) will only yield positive m/z ratio' do
        subject.mz(true, false).should == (@exact_plus_2e / 2.0)
      end

      specify '#mz(false, true) will not consider electrons in mass determination' do
        subject.mz(false, true).should == (@exact / -2.0)
      end
    end

  end
end
