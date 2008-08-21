module SRFHelper

  File_32 = {
    :header => 
    {
      :params_filename=>"C:\\Xcalibur\\sequest\\john\\opd1_2runs_2mods\\ecoli.params",
      :raw_filename=>"C:\\Xcalibur\\data\\john\\opd00001\\020.RAW", 
      :modifications=>"(M* +15.99940) (STY# +79.97990)",
      :sequest_log_filename=>"C:\\Xcalibur\\sequest\\john\\opd1_2runs_2mods\\020_sequest.log",
      :ion_series=>"ion series nABY ABCDVWXYZ: 0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0",
      :db_filename=>"C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta",
      :enzyme=>"Enzyme:Trypsin(KR/P) (2)",
      :version=>"3.2",
      :model=>"LCQ Deca XP",
      :dta_log_filename=>"C:\\Xcalibur\\sequest\\john\\opd1_2runs_2mods\\020_dta.log"
    },
    :dta_gen => {
      :min_group_count => 1,
      :start_time => 1.5,
      :start_mass => 300.0,
      :end_scan => 3620,
      :group_scan => 1,
      :start_scan => 1,
      :num_dta_files => 3747,
      :min_ion_threshold => 15,
      :end_mass => 4500.0,
    },
    :dta_files_first => {

      :mh=>390.92919921875,
      :dta_tic=>9041311.0,
      :num_peaks=>48,
      :charge=>1,
      :ms_level=>2,
      :total_num_possible_charge_states=>0,
    },
    :dta_files_last => {
      :dta_tic=>842424.0,
      :mh=>357.041198730469,
      :num_peaks=>78,
      :ms_level=>2,
      :charge=>1,
      :total_num_possible_charge_states=>0,
    },
    :out_files_first => {
      :num_hits => 0,
      :computer => 'VELA',
      :date_time => '05/06/2008, 02:08 PM,',
      :hits => 0,
    },
    :out_files_last => {
      :num_hits => 0,
      :computer => 'VELA',
      :date_time => '05/06/2008, 02:11 PM,',
      :hits => 0,
    },
    :out_files_first_pep => {
      :aaseq=>"YRLGGSTK",
      :sequence=>"R.Y#RLGGS#T#K.K",
      :mh=>1121.9390244522,
      :deltacn_orig=>0.0,
      :sp=>29.8529319763184,
      :xcorr=>0.123464643955231,
      :id=>2104,
      :rsp=>1,
      :ions_matched=>5,
      :ions_total=>35,
      :prots=>1,
      :deltamass=>-0.00579976654989878,
      :ppm=>5.16938660859491,
      :base_name=>"020",
      :first_scan=>3,
      :last_scan=>3,
      :charge=>1,
      :deltacn=>0.795928299427032,
      :base_name=>"020",
    },
    :out_files_last_pep => 
    {
      :aaseq=>"LLPGTARTMRR",
      :sequence=>"R.LLPGTARTMRR.M",
      :mh=>1272.5493424522,
      :deltacn_orig=>0.835508584976196,
      :deltacn=>1.1,
      :sp=>57.9885787963867,
      :xcorr=>0.109200321137905,
      :id=>1361,
      :rsp=>11,
      :ions_matched=>6,
      :ions_total=>40,
      :prots=>1,
      :deltamass=>0.00243330985608736,
      :ppm=>1.91215729542523,
      :base_name=>"020",
      :first_scan=>3619,
      :last_scan=>3619,
      :charge=>3,
      :deltacn=>1.1,
      :base_name=>"020",
    },

    :params => {
        "add_O_Ornithine"=>"0.0000", "add_F_Phenylalanine"=>"0.0000", "add_A_Alanine"=>"0.0000", "add_C_Cysteine"=>"0.0000", "add_Y_Tyrosine"=>"0.0000", "add_X_LorI"=>"0.0000", "add_J_user_amino_acid"=>"0.0000", "add_Cterm_peptide"=>"0.0000", "add_S_Serine"=>"0.0000", "add_Nterm_protein"=>"0.0000", "add_D_Aspartic_Acid"=>"0.0000", "add_Q_Glutamine"=>"0.0000", "add_K_Lysine"=>"0.0000", "add_R_Arginine"=>"0.0000", "add_W_Tryptophan"=>"0.0000", "add_Nterm_peptide"=>"0.0000", "add_H_Histidine"=>"0.0000", "add_L_Leucine"=>"0.0000", "add_I_Isoleucine"=>"0.0000", "add_N_Asparagine"=>"0.0000", "add_B_avg_NandD"=>"0.0000", "add_Z_avg_QandE"=>"0.0000", "add_E_Glutamic_Acid"=>"0.0000", "add_G_Glycine"=>"0.0000", "add_P_Proline"=>"0.0000", "add_M_Methionine"=>"0.0000", "add_Cterm_protein"=>"0.0000", "add_V_Valine"=>"0.0000", "add_T_Threonine"=>"0.0000", "add_U_user_amino_acid"=>"0.0000", "match_peak_tolerance"=>"1.0000", "match_peak_allowed_error"=>"1", "normalize_xcorr"=>"0", "nucleotide_reading_frame"=>"0", "num_results"=>"250", "sequence_header_filter"=>"", "diff_search_options"=>"15.999400 M 79.979900 STY 0.000000 M 0.000000 X 0.000000 T 0.000000 Y", "partial_sequence"=>"", "max_num_internal_cleavage_sites"=>"2", "search_engine"=>"SEQUEST", "print_duplicate_references"=>"40", "ion_series"=>"0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0", "remove_precursor_peak"=>"0", "num_output_lines"=>"10", "second_database_name"=>"", "first_database_name"=>"C:\\Xcalibur\\database\\ecoli_K12_ncbi_20060321.fasta", "peptide_mass_tolerance"=>"25.0000", "digest_mass_range"=>"600.0 3500.0", "enzyme_info"=>"Trypsin(KR/P) 1 1 KR P", "show_fragment_ions"=>"0", "protein_mass_filter"=>"0 0", "term_diff_search_options"=>"0.000000 0.000000", "num_description_lines"=>"5", "fragment_ion_tolerance"=>"1.0000", "peptide_mass_units"=>"2", "mass_type_parent"=>"0", "match_peak_count"=>"0", "max_num_differential_per_peptide"=>"3", "ion_cutoff_percentage"=>"0.0000", "mass_type_fragment"=>"0"
    }
  }

  File_33 = {}
  File_32.each do |k,v|
    File_33[k] = v.dup
  end

  ## Bioworks 3.3 (srf version 3.3)
  File_33[:header][:raw_filename] = "C:\\Xcalibur\\data\\john\\021112-EcoliSol37-1\\020.RAW"
  File_33[:header][:version] = "3.3"

  File_33[:out_files_first][:computer] = 'TESLA'
  File_33[:out_files_first][:date_time] = '04/24/2007, 10:41 AM,'
  File_33[:out_files_last][:computer] = 'TESLA'
  File_33[:out_files_last][:date_time] = '04/24/2007, 10:42 AM,'

  File_33[:out_files_first_pep][:sp] = 29.8535556793213
  File_33[:out_files_last_pep][:sp] = 57.987476348877
  File_33[:out_files_last_pep][:rsp] = 10
  File_33[:out_files_last_pep][:deltacn_orig] = 0.835624694824219


  ## Bioworks 3.3.1 (srf version 3.5)
  File_331 = {}
  File_33.each do |k,v|
    File_331[k] = v.dup
  end
  File_331[:header][:raw_filename] = "C:\\Xcalibur\\data\\john\\opd1_2runs_2mods\\020.RAW"
  File_331[:header][:version] = "3.5"
  File_331[:out_files_first][:date_time] = '05/06/2008, 03:31 PM,'
  File_331[:out_files_last][:date_time] = '05/06/2008, 03:32 PM,'

end


