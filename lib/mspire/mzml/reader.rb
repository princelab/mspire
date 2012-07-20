require 'io/bookmark'

%w(
  parser

  index_list

  cv
  referenceable_param_group
  file_description

  sample
  software
  instrument_configuration
  data_processing
  run
).each do |file|
  require "mspire/mzml/#{file}"
end

module Mspire
  class Mzml
  end
end

module Mspire::Mzml::Reader

  def set_from_xml_io!(xml_io)
    @io = xml_io
    begin
      @encoding = @io.bookmark(true) {|io| io.readline.match(/encoding=["'](.*?)["']/)[1] }
    rescue EOFError
      raise RuntimeError, "no encoding present in XML!  (Is this even an xml file?)"
    end
    @index_list = Mspire::Mzml::IndexList.from_io(@io)
    read_header!( get_default_data_processing_ids(@io, @index_list) )
  end

  # returns a hash keyed by :spectrum or :chromatogram that gives the id
  # (aka ref) as a string.
  def get_default_data_processing_ids(io, index_list, lookback=200)
    hash = {}
    index_list.each_pair do |name, index|
      io.bookmark do |io|
        io.pos = index[0] - lookback 
        hash[name] = io.read(lookback)[/<#{name}List.*defaultDataProcessingRef=['"](.*?)['"]/m, 1]
      end
    end
    hash
  end

  # saves ~ 3 seconds when reading a 83M mzML file to scrape off the
  # header string (even though we're just handing in an IO object to
  # Nokogiri::XML::Document.parse and we are very careful to not parse too
  # far).
  def get_header_string(io)
    chunk_size = 2**12
    loc = 0
    string = ''
    while chunk = @io.read(chunk_size)
      string << chunk
      start_looking = ((loc-20) < 0) ? 0 : (loc-20)
      break if string[start_looking..-1] =~ /<(spectrum|chromatogram)/
        loc += chunk_size
    end
    string
  end

  # list_type_to_default_data_processing_id is a hash keyed by :spectrum or
  # :chromatogram that gives the default data_processing_object for the
  # SpectrumList and/or the ChromatogramList.  This information is not
  # obtainable from the header string, so must be pre-obtained.
  def read_header!(list_type_to_default_data_processing_id)
    @io.rewind

    string = get_header_string(@io)
    doc = Nokogiri::XML.parse(string, nil, @encoding, Mspire::Mzml::Parser::NOBLANKS)

    doc.remove_namespaces!
    mzml_n = doc.root
    if mzml_n.name == 'indexedmzML'
      mzml_n = mzml_n.child
    end
    cv_list_n = mzml_n.child
    self.cvs = cv_list_n.children.map do |cv_n|
      Mspire::Mzml::CV.from_xml(cv_n)
    end

    # get the file description node but deal with it after getting ref_hash
    file_description_n = cv_list_n.next

    xml_n = file_description_n.next

    # a hash of referenceable_param_groups indexed by id
    link = {}

    if xml_n.name == 'referenceableParamGroupList'
      self.referenceable_param_groups = xml_n.children.map do |rpg_n|
        Mspire::Mzml::ReferenceableParamGroup.from_xml(rpg_n) # <- no ref_hash (not made yet)
      end
      link[:ref_hash] = self.referenceable_param_groups.index_by(&:id)
      xml_n = xml_n.next
    end

    # now we can set the file description because we have the ref_hash
    self.file_description = Mspire::Mzml::FileDescription.from_xml(file_description_n, link)
    link[:source_file_hash] = self.file_description.source_files.index_by(&:id)


    loop do
      case xml_n.name
      when 'sampleList'
        self.samples = xml_n.children.map do |sample_n|
          Mspire::Mzml::Sample.from_xml(sample_n, link)
        end
        link[:sample_hash] = self.samples.index_by(&:id)
      when 'softwareList'  # required
        self.software_list = xml_n.children.map do |software_n|
          Mspire::Mzml::Software.from_xml(software_n, link)
        end
        link[:software_hash] = self.software_list.index_by(&:id)
      when 'instrumentConfigurationList'
        self.instrument_configurations = xml_n.children.map do |inst_config_n|
          Mspire::Mzml::InstrumentConfiguration.from_xml(inst_config_n, link)
        end
        link[:instrument_configuration_hash] = self.instrument_configurations.index_by(&:id)
      when 'dataProcessingList'
        self.data_processing_list = xml_n.children.map do |data_processing_n|
          Mspire::Mzml::DataProcessing.from_xml(data_processing_n, link)
        end
        link[:data_processing_hash] = self.data_processing_list.index_by(&:id)
      when 'run'
        link[:index_list] = @index_list
        list_type_to_default_data_processing_id.each do |type, process_id|
          link["#{type}_default_data_processing".to_sym] = link[:data_processing_hash][process_id]
        end
        self.run = Mspire::Mzml::Run.from_xml(@io, xml_n, link)
        break
      end
      xml_n = xml_n.next
    end
  end
end

module Mspire
  class Mzml
    include Reader
  end
end



