require 'spec_helper'

require 'ms/mass'
require 'ms/mass/aa'
require 'ms/ident/pepxml'
require 'ms/ident/pepxml/modifications'
require 'ms/ident/pepxml/spectrum_query'
require 'ms/ident/pepxml/search_result'
require 'ms/ident/pepxml/search_hit'
require 'ms/ident/pepxml/search_hit/modification_info'

describe "creating an MS::Ident::Pepxml" do
  include MS::Ident

  it "can be creating in a nested fashion reflecting internal structure" do
    tags_that_should_be_present = %w(msms_pipeline_analysis msms_run_summary sample_enzyme search_summary spectrum_query search_result search_hit modification_info mod_aminoacid_mass search_score)

    pepxml = Pepxml.new do |msms_pipeline_analysis|
      msms_pipeline_analysis.merge!(:summary_xml => "020.xml") do |msms_run_summary|
        # prep the sample enzyme and search_summary
        msms_run_summary.merge!(
          :base_name => '/home/jtprince/dev/mspire/020', 
          :ms_manufacturer => 'Thermo', 
          :ms_model => 'LTQ Orbitrap', 
          :ms_ionization => 'ESI', 
          :ms_mass_analyzer => 'Ion Trap', 
          :ms_detector => 'UNKNOWN'
        ) do |sample_enzyme, search_summary, spectrum_queries|
          sample_enzyme.merge!(:name=>'Trypsin',:cut=>'KR',:no_cut=>'P',:sense=>'C')
          search_summary.merge!(
            :base_name=>'/path/to/file/020',
            :search_engine => 'SEQUEST',
            :precursor_mass_type =>'monoisotopic',
            :fragment_mass_type => 'average'
          ) do |search_database, enzymatic_search_constraint, modifications, parameters|
            search_database.merge!(:local_path => '/path/to/db.fasta', :seq_type => 'AA') # note seq_type == type
            enzymatic_search_constraint.merge!(
              :enzyme => 'Trypsin', 
              :max_num_internal_cleavages => 2,
              :min_number_termini => 2
            )
            modifications << Pepxml::AminoacidModification.new(
              :aminoacid => 'M', :massdiff => 15.9994, :mass => MS::Mass::AA::MONO['M']+15.9994,
              :variable => 'Y', :symbol => '*')
              # invented, for example, a protein terminating mod
            modifications << Pepxml::TerminalModification.new( 
              :terminus => 'c', :massdiff => 23.3333, :mass => MS::Mass::MONO['oh'] + 23.3333, 
              :variable => 'Y', :symbol => '[', :protein_terminus => 'c', 
              :description => 'leave protein_terminus off if not protein mod'
            )
            modifications << Pepxml::TerminalModification.new( 
              :terminus => 'c', :massdiff => 25.42322, :mass => MS::Mass::MONO['h+'] + 25.42322, 
              :variable => 'N', :symbol => ']', :description => 'example: c term mod'
            )
            parameters.merge!( 
                              :fragment_ion_tolerance => 1.0000, 
                              :digest_mass_range => '600.0 3500.0', 
                              :enzyme_info => 'Trypsin(KR/P) 1 1 KR P', # etc.... 
                             )
          end
          spectrum_query1 = Pepxml::SpectrumQuery.new(
            :spectrum  => '020.3.3.1', :start_scan => 3, :end_scan => 3, 
            :precursor_neutral_mass => 1120.93743421875, :assumed_charge => 1
          ) do |search_results|
            search_result1 = Pepxml::SearchResult.new do |search_hits|
              modpositions = [[1, 243.1559], [6, 167.0581], [7,181.085]].map do |pair|  
                Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new(*pair)
              end
              # order(modified_peptide, mod_aminoacid_masses, :mod_nterm_mass, :mod_cterm_mass)
              # or can be set by hash
              mod_info = Pepxml::SearchHit::ModificationInfo.new('Y#RLGGS#T#K', modpositions)
              search_hit1 = Pepxml::SearchHit.new( 
                :hit_rank=>1, :peptide=>'YRLGGSTK', :peptide_prev_aa => "R", :peptide_next_aa => "K",
                :protein => "gi|16130113|ref|NP_416680.1|", :num_tot_proteins => 1, :num_matched_ions => 5,
                :tot_num_ions => 35, :calc_neutral_pep_mass => 1120.93163442, :massdiff => 0.00579979875010395,
                :num_tol_term => 2, :num_missed_cleavages => 1, :is_rejected => 0, 
                :modification_info => mod_info) do |search_scores|
                  search_scores.merge!(:xcorr => 0.12346, :deltacn => 0.7959, :deltacnstar => 0, 
                                     :spscore => 29.85, :sprank => 1)
                end
              search_hits << search_hit1
            end
            search_results << search_result1
          end
          spectrum_queries << spectrum_query1
        end
      end
    end
    xml = pepxml.to_xml
    tags_that_should_be_present.each do |tag|
      xml.should match(/<#{tag} ?/)
    end
    xml.should match( /<\?xml version="1.0" encoding="UTF-8"\?>/ )
    xml.should match( %r{<\?xml-stylesheet type="text/xsl" href="/tools/bin/TPP/tpp/schema/pepXML_std.xsl"\?>} )
  end
end

=begin
    # splits string on ' 'and matches the line found by find_line_regexp in
    # lines
    def match_modline_pieces(lines, find_line_regexp, string)
      pieces = string.split(' ').map {|v| /#{Regexp.escape(v)}/ }
      lines.each do |line|
        if line =~ find_line_regexp
          pieces.each do |piece|
            line.should =~ piece
          end
        end
      end
    end


    it 'gets modifications right in real run' do
      @out_files.each do |fn|
        fn.exist_as_a_file?.should be_true
        beginning = IO.read(fn) 
        lines = beginning.split("\n")
        [
          [/aminoacid="M"/, '<aminoacid_modification symbol="*" massdiff="+15.9994" aminoacid="M" variable="Y" binary="N" mass="147.192"'],

          [/aminoacid="S"/, '<aminoacid_modification symbol="#" massdiff="+79.9799" aminoacid="S" variable="Y" binary="N" mass="167.0581"'],
          [/aminoacid="T"/, '<aminoacid_modification symbol="#" massdiff="+79.9799" aminoacid="T" variable="Y" binary="N" mass="181.085"'],
          [/aminoacid="Y"/, '<aminoacid_modification symbol="#" massdiff="+79.9799" aminoacid="Y" variable="Y" binary="N" mass="243.1559"'],
          [/parameter name="diff_search_options"/, '<parameter name="diff_search_options" value="15.999400 M 79.979900 STY 0.000000 M 0.000000 X 0.000000 T 0.000000 Y"/>'],
        ].each do |a,b|
          match_modline_pieces(lines, a, b)
        end
        [
        '<modification_info modified_peptide="Y#RLGGS#T#K">',
        '<mod_aminoacid_mass position="1" mass="243.1559"/>',
        '<mod_aminoacid_mass position="7" mass="167.0581"/>',
        '</modification_info>',
        '<mod_aminoacid_mass position="9" mass="181.085"/>'
        ].each do |line|
          beginning.should =~ /#{Regexp.escape(line)}/ # "a modification info for a peptide")
        end
      end
    end
  end
end



=begin
describe "MS::Ident::Pepxml created from small bioworks.xml" do

  spec_large do
    before(:all) do
      tf_mzxml_path = Tfiles_l + "/yeast_gly_mzXML"

      tf_params = Tfiles + "/bioworks32.params"
      tf_bioworks_xml = Tfiles + "/bioworks_small.xml"
      out_path = Tfiles
      @pepxml_objs = Sequest::Pepxml.set_from_bioworks(tf_bioworks_xml, :params => tf_params, :ms_data => tf_mzxml_path, :out_path => out_path)
    end

    it 'gets some spectrum queries' do
      @pepxml_objs.each do |obj|
        (obj.spectrum_queries.size > 2).should be_true
        (obj.spectrum_queries.first.search_results.first.search_hits.size > 0).should be_true
      end
      #@pepxml_objs.each do |pep| puts pep.to_pepxml end
    end
  end
end



describe Sequest::Pepxml, " created from large bioworks.xml" do
  # assert_equal_by_pairs (really any old array)
  def assert_equal_pairs(obj, arrs)
    arrs.each do |arr|
      #if obj.send(arr[1]) != arr[0]
      #  puts "HELLO"
      #  puts "OBJ answer"
      #  p obj.send(arr[1])
      #  puts "ar0"
      #  p arr[0]
      #  puts "ar1"
      #  p arr[1]
      #end
      if arr[0].is_a? Float
        obj.send(arr[1]).should be_close(arr[0], 0.0000000001)
      else
        obj.send(arr[1]).should == arr[0]
      end
    end
  end

  #swap the first to guys first
  def assert_equal_pairs_swapped(obj, arrs)
    arrs.each do |arr|
      arr[0], arr[1] = arr[1], arr[0] 
    end
    assert_equal_pairs(obj, arrs)
  end

  spec_large do
    before(:all) do
      st = Time.new
      params = Tfiles + "/opd1/sequest.3.2.params"
      bioworks_xml = Tfiles_l + "/opd1/bioworks.000.oldparams.xml"
      mzxml_path = Tfiles_l + "/opd1"
      out_path = Tfiles
      @pepxml_version = 18
      @pepxml_objs = Sequest::Pepxml.set_from_bioworks_xml(bioworks_xml, params, {:ms_data => mzxml_path, :out_path => out_path, :pepxml_version => @pepxml_version})
      puts "- takes #{Time.new - st} secs"
    end

    it 'extracts MSMSPipelineAnalysis' do
      ######## HMMMMM...
      Sequest::Pepxml.pepxml_version.should == @pepxml_version

      # MSMSPipelineAnalysis
      po = @pepxml_objs.first
      msms_pipeline = po.msms_pipeline_analysis
      msms_pipeline.xmlns.should == 'http://regis-web.systemsbiology.net/pepXML'
      msms_pipeline.xmlns_xsi.should == 'http://www.w3.org/2001/XMLSchema-instance'
      msms_pipeline.xsi_schema_location.should == 'http://regis-web.systemsbiology.net/pepXML /tools/bin/TPP/tpp/schema/pepXML_v18.xsd'
      msms_pipeline.summary_xml.should == '000.xml'
    end

    it 'extracts MSmSRunSummary' do
      # MSMSRunSummary
      rs = @pepxml_objs.first.msms_pipeline_analysis.msms_run_summary
      rs.base_name.should =~ /\/000/
      assert_equal_pairs(rs, [ ['ThermoFinnigan', :ms_manufacturer], ['LCQ Deca XP Plus', :ms_model], ['ESI', :ms_ionization], ['Ion Trap', :ms_mass_analyzer], ['UNKNOWN', :ms_detector], ['raw', :raw_data_type], ['.mzXML', :raw_data], ])
    end

    it 'extracts SampleEnzyme' do
      # SampleEnzyme
      se = @pepxml_objs.first.msms_pipeline_analysis.msms_run_summary.sample_enzyme
      assert_equal_pairs(se, [ ['Trypsin', :name], ['KR', :cut], [nil, :no_cut], ['C', :sense], ])
    end

    it 'extracts SearchSummary' do
      # SearchSummary
      ss = @pepxml_objs.first.msms_pipeline_analysis.msms_run_summary.search_summary
      ss.is_a?(Sequest::Pepxml::SearchSummary).should be_true
      ss.base_name.should =~ /\/000/
      ss.peptide_mass_tol.should =~ /1\.500/
      assert_equal_pairs_swapped(ss, [ # normal attributes
                                 [:search_engine, "SEQUEST"], [:precursor_mass_type, "average"], [:fragment_mass_type, "average"], [:out_data_type, "out"], [:out_data, ".tgz"], [:search_id, "1"],

                                 # enzymatic_search_constraint
                                 [:enzyme, 'Trypsin'], [:max_num_internal_cleavages, '2'], [:min_number_termini, '2'],

                                 # parameters
                                 [:fragment_ion_tol, "1.0000"], [:ion_series, "0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0"], [:max_num_differential_AA_per_mod, "3"], [:nucleotide_reading_frame, "0"], [:num_output_lines, "10"], [:remove_precursor_peak, "0"], [:ion_cutoff_percentage, "0.0000"], [:match_peak_count, "0"], [:match_peak_allowed_error, "1"], [:match_peak_tolerance, "1.0000"], [:protein_mass_filter, "0 0"],
      ])

    end
    it 'extracts SearchDatabase' do
      # SearchDatabase
      sd = @pepxml_objs.first.msms_pipeline_analysis.msms_run_summary.search_summary.search_database
      sd.is_a?(Sequest::Pepxml::SearchDatabase).should be_true
      assert_equal_pairs_swapped(sd, [ [:local_path, "C:\\Xcalibur\\database\\ecoli_K12.fasta"], [:seq_type, 'AA'], ])
    end

    it 'returns SpectrumQueries' do
      # SpectrumQueries
      sq = @pepxml_objs.first.msms_pipeline_analysis.msms_run_summary.spectrum_queries
      spec = sq.first 
      assert_equal_pairs_swapped(spec, [
                                 [:spectrum, "000.100.100.1"], [:start_scan, "100"], [:end_scan, "100"],
                                 #[:precursor_neutral_mass, "1074.5920"], # out2summary
                                 [:precursor_neutral_mass, 1074.666926], # mine
                                 [:assumed_charge, 1], [:index, "1"],
      ])
      sh = spec.search_results.first.search_hits.first
      assert_equal_pairs_swapped(sh, [
                                 # normal attributes
                                 [:hit_rank, 1], 
                                 [:peptide, "SIYFRNFK"], 
                                 [:peptide_prev_aa, "R"], 
                                 [:peptide_next_aa, "G"], 
                                 [:protein, "gi|16130084|ref|NP_416651.1|"], 
                                 [:num_tot_proteins, 1], 
                                 [:num_matched_ions, 4], 
                                 [:tot_num_ions, 14],
                                 #[:calc_neutral_pep_mass, "1074.1920"], # out2summary
                                 [:calc_neutral_pep_mass, 1074.23261], # mine
                                 #[:massdiff, "+0.400000"], # out2summary
                                 [:massdiff, 0.434316000000081],  # mine
                                 [:num_tol_term, 2], [:num_missed_cleavages, 1], [:is_rejected, 0],

                                 # search_score
                                 [:xcorr, 0.4], [:deltacn, 0.023], [:deltacnstar, "0"], [:spscore, 78.8], [:sprank, 1],
      ])

      spec = sq[1]
      assert_equal_pairs_swapped(spec, [
                                 [:spectrum, "000.1000.1000.1"], [:start_scan, "1000"], [:end_scan, "1000"], #[:precursor_neutral_mass, "663.1920"], # out2summary
                                 [:precursor_neutral_mass, 663.206111], # mine
                                 [:assumed_charge, 1], [:index, "2"],
      ])

      sh = spec.search_results.first.search_hits.first
      assert_equal_pairs_swapped(sh, [
                                 # normal attributes
                                 [:hit_rank, 1], [:peptide, "ALADFK"], [:peptide_prev_aa, "R"], [:peptide_next_aa, "S"], [:protein, "gi|16128765|ref|NP_415318.1|"], [:num_tot_proteins, 1], [:num_matched_ions, 5], [:tot_num_ions, 10],
                                 [:num_tol_term, 2], [:num_missed_cleavages, 0], [:is_rejected, 0],
                                 #[:massdiff, "-0.600000"], # out2summary
                                 [:massdiff, -0.556499000000031],  # mine
                                 #[:calc_neutral_pep_mass, 663.7920], # out2summary
                                 [:calc_neutral_pep_mass, 663.76261], # mine

                                 # search_score
                                 [:xcorr, 0.965], [:deltacn, 0.132], [:deltacnstar, "0"], [:spscore, 81.1], [:sprank, 1],
      ])

      spec = sq[9]
      assert_equal_pairs_swapped(spec, [
                                 [:spectrum, "000.1008.1008.2"], [:start_scan, "1008"], [:end_scan, "1008"], [:assumed_charge, 2],
                                 #[:precursor_neutral_mass, "691.0920"], # out2summary
                                 [:precursor_neutral_mass, 691.150992], # mine
      ])

      sh = spec.search_results.first.search_hits.first
      assert_equal_pairs_swapped(sh, [
                                 # normal attributes
                                 [:hit_rank, 1], [:peptide, "RLFTR"], [:peptide_prev_aa, "R"], [:peptide_next_aa, "A"], [:protein, "gi|16130457|ref|NP_417027.1|"], [:num_tot_proteins, 1], [:num_matched_ions, 5], [:tot_num_ions, 8], [:num_tol_term, 2], 

                                 #[:num_missed_cleavages, "0"],  # out2summary misses this!
                                 [:num_missed_cleavages, 1], 
                                 [:is_rejected, 0],
                                 #[:calc_neutral_pep_mass, "691.7920"], # out2summary
                                 [:calc_neutral_pep_mass, 691.82261], # mine
                                 #[:massdiff, "-0.700000"], # out2summary
                                 [:massdiff, -0.67161800000008],  # mine

                                 # search_score
                                 [:xcorr, 0.903], [:deltacn, 0.333], [:deltacnstar, "0"], [:spscore, 172.8], [:sprank, 1],
      ])
    end

    it 'can generate correct pepxml file' do
      
      ## IF OUR OBJECT IS CORRECT, THEN WE GET THE OUTPUT:
      string = @pepxml_objs.first.to_pepxml
      ans_lines = IO.read(Tfiles + "/opd1/000.my_answer.100lines.xml").split("\n")
      base_name_re = /base_name=".*?files\//o
      date_re = /date=".*?"/
      string.split("\n").each_with_index do |line,i|
        if i > 99 ; break end
        ans, exp = 
          if i == 1
            [line.sub(date_re,''), ans_lines[i].sub(date_re,'')]
          elsif i == 2 
            [line.sub(base_name_re,''), ans_lines[i].sub(base_name_re, '').sub(/^\s+/, "\t")]
          elsif i == 6
            [line.sub(base_name_re,''), ans_lines[i].sub(base_name_re, '').sub(/^\s+/, "\t\t")]
          else
            [line, ans_lines[i]]
          end

        #ans.split('').zip(exp.split('')) do |l,a|
        #  if l != a
        #    puts line
        #    puts ans_lines[i]
        #    puts l
        #    puts a
        #  end
        #end
        if ans != exp
          puts ans
          puts exp
        end
        ans.should == exp
        #line.sub(base_name_re,'').should == ans_lines[i].sub(base_name_re,'')
      end
    end
  end
end



describe Sequest::Pepxml::Modifications do
  before(:each) do
    tf_params = Tfiles + "/bioworks32.params"
    @params = Sequest::Params.new(tf_params)
    # The params object here is completely unnecessary for this test, except
    # that it sets up the mass table
    @obj = Sequest::Pepxml::Modifications.new(@params, "(M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000) ")
  end
  it 'creates a mod_symbols_hash' do
    answ = {[:C, 12.0]=>"^", [:S, 80.0]=>"@", [:M, 29.0]=>"#", [:M, 15.9]=>"*", [:ct, 12.33]=>"[", [:nt, 14.2]=>"]"}
    @obj.mod_symbols_hash.should == answ
    ## need more here
  end

  it 'creates a ModificationInfo object given a special peptide sequence' do
    mod_string = "(M* +15.90000) (M# +29.00000) (S@ +80.00000) (C^ +12.00000) (ct[ +12.33000) (nt] +14.20000) "
    @params.diff_search_options = "15.90000 M 29.00000 M 80.00000 S 12.00000 C"
    @params.term_diff_search_options = "14.20000 12.33000"
    mod = Sequest::Pepxml::Modifications.new(@params, mod_string)
    ## no mods
    peptide = "PEPTIDE"
    mod.modification_info(peptide).should be_nil
    peptide = "]M*EC^S@IDM#M*EMSCM["
    modinfo = mod.modification_info(peptide)
    modinfo.modified_peptide.should == peptide
    modinfo.mod_nterm_mass.should be_close(146.40054, 0.000001)
    modinfo.mod_cterm_mass.should be_close(160.52994, 0.000001)
  end

end

describe Sequest::Pepxml::SearchHit::ModificationInfo do

  before(:each) do
    modaaobjs = [[3, 150.3], [6, 345.2]].map do |ar| 
      Sequest::Pepxml::SearchHit::ModificationInfo::ModAminoacidMass.new(ar)
    end
    hash = {
      :mod_nterm_mass => 520.2,
      :modified_peptide => "MOD*IFI^E&D",
      :mod_aminoacid_masses => modaaobjs,
    }
    #answ = "<modification_info mod_nterm_mass=\"520.2\" modified_peptide=\"MOD*IFI^E&amp;D\">\n\t<mod_aminoacid_mass position=\"3\" mass=\"150.3\"/>\n\t<mod_aminoacid_mass position=\"6\" mass=\"345.2\"/>\n</modification_info>\n"
    @obj = Sequest::Pepxml::SearchHit::ModificationInfo.new(hash)
  end

  def _re(st)
    /#{Regexp.escape(st)}/
  end
  
  it 'can produce pepxml' do
    answ = @obj.to_pepxml
    answ.should =~ _re('<modification_info')
    answ.should =~ _re(" mod_nterm_mass=\"520.2\"")
    answ.should =~ _re(" modified_peptide=\"MOD*IFI^E&amp;D\"")
    answ.should =~ _re("<mod_aminoacid_mass")
    answ.should =~ _re(" position=\"3\"")
    answ.should =~ _re(" mass=\"150.3\"")
    answ.should =~ _re(" position=\"6\"") 
    answ.should =~ _re(" mass=\"345.2\"")
    answ.should =~ _re("</modification_info>")
  end
end

=end
