require 'mspire'
require 'builder'
require 'nokogiri'
require 'io/bookmark'
require 'zlib'
require 'mspire/mzml/index_list'
require 'mspire/mzml/spectrum'
require 'mspire/mzml/chromatogram'
require 'mspire/mzml/file_description'
require 'mspire/mzml/software'
require 'mspire/mzml/scan_list'
require 'mspire/mzml/selected_ion'
require 'mspire/mzml/scan'
require 'mspire/mzml/scan_settings'
require 'mspire/mzml/processing_method'
require 'mspire/mzml/run'
require 'mspire/mzml/spectrum_list'
require 'mspire/mzml/chromatogram_list'
require 'mspire/mzml/instrument_configuration'
require 'mspire/mzml/data_processing'
require 'mspire/mzml/referenceable_param_group'
require 'mspire/mzml/cv'
require 'mspire/mzml/sample'

module Mspire
  # Reading an mzml file:
  #
  #     Mspire::Mzml.open("somefile.mzML") do |mzml|
  #       mzml.each do |spectrum|
  #         scan = spectrum.scan
  #         spectrum.mzs                  # array of m/zs
  #         spectrum.intensities          # array of intensities
  #         spectrum.peaks do |mz,intensity|
  #           puts "mz: #{mz} intensity: #{intensity}" 
  #         end
  #       end
  #     end
  #
  # Note that the mzml object supports random spectrum access (even if the
  # mzml was not indexed):
  #
  #     mzml[22]  # retrieve spectrum at index 22
  #
  # Writing an mzml file from scratch:
  #
  #     spec1 = Mspire::Mzml::Spectrum.new('scan=1', params: ['MS:1000127', ['MS:1000511', 1]]) do |spec|
  #       spec.data_arrays = [[1,2,3], [4,5,6]]
  #       spec.scan_list = Mspire::Mzml::ScanList.new do |sl|
  #         scan = Mspire::Mzml::Scan.new do |scan|
  #           # retention time of 40 seconds
  #           scan.describe! ['MS:1000016', 40.0, 'UO:0000010']
  #         end
  #         sl << scan
  #       end
  #     end
  #
  #     mzml = Mspire::Mzml.new do |mzml|
  #       mzml.id = 'the_little_example'
  #       mzml.cvs = Mspire::Mzml::CV::DEFAULT_CVS
  #       mzml.file_description = Mspire::Mzml::FileDescription.new  do |fd|
  #         fd.file_content = Mspire::Mzml::FileContent.new
  #         fd.source_files << Mspire::Mzml::SourceFile.new
  #       end
  #       default_instrument_config = Mspire::Mzml::InstrumentConfiguration.new("IC",[], params: ['MS:1000031'])
  #       mzml.instrument_configurations << default_instrument_config
  #       software = Mspire::Mzml::Software.new
  #       mzml.software_list << software
  #       default_data_processing = Mspire::Mzml::DataProcessing.new("did_nothing")
  #       mzml.data_processing_list << default_data_processing
  #       mzml.run = Mspire::Mzml::Run.new("little_run", default_instrument_config) do |run|
  #         spectrum_list = Mspire::Mzml::SpectrumList.new(default_data_processing)
  #         spectrum_list.push(spec1)
  #         run.spectrum_list = spectrum_list
  #       end
  #     end
  class Mzml

    module Default
      NAMESPACE = {
        :xmlns => "http://psi.hupo.org/ms/mzml",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", 
        "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", 
      }

      VERSION = '1.1.0'
    end

    ###############################################
    # ATTRIBUTES
    ###############################################

    # (optional) an id for accessing from external files
    attr_accessor :id
   
    # (required) the Mzml document version
    attr_accessor :version

    # (optional) e.g. a PRIDE accession number
    attr_accessor :accession

    ###############################################
    # SUBELEMENTS
    ###############################################

    # (required) an array of Mspire::Mzml::CV objects
    attr_accessor :cvs

    # (required) an Mspire::Mzml::FileDescription
    attr_accessor :file_description

    # (optional) an array of CV::ReferenceableParamGroup objects
    attr_accessor :referenceable_param_groups

    # (optional) an array of Mspire::Mzml::Sample objects
    attr_accessor :samples

    # (required) an array of Mspire::Mzml::Software objects 
    attr_accessor :software_list

    # (optional) an array of Mspire::Mzml::ScanSettings objects
    attr_accessor :scan_settings_list

    # (required) an array of Mspire::Mzml::InstrumentConfiguration objects
    attr_accessor :instrument_configurations

    # (required) an array of Mspire::Mzml::DataProcessing objects
    attr_accessor :data_processing_list

    # (required) an Mspire::Mzml::Run object
    attr_accessor :run

    module Parser
      NOBLANKS = ::Nokogiri::XML::ParseOptions::DEFAULT_XML | ::Nokogiri::XML::ParseOptions::NOBLANKS
    end
    include Enumerable

    attr_accessor :io
    attr_accessor :index_list
    attr_accessor :encoding

    # arg must be an IO object for automatic index and header parsing to
    # occur.  If arg is a hash, then attributes are set.  In addition (or
    # alternatively) a block called that yields self to setup the object.
    #
    # io must respond_to?(:size), giving the size of the io object in bytes
    # which allows seeking.  get_index_list is called to get or create the
    # index list.
    def initialize(arg=nil, &block)
      %w(cvs software_list instrument_configurations data_processing_list).each {|guy| self.send( guy + '=', [] ) }

      case arg
      when IO
        @io = arg
        begin
          @encoding = @io.bookmark(true) {|io| io.readline.match(/encoding=["'](.*?)["']/)[1] }
        rescue EOFError
          raise RuntimeError, "no encoding present in XML!  (Is this even an xml file?)"
        end
        @index_list = get_index_list
        read_header!
      when Hash
        arg.each {|k,v| self.send("#{k}=", v) }
      end
      if block
        block.call(self)
      end
    end

    def read_header!
      @io.rewind
      chunk_size = 2**12
      loc = 0
      string = ''
      while chunk = @io.read(chunk_size)
        string << chunk
        start_looking = ((loc-20) < 0) ? 0 : (loc-20)
        break if string[start_looking..-1] =~ /<(spectrum|chromatogram)/
        loc += chunk_size
      end
      doc = Nokogiri::XML.parse(string, nil, @encoding, Parser::NOBLANKS)
      mzml_n = doc.root
      if mzml_n.name == 'indexedmzML'
        mzml_n = mzml_n.child
      end
      cv_list_n = mzml_n.child
      file_description_n = cv_list_n.next
      self.cvs = cv_list_n.children.map do |cv_n|
        Mspire::Mzml::CV.from_xml(cv_n)
      end
      self.file_description = Mspire::Mzml::FileDescription.from_xml(file_description_n)
      next_n = file_description_n.next
      loop do
        case next_n.name
        when 'referenceableParamGroupList'
          # get a hash ready
        when 'sampleList'
          # set objects
        when 'softwareList'  # required
          # set objects
        when 'instrumentConfigurationList'
          # set objects
        when 'dataProcessingList'
          # set objects
        when 'run'
          # get defaults ready
          break
        end
        next_n = next_n.next
      end
    end

    class << self

      # read-only right now
      def open(filename, &block)
        File.open(filename) do |io|
          block.call(self.new(io))
        end
      end

      def foreach(filename, &block)
        block or return enum_for(__method__, filename)
        open(filename) do |mzml|
          mzml.each(&block)
        end
      end
    end

    # name can be :spectrum or :chromatogram
    def get_xml_string(start_byte, name=:spectrum)
      io.seek(start_byte)
      data = []
      regexp = %r{</#{name}>}
      io.each_line do |line|
        data << line 
        #unless (line.index('<binary') && line[-12..-1].include?('</binary>'))
          break if regexp.match(line)
        #end
      end
      data.join
    end

    def each_chromatogram(&block)
      block or return enum_for(__method__)
      (0...num_chromatograms).each do |int|
        block.call(chromatogram(int))
      end
    end

    def each_spectrum(&block)
      block or return enum_for(__method__)
      (0...self.size).each do |int|
        block.call(spectrum(int))
      end
      #block_given? or return enum_for(__method__)
      #(0...@index_list[:spectrum].size).each do |int|
      #  yield spectrum(int)
      #end
    end

    # returns the Nokogiri::XML::Node object associated with each spectrum
    def each_spectrum_node(&block)
      @index_list[:spectrum].each do |start_byte|
        block.call spectrum_node_from_start_byte(start_byte)
      end
    end

    alias_method :each, :each_spectrum

    # returns the nokogiri xml node for the spectrum at that index
    def spectrum_node(index)
      spectrum_node_from_start_byte(@index_list[:spectrum][index])
    end

    def spectrum_node_from_start_byte(start_byte)
      xml = get_xml_string(start_byte, :spectrum)
      doc = Nokogiri::XML.parse(xml, nil, @encoding, Parser::NOBLANKS)
      doc.root
    end

    def chromatogram_node_from_start_byte(start_byte)
      xml = get_xml_string(start_byte, :chromatogram)
      doc = Nokogiri::XML.parse(xml, nil, @encoding, Parser::NOBLANKS)
      doc.root
    end

    # @param [Object] arg an index number (Integer) or id string (String)
    # @return [Mspire::Mzml::Spectrum] a spectrum object
    def spectrum(arg)
      start_byte = index_list[0].start_byte(arg)
      spec_n = spectrum_node_from_start_byte(start_byte)
      Mspire::Mzml::Spectrum.from_xml(spec_n)
    end

    # @param [Object] arg an index number (Integer) or id string (String)
    # @return [Mspire::Mzml::Chromatogram] a spectrum object
    def chromatogram(arg)
      start_byte = index_list[:chromatogram].start_byte(arg)
      chrom_n = chromatogram_node_from_start_byte(start_byte)
      Mspire::Mzml::Chromatogram.from_xml(chrom_n)
    end

    def num_chromatograms
      @index_list[:chromatogram].size
    end

    # returns the number of spectra
    def size
      @index_list[:spectrum].size
    end

    alias_method :'[]', :spectrum

    # @param [Integer] scan_num the scan number 
    # @return [Mspire::Spectrum] a spectrum object, or nil if not found
    # @raise [ScanNumbersNotUnique] if scan numbers are not unique
    # @raise [ScanNumbersNotFound] if spectra exist but scan numbers were not
    #   found
    def spectrum_from_scan_num(scan_num)
      @scan_to_index ||= @index_list[0].create_scan_index
      raise ScanNumbersNotUnique if @scan_to_index == false
      raise ScanNumbersNotFound if @scan_to_index == nil
      spectrum(@scan_to_index[scan_num])
    end

    # @return [Mspire::Mzml::IndexList] or nil if there is no indexList in the
    # mzML
    def read_index_list
      if offset=Mspire::Mzml::Index.index_offset(@io)
        @io.seek(offset)
        xml = Nokogiri::XML.parse(@io.read, nil, @encoding, Parser::NOBLANKS)
        index_list = xml.root
        num_indices = index_list['count'].to_i
        array = index_list.children.map do |index_n|
          #index = Index.new(index_n['name'])
          index = Index.new
          index.name = index_n['name'].to_sym
          ids = []
          index_n.children.map do |offset_n| 
            index << offset_n.text.to_i 
            ids << offset_n['idRef']
          end
          index.ids = ids
          index
        end
        IndexList.new(array)
      end
    end
    # Reads through and captures start bytes
    # @return [Mspire::Mzml::IndexList] 
    def create_index_list
      indices_hash = @io.bookmark(true) do |inner_io|   # sets to beginning of file
        indices = {:spectrum => {}, :chromatogram => {}}
        byte_total = 0
        @io.each do |line|
          if md=%r{<(spectrum|chromatogram).*?id=['"](.*?)['"][ >]}.match(line)
            indices[md[1].to_sym][md[2]] = byte_total + md.pre_match.bytesize
          end
          byte_total += line.bytesize
        end
        indices
      end

      indices = indices_hash.map do |sym, hash|
        indices = Index.new ; ids = []
        hash.each {|id, startbyte| ids << id ; indices << startbyte }
        indices.ids = ids ; indices.name = sym
        indices
      end
      IndexList.new(indices)
    end

    # reads or creates an index list
    # @return [Array] an array of indices
    def get_index_list
      read_index_list || create_index_list
    end

    # Because mzml files are often very large, we try to avoid storing the
    # entire object tree in memory before writing.
    # 
    # takes a filename and uses builder to write to it
    # if no filename is given, returns a string
    def to_xml(filename=nil)
      # TODO: support indexed mzml files
      io = filename ? File.open(filename, 'w') : StringIO.new
      xml = Builder::XmlMarkup.new(:target => io, :indent => 2)
      xml.instruct!

      mzml_atts = Default::NAMESPACE.dup
      mzml_atts[:version] = @version || Default::VERSION
      mzml_atts[:accession] = @accession if @accession
      mzml_atts[:id] = @id if @id

      xml.mzML(mzml_atts) do |mzml_n|
        # the 'if' statements capture whether or not the list is required or not
        raise "#{self.class}#cvs must have > 0 Mspire::Mzml::CV objects" unless @cvs.size > 0 
        Mspire::Mzml::CV.list_xml(@cvs, mzml_n)
        @file_description.to_xml(mzml_n)
        if @referenceable_param_groups
          Mspire::Mzml::ReferenceableParamGroup.list_xml(@referenceable_param_groups, mzml_n)
        end
        if @samples
          Mspire::Mzml::Sample.list_xml(@samples, mzml_n)
        end
        Mspire::Mzml::Software.list_xml(@software_list, mzml_n)
        if @scan_settings_list && @scan_settings_list.size > 0
          Mspire::Mzml::ScanSettings.list_xml(@scan_settings_list, mzml_n)
        end
        icl = Mspire::Mzml::InstrumentConfiguration.list_xml(@instrument_configurations, mzml_n)
        Mspire::Mzml::DataProcessing.list_xml(@data_processing_list, mzml_n)
        @run.to_xml(mzml_n)
      end
      
      if filename
        io.close 
        self
      else
        io.string
      end
    end

    class ScanNumbersNotUnique < Exception
    end
    class ScanNumbersNotFound < Exception
    end
  end
end

