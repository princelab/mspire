require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )

require 'xml'

describe XML, 'converting duration to seconds' do
  it 'converts hours/mins/seconds in combinations' do
    answ = [0.234, 624, 7392.2]
    %w(PT0.234S PT10M24S PT2H3M12.2S).zip(answ) do |string, answ|
      XML.duration_to_seconds(string).should == answ
    end
  end
end
