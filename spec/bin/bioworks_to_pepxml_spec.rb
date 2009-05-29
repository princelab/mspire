require File.expand_path( File.dirname(__FILE__) + '/../spec_helper' )
require 'fileutils'


$XML_SANITY_LINES = ['<sample_enzyme name="Trypsin">', '<specificity cut="KR" no_cut="P" sense="C"/>', '<parameter name="diff_search_options" value="0.000000 S 0.000000 C 0.000000 M 0.000000 X 0.000000 T 0.000000 Y"/>']

$XML_SANITY_MATCHES = [/<spectrum_query spectrum="0\d0.\d+.\d+.[123]" start_scan="\d+" end_scan="\d+" precursor_neutral_mass="[\d\.]+" assumed_charge="[123]" index="\d+">/,
  /	<search_hit hit_rank="\d" peptide="[\w\-\.]+" peptide_prev_aa="." peptide_next_aa="." protein=".*" num_tot_proteins="\d+" num_matched_ions="\d+" tot_num_ions="\d+" calc_neutral_pep_mass="[\d\.]+" massdiff="[\+\-][\d\.]+" num_tol_term="\d" num_missed_cleavages="\d" is_rejected="[01]">/, 
  /<search_score name="xcorr" value="[\d\.]+"\/>/,
  /<search_score name="deltacn" value="[\d\.]+"\/>/, 
  /<search_score name="deltacnstar" value="[01]"\/>/, 
  /<search_score name="spscore" value="[\d\.]+"\/>/, 
  /<search_score name="sprank" value="\d+"\/>/,
]


describe 'bioworks_to_pepxml.rb' do
  before(:all) do
    @tf_mzxml_path = Tfiles_l + "/yeast_gly_mzXML"
    @tf_bioworks_xml = Tfiles + "/bioworks_small.xml"
    @tf_params = Tfiles + '/bioworks32.params'
    @out_path = Tfiles + '/pepxml/'
    @progname = 'bioworks_to_pepxml.rb'
    @no_delete = false
  end

  it_should_behave_like "a cmdline program"

  def _basic(cmd, prc)
    puts "Performing: #{cmd}" if $DEBUG
    reply = `#{cmd}`
    puts reply if $DEBUG
    %w(000 020).each do |file|
      ffile = @out_path + file + ".xml"
      prc.call(ffile)
    end
  end

  spec_large do
    it 'works on a real bioworks.xml file' do
      cmd = "#{@cmd} -p #{@tf_params} -o #{@out_path} #{@tf_bioworks_xml} -m #{@tf_mzxml_path} -d /work/special/path --copy_mzxml"
      ## FILES EXIST:
      prc = proc {|file| 
        file.exist_as_a_file?.should be_true
        beginning = IO.readlines(file)[0,50].join("\n")
        $XML_SANITY_LINES.each do |line|
          beginning.should include(line)
          #beginning.include?(line).should be_true
        end
        $XML_SANITY_MATCHES.each do |match|
          beginning.should =~ match
        end
      }
      _basic(cmd, prc)
      ## COPY MZXML:
      %w(000 020).each do |file|
        mzxml_file = File.join(@out_path, "#{file}.mzXML")
        mzxml_file.exist_as_a_file?.should be_true
      end
      ## CLEANUP:
      unless @no_delete then FileUtils.rm_rf(@out_path) end
    end
  end

  spec_large do
    it 'transforms database name when its proper to do so' do
      cmd = "#{@cmd} -p #{@tf_params} -o #{@out_path} #{@tf_bioworks_xml} -m #{@tf_mzxml_path}" 
      db_re = /C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta/
      IO.read(@tf_params).should =~ db_re
      prc = proc {|file|
        file.exist_as_a_file?.should be_true
        IO.read(file).should_not =~ db_re
      }
      _basic(cmd, prc)
      unless @no_delete then FileUtils.rm_rf(@out_path) end
    end
  end
end

