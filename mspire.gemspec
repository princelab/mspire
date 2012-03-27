# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "mspire"
  s.version = "0.7.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John T. Prince", "Simon Chiang"]
  s.date = "2012-03-27"
  s.description = "mass spectrometry proteomics, lipidomics, and tools, a rewrite of mspire, merging of ms-* gems"
  s.email = "jtprince@gmail.com"
  s.executables = ["mzml_to_imzml"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "bin/mzml_to_imzml",
    "lib/core_ext/array/in_groups.rb",
    "lib/cv.rb",
    "lib/cv/param.rb",
    "lib/cv/referenceable_param_group_ref.rb",
    "lib/io/bookmark.rb",
    "lib/merge.rb",
    "lib/mspire.rb",
    "lib/mspire/bin.rb",
    "lib/mspire/cv.rb",
    "lib/mspire/cv/param.rb",
    "lib/mspire/cv/paramable.rb",
    "lib/mspire/digester.rb",
    "lib/mspire/error_rate/decoy.rb",
    "lib/mspire/error_rate/qvalue.rb",
    "lib/mspire/fasta.rb",
    "lib/mspire/ident.rb",
    "lib/mspire/ident/peptide.rb",
    "lib/mspire/ident/peptide/db.rb",
    "lib/mspire/ident/peptide_hit.rb",
    "lib/mspire/ident/peptide_hit/qvalue.rb",
    "lib/mspire/ident/pepxml.rb",
    "lib/mspire/ident/pepxml/modifications.rb",
    "lib/mspire/ident/pepxml/msms_pipeline_analysis.rb",
    "lib/mspire/ident/pepxml/msms_run_summary.rb",
    "lib/mspire/ident/pepxml/parameters.rb",
    "lib/mspire/ident/pepxml/sample_enzyme.rb",
    "lib/mspire/ident/pepxml/search_database.rb",
    "lib/mspire/ident/pepxml/search_hit.rb",
    "lib/mspire/ident/pepxml/search_hit/modification_info.rb",
    "lib/mspire/ident/pepxml/search_result.rb",
    "lib/mspire/ident/pepxml/search_summary.rb",
    "lib/mspire/ident/pepxml/spectrum_query.rb",
    "lib/mspire/ident/protein.rb",
    "lib/mspire/ident/protein_group.rb",
    "lib/mspire/ident/search.rb",
    "lib/mspire/imzml/writer.rb",
    "lib/mspire/imzml/writer/commandline.rb",
    "lib/mspire/isotope.rb",
    "lib/mspire/isotope/aa.rb",
    "lib/mspire/isotope/distribution.rb",
    "lib/mspire/isotope/nist_isotope_info.yml",
    "lib/mspire/mascot.rb",
    "lib/mspire/mass.rb",
    "lib/mspire/mass/aa.rb",
    "lib/mspire/molecular_formula.rb",
    "lib/mspire/mzml.rb",
    "lib/mspire/mzml/activation.rb",
    "lib/mspire/mzml/chromatogram.rb",
    "lib/mspire/mzml/chromatogram_list.rb",
    "lib/mspire/mzml/component.rb",
    "lib/mspire/mzml/contact.rb",
    "lib/mspire/mzml/cv.rb",
    "lib/mspire/mzml/data_array.rb",
    "lib/mspire/mzml/data_array_container_like.rb",
    "lib/mspire/mzml/data_processing.rb",
    "lib/mspire/mzml/file_content.rb",
    "lib/mspire/mzml/file_description.rb",
    "lib/mspire/mzml/index_list.rb",
    "lib/mspire/mzml/instrument_configuration.rb",
    "lib/mspire/mzml/isolation_window.rb",
    "lib/mspire/mzml/list.rb",
    "lib/mspire/mzml/plms1.rb",
    "lib/mspire/mzml/precursor.rb",
    "lib/mspire/mzml/processing_method.rb",
    "lib/mspire/mzml/product.rb",
    "lib/mspire/mzml/referenceable_param_group.rb",
    "lib/mspire/mzml/run.rb",
    "lib/mspire/mzml/sample.rb",
    "lib/mspire/mzml/scan.rb",
    "lib/mspire/mzml/scan_list.rb",
    "lib/mspire/mzml/scan_settings.rb",
    "lib/mspire/mzml/scan_window.rb",
    "lib/mspire/mzml/selected_ion.rb",
    "lib/mspire/mzml/software.rb",
    "lib/mspire/mzml/source_file.rb",
    "lib/mspire/mzml/spectrum.rb",
    "lib/mspire/mzml/spectrum_list.rb",
    "lib/mspire/obo.rb",
    "lib/mspire/peak.rb",
    "lib/mspire/peak/point.rb",
    "lib/mspire/plms1.rb",
    "lib/mspire/quant/qspec.rb",
    "lib/mspire/quant/qspec/protein_group_comparison.rb",
    "lib/mspire/spectrum.rb",
    "lib/mspire/spectrum/centroid.rb",
    "lib/mspire/spectrum_like.rb",
    "lib/mspire/user_param.rb",
    "lib/obo/ims.rb",
    "lib/obo/ms.rb",
    "lib/obo/ontology.rb",
    "lib/obo/unit.rb",
    "lib/openany.rb",
    "lib/write_file_or_string.rb",
    "mspire.gemspec",
    "obo/ims.obo",
    "obo/ms.obo",
    "obo/unit.obo",
    "script/mzml_read_binary.rb",
    "spec/cv/param_spec.rb",
    "spec/mspire/bin_spec.rb",
    "spec/mspire/cv/param_spec.rb",
    "spec/mspire/digester_spec.rb",
    "spec/mspire/error_rate/qvalue_spec.rb",
    "spec/mspire/fasta_spec.rb",
    "spec/mspire/ident/peptide/db_spec.rb",
    "spec/mspire/ident/pepxml/sample_enzyme_spec.rb",
    "spec/mspire/ident/pepxml/search_hit/modification_info_spec.rb",
    "spec/mspire/ident/pepxml_spec.rb",
    "spec/mspire/ident/protein_group_spec.rb",
    "spec/mspire/imzml/writer_spec.rb",
    "spec/mspire/isotope/aa_spec.rb",
    "spec/mspire/isotope/distribution_spec.rb",
    "spec/mspire/isotope_spec.rb",
    "spec/mspire/mass_spec.rb",
    "spec/mspire/molecular_formula_spec.rb",
    "spec/mspire/mzml/cv_spec.rb",
    "spec/mspire/mzml/data_array_spec.rb",
    "spec/mspire/mzml/file_content_spec.rb",
    "spec/mspire/mzml/file_description_spec.rb",
    "spec/mspire/mzml/index_list_spec.rb",
    "spec/mspire/mzml/plms1_spec.rb",
    "spec/mspire/mzml/referenceable_param_group_spec.rb",
    "spec/mspire/mzml/source_file_spec.rb",
    "spec/mspire/mzml/spectrum_spec.rb",
    "spec/mspire/mzml_spec.rb",
    "spec/mspire/peak_spec.rb",
    "spec/mspire/plms1_spec.rb",
    "spec/mspire/quant/qspec_spec.rb",
    "spec/mspire/spectrum_spec.rb",
    "spec/mspire/user_param_spec.rb",
    "spec/mspire_spec.rb",
    "spec/obo_spec.rb",
    "spec/spec_helper.rb",
    "spec/testfiles/continuous_binary.tmp.ibd",
    "spec/testfiles/mspire/ident/peptide/db/uni_11_sp_tr.fasta",
    "spec/testfiles/mspire/ident/peptide/db/uni_11_sp_tr.msd_clvg2.min_aaseq4.yml",
    "spec/testfiles/mspire/imzml/continuous_binary_check.ibd",
    "spec/testfiles/mspire/imzml/processed_binary_check.ibd",
    "spec/testfiles/mspire/mzml/j24z.idx_comp.3.mzML",
    "spec/testfiles/mspire/mzml/mspire_simulated.MSn.check.mzML",
    "spec/testfiles/mspire/mzml/openms.noidx_nocomp.12.mzML",
    "spec/testfiles/mspire/quant/kill_extra_tabs.rb",
    "spec/testfiles/mspire/quant/max_quant_output.provenance.txt",
    "spec/testfiles/mspire/quant/max_quant_output.txt",
    "spec/testfiles/mspire/quant/pdcd5_final.killedextratabs.tsv",
    "spec/testfiles/mspire/quant/pdcd5_final.killedextratabs.tsv_qspecgp",
    "spec/testfiles/mspire/quant/pdcd5_final.killedextratabs.tsv_qspecgp.csv",
    "spec/testfiles/mspire/quant/pdcd5_final.txt",
    "spec/testfiles/mspire/quant/pdcd5_final.txt_qspecgp",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.CSV.csv",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.csv",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.oneprot.csv",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.oneprot.tsv",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.oneprot.tsv_qspecgp",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.oneprot.tsv_qspecgp.csv",
    "spec/testfiles/mspire/quant/pdcd5_lfq_qspec.txt",
    "spec/testfiles/mspire/quant/pdcd5_lfq_tabdel.txt",
    "spec/testfiles/mspire/quant/pdcd5_lfq_tabdel.txt_qspecgp",
    "spec/testfiles/mspire/quant/remove_rest_of_proteins.rb",
    "spec/testfiles/mspire/quant/unlog_transform.rb",
    "spec/testfiles/plms1/output.key",
    "spec/testfiles/processed_binary.tmp.ibd"
  ]
  s.homepage = "http://github.com/princelab/mspire"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.18"
  s.summary = "mass spectrometry proteomics, lipidomics, and tools"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.5"])
      s.add_runtime_dependency(%q<bsearch>, [">= 1.5.0"])
      s.add_runtime_dependency(%q<andand>, [">= 1.3.1"])
      s.add_runtime_dependency(%q<obo>, [">= 0.1.0"])
      s.add_runtime_dependency(%q<builder>, ["~> 3.0.0"])
      s.add_runtime_dependency(%q<bio>, ["~> 1.4.2"])
      s.add_runtime_dependency(%q<trollop>, ["~> 1.16.2"])
      s.add_development_dependency(%q<fftw3>, ["~> 0.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
    else
      s.add_dependency(%q<nokogiri>, ["~> 1.5"])
      s.add_dependency(%q<bsearch>, [">= 1.5.0"])
      s.add_dependency(%q<andand>, [">= 1.3.1"])
      s.add_dependency(%q<obo>, [">= 0.1.0"])
      s.add_dependency(%q<builder>, ["~> 3.0.0"])
      s.add_dependency(%q<bio>, ["~> 1.4.2"])
      s.add_dependency(%q<trollop>, ["~> 1.16.2"])
      s.add_dependency(%q<fftw3>, ["~> 0.3"])
      s.add_dependency(%q<rspec>, ["~> 2.6"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    end
  else
    s.add_dependency(%q<nokogiri>, ["~> 1.5"])
    s.add_dependency(%q<bsearch>, [">= 1.5.0"])
    s.add_dependency(%q<andand>, [">= 1.3.1"])
    s.add_dependency(%q<obo>, [">= 0.1.0"])
    s.add_dependency(%q<builder>, ["~> 3.0.0"])
    s.add_dependency(%q<bio>, ["~> 1.4.2"])
    s.add_dependency(%q<trollop>, ["~> 1.16.2"])
    s.add_dependency(%q<fftw3>, ["~> 0.3"])
    s.add_dependency(%q<rspec>, ["~> 2.6"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
  end
end

