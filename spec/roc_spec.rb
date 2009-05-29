require File.expand_path( File.dirname(__FILE__) + '/spec_helper' )
require 'roc'

describe 'an area under the curve calculator', :shared => true do

  it 'calculates area under curve correctly' do
    x_y_pairs = {
      [[1,2,3],[2,3,4]]    => 6,
      [[1,2,3],[-2,-3,-4]] => -6,
      [[1,2,3],[4,3,2]]    => 6,
      [[1,2,3],[-4,-3,-2]] => -6,
      [[4,5,6],[2,1,2]]    => 3,
      [[4,5,6],[-2,-1,-2]] => -3,
    }
    x_y_pairs.each do |k,v|
      calculate(*k).should == v
    end
  end

  def calculate(x,y)
    @method.call(x,y)
  end
end

describe ROC do
  before(:all) do
    @method = proc {|x,y| ROC.new.area_under_curve(x,y) }
  end
  it_should_behave_like 'an area under the curve calculator'

  it 'gives doublets_to_separate' do
    t = true
    f = false
    x,y = ROC.new.doublets_to_separate([[0,f],[1,f],[2,f],[3,t],[3,f],[0,f],[4,f],[1,t],[2,t]])
    x.should == [1,2,3]
    y.should == [0,0,1,2,3,4]
  end

  it 'gives tps_and_ppv' do
    tp = %w(1 2 3 4 5 6 6 6 7 8 9 10 10 10 10 11 12 ).collect {|c| c.to_f } # 17 total
    fp = %w(3.5 4 5 5 5 6 6 6.5 7 8 9 9.5 10 15).collect {|c| c.to_f } # 14 total
    xe = [1, 2, 3, 4, 5, 8, 9, 10, 11, 15, 16, 17]
    #       1, 2, 3, 4        5,   6,             7,             8,   9
    #       10              11                12
    ye = [1, 1, 1, 4.0/6.0, 0.5, 8.0/(7.0+8.0), 9.0/(9.0+9.0), 0.5, 11.0/(11.0+ 11.0),  15.0/(15.0+13.0), 16.0/(16.0+13.0), 17.0/(17.0+13.0)]
    _test_tps_and_ppv_method(tp,fp,xe,ye,"complex real-life-like scenario")

    ## leading fp's
    tp = [1,2,3]
    fp = [0,0,1,2,3,4]
    xe = [1,2,3]
    ye = [1.0/(1+3), 2.0/(2+4), 3.0/(3+5)]
    _test_tps_and_ppv_method(tp,fp,xe,ye, "leading fps")

    ## leading tp's
    tp = [-1,2,3]
    fp = [0,4]
    xe = [1,2,3]
    ye = [1.0/(1+0), 2.0/(2+1), 3.0/(3+1)]
    _test_tps_and_ppv_method(tp,fp,xe,ye, "leading tps")

    ## equal tp's leading
    tp = [0.0001,0.0001,0.0001,2]
    fp = [0.01,4.0]
    xe = [3,4]
    ye = [3.0/(3+0), 4.0/(4+1)]
    _test_tps_and_ppv_method(tp,fp,xe,ye, "equal tps leading")

    ## equal arrays with some repeated values
    tp = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    fp = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    xe = [1,2,4,5,6,7]
    ye = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    _test_tps_and_ppv_method(tp,fp,xe,ye, "equal arrays with some repeated values")

  end

  it 'gives numhits_and_ppv' do
    ## leading fp's
    tp = [1,2,3]
    fp = [0,0,1,2,3,4]
    xe = [2,4,6,8,9]
    ye = [0.0/2, 1.0/4, 2.0/6, 3.0/8, 3.0/9]
    _test_numhits_and_ppv_method(tp,fp,xe,ye, "leading fps")

    ## leading tp's
    tp = [-1,2,3]
    fp = [0,4]
    xe = [1, 2, 3, 4, 5]
    ye = [1.0/1, 1.0/2, 2.0/3, 3.0/4, 3.0/5]
    _test_numhits_and_ppv_method(tp,fp,xe,ye, "leading tps")

    ## equal tp's leading
    tp = [0.0001,0.0001,0.0001,2]
    fp = [0.01,4.0]
    xe = [3, 4, 5, 6]
    ye = [3.0/3, 3.0/4, 4.0/5, 4.0/6]
    _test_numhits_and_ppv_method(tp,fp,xe,ye, "equal tps leading")

    ## equal arrays with some repeated values
    tp = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    fp = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    xe = [2, 4, 8, 10, 12, 14]
    ye = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    _test_numhits_and_ppv_method(tp,fp,xe,ye, "equal arrays with some repeated values")

    ## @TODO: NEED TO FILL THIS OUT!
=begin 
    tp = %w(1 2 3 4 5 6 6 6 7 8 9 10 10 10 10 11 12 ).collect {|c| c.to_f } # 17 total
    fp = %w(3.5 4 5 5 5 6 6 6.5 7 8 9 9.5 10 15).collect {|c| c.to_f } # 14 total
    xe = [1, 2, 3, 4, ]
    #       1, 2, 3, 4        5,   6,             7,             8,   9
    #       10              11                12
    ye = [1, 1, 1, 4.0/6.0, 0.5, 8.0/(7.0+8.0), 9.0/(9.0+9.0), 0.5, 11.0/(11.0+ 11.0),  15.0/(15.0+13.0), 16.0/(16.0+13.0), 17.0/(17.0+13.0)]
    _test_tps_and_ppv_method(tp,fp,xe,ye,"complex real-life-like scenario")
=end

  end

  def _test_numhits_and_ppv_method(tp,fp,xe,ye,message='')
    roc = ROC.new
    list = roc.separate_to_doublets(tp,fp)
    (x,y) = roc.numhits_and_ppv(list)
    y.size.should == x.size
    x.should == xe
    y.should == ye
  end

  def _test_tps_and_ppv_method(tp,fp,xe,ye,message='')
    (x,y) = ROC.new.tps_and_ppv(tp,fp)
    y.size.should == x.size
    x.should == xe
    y.should == ye
  end

end

describe DecoyROC do

  ###################################################################

  it 'gives pred_and_ppv' do
    hits = [1,2,3]
    decoys = [0,0,1,2,3,4]
    num_hits_e = [1,2,3]
    num_fps = [3,4,5]
    # expected = [-2.0/1, -2.0/2, -2.0/3] 
    _test_pred_and_ppv(hits, decoys, num_hits_e, num_fps)
  end

  it 'gives pred_tps_ppv__leading_tps' do
    ## leading tp's
    hits = [-1,2,3]
    decoys = [0,4]
    num_hits_e = [1,2,3]
    num_fps = [0,1,1]
    _test_pred_and_ppv(hits, decoys, num_hits_e, num_fps)
  end

  it 'gives pred_tps_ppv__equal_tps_leading' do
    hits = [0.0001,0.0001,0.0001,2]
    decoys = [0.01,4.0]
    num_hits_e = [3,4]
    num_fps = [0,1]
    _test_pred_and_ppv(hits, decoys, num_hits_e, num_fps)
  end

  it 'gives pred_tps_ppv__equal_arrays_with_some_repeated_values' do
    hits = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    decoys = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    num_hits_e = [1,2,4,5,6,7]
    num_fps = [1,2,4,5,6,7]
    _test_pred_and_ppv(hits, decoys, num_hits_e, num_fps)
  end

  ###################################################################

  it 'gives pred_tps_ppv__leading_fps' do
    ## leading fp's
    hits = [1,2,3]
    decoys = [0,0,1,2,3,4]
    num_hits_e = [1,2,3]
    num_fps = [3,4,5]
    tps_e = make_tps_e(num_fps, num_hits_e)
    ppv_e = make_ppv_e(tps_e, num_hits_e)
    _test_pred_and_tps_and_ppv(hits, decoys, num_hits_e, tps_e, ppv_e)
  end

  it 'gives pred_tps_ppv__leading_tps' do
    ## leading tp's
    hits = [-1,2,3]
    decoys = [0,4]
    num_hits_e = [1,2,3]
    num_fps = [0,1,1]
    tps_e = make_tps_e(num_fps, num_hits_e)
    ppv_e = make_ppv_e(tps_e, num_hits_e)
    _test_pred_and_tps_and_ppv(hits, decoys, num_hits_e, tps_e, ppv_e)
  end

  it 'gives pred_tps_ppv__equal_tps_leading' do
    hits = [0.0001,0.0001,0.0001,2]
    decoys = [0.01,4.0]
    num_hits_e = [3,4]
    num_fps = [0,1]
    tps_e = make_tps_e(num_fps, num_hits_e)
    ppv_e = make_ppv_e(tps_e, num_hits_e)
    _test_pred_and_tps_and_ppv(hits, decoys, num_hits_e, tps_e, ppv_e)
  end

  it 'gives pred_tps_ppv__equal_arrays_with_some_repeated_values' do
    hits = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    decoys = %w(1 2 3 3 4 5 6 ).collect {|x| x.to_f } # 17 total
    num_hits_e = [1,2,4,5,6,7]
    num_fps = [1,2,4,5,6,7]
    tps_e = make_tps_e(num_fps, num_hits_e)
    ppv_e = make_ppv_e(tps_e, num_hits_e)
    _test_pred_and_tps_and_ppv(hits, decoys, num_hits_e, tps_e, ppv_e)
  end

  def  _test_pred_and_ppv(hits, decoys, num_hits_e, num_fps)
    answer = DecoyROC.new.pred_and_ppv(hits, decoys)
    precision = num_hits_e.zip(num_fps).map do |h,f|
      (h - f).to_f / h
    end
    answer.should == [num_hits_e, precision]
  end

  def _test_pred_and_tps_and_ppv(hits, decoys, num_hits_e, tps_e, ppv_e)
    answer = DecoyROC.new.pred_and_tps_and_ppv(hits, decoys)
    expected = [num_hits_e, tps_e, ppv_e]
    %w(num_hits num_tps ppv).each_with_index do |cat, i|
      answer[i].should == expected[i]
    end
  end

  def make_tps_e(num_fps, num_hits_e)
    tps_e = []
    num_hits_e.each_with_index do |v,i|
      tps_e[i] = v - num_fps[i]
    end
    tps_e
  end

  def make_ppv_e(tps_e, num_hits_e)
    ppv_e = []
    tps_e.each_with_index {|v,i| ppv_e[i] = v.to_f/num_hits_e[i] }
    ppv_e
  end

end

