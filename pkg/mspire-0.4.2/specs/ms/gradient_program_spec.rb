require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'ms/gradient_program'

describe GradientProgram do
  it 'can be set from a Thermo Xcal 2.X .meth file' do
    data = [
      [0.00, 95.0, 5.0, 0.0, 0.0, 38.0],
      [1.00, 90.0, 10.0, 0.0, 0.0, 38.0],
      [30.00, 85.0, 15.0, 0.0, 0.0, 38.0],
      [40.00, 80.0, 20.0, 0.0, 0.0, 38.0],
      [45.00, 78.0, 22.0, 0.0, 0.0, 38.0],
      [50.00, 72.0, 28.0, 0.0, 0.0, 38.0],
      [65.00, 60.0, 40.0, 0.0, 0.0, 38.0],
      [72.00, 10.0, 90.0, 0.0, 0.0, 38.0],
      [75.0, 10.0, 90.0, 0.0, 0.0, 38.0],
      [81.00, 10.0, 90.0, 0.0, 0.0, 38.0],
      [81.10, 95.0, 5.0, 0.0, 0.0, 38.0],
      [90.00, 95.0, 5.0, 0.0, 0.0, 38.0],
    ]

    ms_pump_expected_tps = data.map do |ar| 
      GradientProgram::TimePoint.new(ar[0], ar[-1], ar[1,4])
    end
    ms_pump_expected = GradientProgram.new('MS Pump', ms_pump_expected_tps, %w(A B C D))

    data = [
      [0.00, 0.0, 0.0, 100.0, 0.0, 40.0],
      [90.0, 0.0, 0.0, 100.0, 0.0, 40.0],
    ]
    sample_pump_expected_tps = data.map {|ar| GradientProgram::TimePoint.new(ar[0], ar[-1], ar[1,4]) }
    sample_pump_expected = GradientProgram.new('Sample Pump', sample_pump_expected_tps, %w(A B C D))

    file = Tfiles + '/s01_anC1_ld020mM.meth'
    File.open(file) do |fh|
      gps = GradientProgram.all_from_handle(fh)
      gps[0].should == ms_pump_expected
      gps[1].should == sample_pump_expected
    end
  end

  it 'can be set from a Thermo Xcal 1.X .RAW file (but missing pump_type)' do
    file = Tfiles + '/opd1_020_beginning.RAW'
    data = [[0.0, 0.0, 0.0, 100.0, 0.0, 200.0],
      [1.0, 0.0, 0.0, 96.0, 4.0, 200.0],
      [10.0, 0.0, 0.0, 96.0, 4.0, 200.0],
      [11.0, 0.0, 0.0, 100.0, 0.0, 200.0],
      [85.0, 0.0, 0.0, 100.0, 0.0, 200.0],]

    time_points = data.map do |ar| 
      GradientProgram::TimePoint.new(ar[0], ar[-1], ar[1,4])
    end
    pump_type = ''  ## need to get pump type...
    ms_pump_expected = GradientProgram.new(pump_type, time_points, %w(A B C D))

    data = [[0.0, 95.0, 5.0, 0.0, 0.0, 200.0],
      [1.0, 95.0, 5.0, 0.0, 0.0, 200.0],
      [61.0, 55.0, 45.0, 0.0, 0.0, 200.0],
      [62.0, 5.0, 95.0, 0.0, 0.0, 200.0],
      [67.0, 5.0, 95.0, 0.0, 0.0, 200.0],
      [68.0, 95.0, 5.0, 0.0, 0.0, 200.0],
      [85.0, 95.0, 5.0, 0.0, 0.0, 200.0],]
    time_points = data.map do |ar| 
      GradientProgram::TimePoint.new(ar[0], ar[-1], ar[1,4])
    end
    pump_type = ''  ## need to get pump type...
    sample_pump_expected = GradientProgram.new(pump_type, time_points, %w(A B C D))

    # we'd like to get an older .meth file to do this on
    File.open(file) do |fh|
      gps = GradientProgram.all_from_handle(fh)
      gps[0].should == ms_pump_expected
      gps[1].should == sample_pump_expected

    end
  end

end
