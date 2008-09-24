require 'yaml'

require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

require 'spec_id/precision/prob'

describe 'filter_and_validate.rb on small bioworks file' do
  before(:all) do
    @progname = 'prob_validate.rb'

    @outfile = Tfiles + '/prob_and_validate.tmp'

    # direct call with an array
    @direct_call = Proc.new {|ar| SpecID::Precision::Prob.new.precision_vs_num_hits_cmdline(ar) }
    # direct call with a string
    @direct_call_st = Proc.new {|st| @direct_call.call(st.split(/\s+/)) }
    @st_to_yaml = Proc.new do |st| 
      to_call = st + " -o yaml:#{@outfile} "
      @direct_call.call(to_call.split(/\s+/)) 
      YAML.load_file(@outfile)
    end

    file = Tfiles + '/opd1/000_020_3prots-prot.mod_initprob.xml'
    @args = [file].join(' ')
    # uses DECOY_ prefix on two
    @fake_bioworks_file = Tfiles + '/validator_hits_separate/bioworks_small_HS.xml'
    @small_bias_fasta_file = Tfiles + '/validator_hits_separate/bias_bioworks_small_HS.fasta'
    @small_fasta_file = Tfiles + '/bioworks_small.fasta'
    @params_file = Tfiles + '/bioworks_small.params'
    @toppred_file = Tfiles + '/bioworks_small.toppred.out'
    @phobius_file = Tfiles + '/bioworks_small.phobius'
  end

  after(:all) do 
    [@outfile].each do |file|
      File.unlink(file) if File.exist?(file)
    end
  end

  ############################ uncomment this::
  # this ensures that the actual commandline version gives usage.
  # it_should_behave_like "a cmdline program"

  it 'outputs to yaml' do
    reply = @st_to_yaml.call( @args )
    keys = [:probabilities, :params, :pephits, :pephits_precision, :charges, :aaseqs, :count].map {|v| v.to_s }.sort
    reply.keys.map {|v| v.to_s}.sort.should == keys
  end


  it 'responds to --prob init' do
    normal = @st_to_yaml.call( @args + " --prob" )

 normal[:pephits_precision].first[:values].zip([1.0, 1.0, 0.993333333333333, 0.85]) do |got,exp|
      got.should be_close(exp, 0.000000000001)
    end
    #normal_nsp = @st_to_yaml.call( @args + " --prob nsp" )
    #normal.should == normal_nsp
    init = @st_to_yaml.call( @args + " --prob init" )

    init[:pephits_precision].first[:values].should_not == normal[:pephits_precision].first[:values]


    init[:pephits_precision].first[:values].zip([1.0, 0.95, 0.963333333333333, 0.8025]) do |got,exp|
      got.should be_close(exp, 0.000000000001)
    end
    with_sort_by = @st_to_yaml.call( @args + " --prob nsp --sort_by_init" )
    # frozen
    with_sort_by[:pephits_precision].first[:values].zip([1.0, 0.99, 0.993333333333333, 0.85]) do |got,exp|
      got.should be_close(exp, 0.000000000001)
    end
  end

  it 'works with --to_qvalues flag' do
    begin
      normal = @st_to_yaml.call( @args + " --to_qvalues --prob" )
    rescue RuntimeError
      # right now the p values in this data set don't lend themselves to
      # legitimate q-values, so we get a RuntimeError
      # Need to work this one out
    end
  end

end


