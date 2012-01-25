require 'spec_helper'

require 'msplat'

class String
  def const
    self.split('::').inject(Kernel) {|scope, const_name| scope.const_get(const_name)}
  end
end

describe "msplat" do
  it "requires major classes/modules" do
    %w(
      MS::Mass
      MS::Mass::AA
    ).each do |str|
      expect { str.const }.to be_true
    end
    # for sanity's sake
    %w(MS::DoesntExit).each do |str|
      expect { str.const }.to raise_error(NameError)
    end
  end
end
