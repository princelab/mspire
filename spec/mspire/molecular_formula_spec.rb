require 'spec_helper'

require 'mspire/molecular_formula'

MF = Mspire::MolecularFormula
describe Mspire::MolecularFormula do

  describe 'initialization' do

    it 'is initialized with Hash' do
      data = {h: 22, c: 12, n: 1, o: 3, s: 2}
      mf = Mspire::MolecularFormula.new(data)
      mf.to_hash.should == {:h=>22, :c=>12, :n=>1, :o=>3, :s=>2}
      mf.to_hash.should == data
    end

    it 'can be initialized with charge, too' do
      mf = Mspire::MolecularFormula["H22BeC12N1O3S2Li2", 2]
      mf.to_hash.should == {:h=>22, :be=>1, :c=>12, :n=>1, :o=>3, :s=>2, :li=>2}
      mf.charge.should == 2
    end

    it 'from_string or ::[] to make from a capitalized string formula' do
      Mspire::MolecularFormula.from_string("H22BeC12N1O3S2Li2").to_hash.should == {:h=>22, :be=>1, :c=>12, :n=>1, :o=>3, :s=>2, :li=>2}

      mf = Mspire::MolecularFormula['Ni7Se3', 1]
      mf.charge.should == 1
      mf.to_hash.should == {:ni=>7, :se=>3}

      # there is no such thing as the E element, so this is going to get the
      # user in trouble.  However, this is the proper interpretation of the
      # formula.
      Mspire::MolecularFormula['Ni7SE3'].to_hash.should == {:ni=>7, :s=>1, :e=>3}
    end

    describe 'conversion' do

      subject {
        data = {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
        Mspire::MolecularFormula.new(data)
      }

      it 'the string output is a standard molecular formula' do
        subject.to_s.should == "BeC12H22NO3S2"
      end

      it 'can be converted to a hash' do
        subject.to_hash.should == {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
      end
    end

    describe 'equality' do
      subject {
        data = {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
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
        data = {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
        Mspire::MolecularFormula.new(data, 2)
      }
      it 'can do non-destructive arithmetic' do
        orig = subject.dup
        reply = subject + MF["H2C3P2", 2]
        reply.to_hash.should == {h: 24, c: 15, n: 1, o: 3, s: 2, be: 1, p: 2}
        reply.charge.should == 4
        subject.should == orig

        reply = subject - MF["H2C3P2", 2]
        reply.to_hash.should == {h: 20, c: 9, n: 1, o: 3, s: 2, be: 1, p: -2}
        reply.charge.should == 0
        subject.should == orig

        by2 = subject * 2
        by2.to_hash.should == {h: 44, c: 24, n: 2, o: 6, s: 4, be: 2}
        by2.charge.should == 4
        subject.should == orig

        reply = by2 / 2
        reply.to_hash.should == {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
        reply.charge.should == 2
        subject.should == orig
      end

      it 'can do destructive arithmetic' do
        orig = subject.dup
        subject.sub!(MF["H2C3"]).to_hash.should == {h: 20, c: 9, n: 1, o: 3, s: 2, be: 1}
        subject.should_not == orig
        subject.add!(MF["H2C3"]).to_hash.should == {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
        subject.should == orig

        by2 = subject.mul!(2)
        subject.should_not == orig
        by2.to_hash.should == {h: 44, c: 24, n: 2, o: 6, s: 4, be: 2}
        by2.div!(2).to_hash.should == {h: 22, c: 12, n: 1, o: 3, s: 2, be: 1}
        by2.to_hash.should == orig
      end

    end

  end
end
