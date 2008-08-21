require 'yaml'

require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )

require 'spec_id/precision/filter'

describe 'filter_and_validate.rb on small bioworks file' do
  before(:all) do
    @progname = 'filter_and_validate.rb'

    @outfile = Tfiles + '/filter_and_validate.tmp'

    # direct call with an array
    @direct_call = Proc.new {|ar| SpecID::Precision::Filter.new.filter_and_validate_cmdline(ar) }
    # direct call with a string
    @direct_call_st = Proc.new {|st| @direct_call.call(st.split(/\s+/)) }
    @st_to_yaml = Proc.new do |st| 
      to_call = st + " -o yaml:#{@outfile} "
      @direct_call.call(to_call.split(/\s+/)) 
      YAML.load_file(@outfile)
    end

    @args = ["-1 0.6 -2 0.8 -3 0.9 -d 0.2", (Tfiles + '/bioworks_small.xml ')].join(' ')
    @interactive_file = Tfiles + '/interactive.tmp'
    File.open(@interactive_file,'w') do |fh| 
      string = ["0.6 0.8 0.9 0.2 5000", "dcns:f", "0.6 0.8 dcns:t", "pf:s", "pf:ac", "pf:a"].join("\n")
      fh.puts string
    end
    # uses DECOY_ prefix on two
    @fake_bioworks_file = Tfiles + '/validator_hits_separate/bioworks_small_HS.xml'
    @small_bias_fasta_file = Tfiles + '/validator_hits_separate/bias_bioworks_small_HS.fasta'
    @small_fasta_file = Tfiles + '/bioworks_small.fasta'
    @params_file = Tfiles + '/bioworks_small.params'
    @toppred_file = Tfiles + '/bioworks_small.toppred.out'
    @phobius_file = Tfiles + '/bioworks_small.phobius'
    @table_output_file = Tfiles + '/table_output.tmp'
  end

  after(:all) do
    [@outfile, @interactive_file, @table_output_file].each do |file|
      File.unlink(file) if File.exist?(file)
    end
  end

  # this ensures that the actual commandline version gives usage.
  it_should_behave_like "a cmdline program"

  it 'filters a file and outputs to table or yaml' do
    @direct_call_st.call( @args + " -o text_table:#{@outfile}")
    IO.read(@outfile).should =~ /66/
    struct = @st_to_yaml.call( @args )
    struct['pephits'].should == 66
  end

  it 'responds to --no_deltacnstar' do
    reply_without = @st_to_yaml.call( @args + " --no_deltacnstar" )
    reply_without['pephits'].should == 34
  end

  it 'works with interactive input (includes dcnstar and postfilter)' do
    @direct_call_st.call( "-o text_table:#{@outfile} -i #{@interactive_file} "  + Tfiles + '/bioworks_small.xml ' )
    reply = IO.read(@outfile)

    exp = %w(73 40 73 73 33 33)
    reply.scan(/^peps\s+(\d+)/) do |v|
      Regexp.last_match[1] == exp.shift
    end
  end

  it 'responds to ppm filter' do
    reply_without = @st_to_yaml.call( @args + " -p 280" )
    reply_without['pephits'].should == 11
  end

  it 'responds to --hits_separate' do
    # this file has two decoy peps that score better than the real peps at
    # those scans
        ht_file = Tfiles + '/test_together.tmp.yaml'
    hs_file = Tfiles + '/test_separate.tmp.yaml'
    outputs = [ht_file, hs_file].zip(['', ' --hits_separate']).map do |output_file, flag|
      run_normal = @cmd + " --bias #{@small_bias_fasta_file} --decoy /^DECOY_/ --digestion #{@small_fasta_file},#{@params_file} #{@fake_bioworks_file} -1 0.0 -2 0.0 -3 0.0 -d 0.01 -p 1000000 -o yaml:#{output_file} #{flag}"
      `#{run_normal}`
    end
    structs = [ht_file, hs_file].map do |file| 
      file.exist_as_a_file?.should be_true
      struct = YAML.load_file(file)
      File.unlink file
      struct
    end

    comparisons = %w(precision calc_bkg hits_together_param)
    comps = structs.map do |st|
      # note that calculated_background may need to be a string if we get our
      # act together...
      [ st['pephits_precision'][0]['value'], st['params']['validators'][0][:calculated_background], st['params']['hits_together'] ]
    end
    comparisons.zip( *comps ) do |tp, ht, hs|
      ht.should_not == hs
    end

  end

  it 'raises error on > 1 decoy validator' do
    lambda { @st_to_yaml.call( @args + " --decoy /hello/ --decoy path/to/file" ) }.should raise_error(ArgumentError)
  end

  it 'handles multiple validators of the same kind (except, of course, decoy)' do

    struct = @st_to_yaml.call( "#{@fake_bioworks_file} --proteins  -1 0.0 -2 0.0 -3 0.0 -d 0.01 -p 1000000 --decoy /^DECOY_/ --digestion #{@small_fasta_file},#{@params_file} --bad_aa_est C,0.001 --bad_aa_est E --bad_aa C,0.001 --bias #{@small_bias_fasta_file},true --bias #{@small_bias_fasta_file},false --bias #{@small_bias_fasta_file},true,0.2 --fasta #{@small_fasta_file} --tmm #{@phobius_file},1,true,0.8,0.2 --tmm #{@phobius_file} --tmm #{@toppred_file},3,true,false --tmm #{@toppred_file} --tps #{@small_bias_fasta_file} -o text_table:#{@table_output_file} " )
    frozen = YAML.load_file( File.dirname(__FILE__) + "/filter_and_validate__multiple_vals_helper.yaml" )

    ## Pephits precision:
    ordering = frozen['pephits_precision'].map {|v| v['validator'] }
    vals = frozen['pephits_precision'].map {|v| v['value'] }
    struct['pephits_precision'].zip(ordering, vals) do |act, vali, val|
      act['validator'].should == vali
      act['value'].should == val
    end

    struct['pephits'].should == frozen['pephits']

    ##### Params:
    frp = frozen['params']
    stp = struct['params']

    #puts "frozen validators:"
    #p frp['validators']

    #puts "seen validators:"
    #p stp['validators']

    frp['validators'].zip(stp['validators']) do |f,s|
      if f.is_a? Hash
        f.keys.each do |k|
          if k == :file or k == :transmem_file
            File.basename(f[k]).should == File.basename(s[k].gsub('\\','/'))
          else
            s[k].should == f[k]
            #f[k].should == s[k]
          end
        end
      else
        f.should == s
      end
    end

    %w(ties prefilter top_hit_by decoy_on_match postfilter include_ties_in_top_hit_postfilter hits_together proteins include_ties_in_top_hit_prefilter).each do |k|
      stp[k].should == frp[k]
    end
    
    ## digestion & output (special)
    %w(digestion output).each do |k|
      stp[k].zip(frp[k]).each do |s,f|
        File.basename( s.gsub('\\', '/') ).should == File.basename(f)
      end
    end

    ## Sequest:
    frp['sequest'].each do |k,v|
      stp['sequest'][k].should == v
    end

    ## TODO: Fill in protein level stuff once stabilized

    #struct.should == frozen

    text_table = IO.read(@table_output_file)

    # frozen
    headings_re = Regexp.new( %w(num decoy badAAEst badAAEst badAA  bias  bias  bias   tmm   tmm   tmm   tmm   tps).join("\\s+") )
    data_re = Regexp.new( %w(peps 283 0.993 0.178006 -0.024765 0.301 0.195 -4.793 0.403 0.438 -0.267 -0.156 -0.020 0.226).join("\\s+") )
    prot_re = Regexp.new( %w(106 0.972 0.018868   0.0 0.038 0.019   0.0 0.094 0.123   0.0   0.0   0.0 0.028).join("\\s+") )
    text_table.should =~ headings_re
    text_table.should =~ data_re
    text_table.should =~ prot_re
  end

end


