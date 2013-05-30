require 'nokogiri'
require 'mspire/ident'
require 'mspire/ident/pepxml/msms_pipeline_analysis'

require 'ostruct'

module Mspire ; module Ident ; end ; end

class Numeric
  # returns a string with a + or - on the front
  def to_plus_minus_string
    if self >= 0
      '+' << self.to_s
    else
      self.to_s
    end
  end
end

class Mspire::Ident::Pepxml
  XML_STYLESHEET_LOCATION = '/tools/bin/TPP/tpp/schema/pepXML_std.xsl'
  DEFAULT_PEPXML_VERSION = MsmsPipelineAnalysis::PEPXML_VERSION
  XML_ENCODING = 'UTF-8'

  attr_accessor :msms_pipeline_analysis

  # returns an array of Mspire::Ident::Pepxml::SearchHit::Simple structs will
  # only process last result if duplicate search scores are included.  Score
  # keys returned as symbols and values cast as Floats while analysis results
  # are all returned as strings.
  def self.simple_search_hits(file, &block)
    hit_values = File.open(file) do |io|
      doc = Nokogiri::XML.parse(io, nil, nil, Nokogiri::XML::ParseOptions::DEFAULT_XML | Nokogiri::XML::ParseOptions::NOBLANKS | Nokogiri::XML::ParseOptions::STRICT)
      # we can work with namespaces, or just remove them ...
      doc.remove_namespaces!
      root = doc.root
      search_hits = root.xpath('//search_hit')
      search_hits.each_with_index.map do |search_hit,i| 
        aaseq = search_hit['peptide']
        charge = search_hit.parent.parent['assumed_charge'].to_i
        nodes_by_name = search_hit.children.group_by(&:name)
        search_scores = {}
        nodes_by_name['search_score'].each do |node|
          search_scores[node['name'].to_sym] = node['value'].to_f
        end
        analysis_results = {}
        nodes_by_name['analysis_result'].each do |node|
          analysis_results[node['analysis']] = node.children.map do |atnode| 
            atnode.attribute_nodes.each_with_object({}) do |attribute, hash|
              hash[attribute.name] = attribute.value
            end
          end
        end
        hit = Mspire::Ident::Pepxml::SearchHit::Simple.new("hit_#{i}", Mspire::Ident::Search.new(file.chomp(File.extname(file))), aaseq, charge, search_scores, analysis_results)
        if block
          block.call(search_hit_n.parent.parent)
        end
        hit
      end
    end
  end

  def pepxml_version
    msms_pipeline_analysis.pepxml_version
  end

  # returns an array of spectrum queries
  def spectrum_queries
    msms_pipeline_analysis.msms_run_summary.spectrum_queries
  end

  # yields a new Msms_Pipeline_Analysis object if given a block 
  def initialize(&block)
    block.call(@msms_pipeline_analysis=MsmsPipelineAnalysis.new) if block
  end

  # takes an xml document object and sets it with the xml stylesheet
  def add_stylesheet(doc, location)
    xml_stylesheet = Nokogiri::XML::ProcessingInstruction.new(doc, "xml-stylesheet", %Q{type="text/xsl" href="#{location}"})
    doc.root.add_previous_sibling  xml_stylesheet
    doc
  end

  # if no options are given, an xml string is returned.  If either :outdir or
  # :outfile is given, the xml is written to file and the output filename is returned.
  # A single string argument will be interpreted as :outfile if it ends in
  # '.xml' and the :outdir otherwise.  In this case, update_summary_xml is still true
  #
  # options:
  #     
  #     arg                    default
  #     :outdir             => nil   write to disk using this outdir with summary_xml basename
  #     :outfile            => nil   write to this filename (overrides outdir)
  #     :update_summary_xml => true  update summary_xml attribute to point to the output file true/false
  #
  # set outdir to
  # File.dirname(pepxml_obj.msms_pipeline_analysis.msms_run_summary.base_name)
  # to write to the same directory as the input search file.
  def to_xml(opts={})
    opts ||= {}
    if opts.is_a?(String) 
      opts = ( opts.match(/\.xml$/) ?  {:outfile => opts} : {:outdir => opts } )
    end
    opt = {:update_summary_xml => true, :outdir => nil, :outfile => nil}.merge(opts)

    if opt[:outfile]
      outfile = opt[:outfile]
    elsif opt[:outdir]
      outfile = File.join(opt[:outdir], msms_pipeline_analysis.summary_xml.split(/[\/\\]/).last)
    end
    self.msms_pipeline_analysis.summary_xml = File.expand_path(outfile) if (opt[:update_summary_xml] && outfile)

    builder = Nokogiri::XML::Builder.new(:encoding => XML_ENCODING)
    msms_pipeline_analysis.to_xml(builder)
    add_stylesheet(builder.doc, Mspire::Ident::Pepxml::XML_STYLESHEET_LOCATION)
    string = builder.doc.to_xml

    if outfile 
      File.open(outfile,'w') {|out| out.print(string) }
      outfile
    else
      string
    end
  end
end


