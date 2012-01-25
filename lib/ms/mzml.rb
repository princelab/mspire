require 'nokogiri'
require 'io/bookmark'
require 'zlib'
require 'ms/mzml/index_list'
require 'ms/spectrum'

module MS
  #     MS::Mzml.open("somefile.mzML") do |mzml|
  #       mzml.each do |spectrum|
  #         scan = spectrum.scan
  #         spectrum.mzs                  # array of m/zs
  #         spectrum.intensities          # array of intensities
  #         spectrum.peaks.each do |mz,intensity|
  #           puts "mz: #{mz} intensity: #{intensity}" 
  #         end
  #       end
  #     end
  class Mzml
    module Parser
      NOBLANKS = ::Nokogiri::XML::ParseOptions::DEFAULT_XML | ::Nokogiri::XML::ParseOptions::NOBLANKS
    end
    include Enumerable

    attr_accessor :filename
    attr_accessor :io
    attr_accessor :index_list
    attr_accessor :encoding

    # io must respond_to?(:size), giving the size of the io object in bytes
    # which allows seeking.  #get_index_list is called to get or create the
    # index list.
    def initialize(io)
      @io = io
      @encoding = @io.bookmark(true) {|io| io.readline.match(/encoding=["'](.*?)["']/)[1] }
      @index_list = get_index_list
    end

    class << self
      # read-only right now
      def open(filename, &block)
        File.open(filename) do |io|
          block.call(self.new(io))
        end
      end

      def foreach(filename, &block)
        open(filename) do |mzml|
          mzml.each(&block)
        end
      end

      # unpack binary data based on an accesions.  accessions must only
      # respond to :include?  So, hash keys, a set, or an array will all work.
      def unpack_binary(base64string, accessions)
        compressed =
          if accessions.include?('MS:1000574') then true # zlib compression
          elsif accessions.include?('MS:1000576') then false # no compression
          else raise 'no compression info: check your MS accession numbers'
          end
        precision_unpack = 
          if accessions.include?('MS:1000523') then 'E*'
          elsif accessions.include?('MS:1000521') then 'e*'
          else raise 'unrecognized precision: check your MS accession numbers'
          end
        data = base64string.unpack("m*").first
        unzipped = compressed ? Zlib::Inflate.inflate(data) : data
        unzipped.unpack(precision_unpack)
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

    def each_spectrum(&block)
      (0...@index_list[:spectrum].size).each do |int|
        block.call spectrum(int)
      end
    end

    # returns the Nokogiri::XML::Node object associated with each spectrum
    def each_spectrum_node(&block)
      @index_list[:spectrum].each do |start_byte|
        block.call spectrum_node_from_start_byte(start_byte)
      end
    end

    alias_method :each, :each_spectrum

    def spectrum_node_from_start_byte(start_byte)
      xml = get_xml_string(start_byte, :spectrum)
      doc = Nokogiri::XML.parse(xml, nil, @encoding, Parser::NOBLANKS)
      doc.root
    end

    # @param [Object] arg an index number (Integer) or id string (String)
    # @return [MS::Spectrum] a spectrum object
    def spectrum(arg)
      ################### trouble
      start_byte = index_list[0].start_byte(arg)
      data_arrays = spectrum_node_from_start_byte(start_byte).xpath('//binaryDataArray').map do |binary_data_array_n|
        accessions = binary_data_array_n.xpath('./cvParam').map {|node| node['accession'] }
        base64 = binary_data_array_n.xpath('./binary').text
        MS::Mzml.unpack_binary(base64, accessions)
      end
      MS::Spectrum.new(data_arrays)
    end

    # returns the number of spectra
    def size
      @index_list[:spectrum].size
    end

    alias_method :'[]', :spectrum

    # @param [Integer] scan_num the scan number 
    # @return [MS::Spectrum] a spectrum object, or nil if not found
    # @raise [ScanNumbersNotUnique] if scan numbers are not unique
    # @raise [ScanNumbersNotFound] if spectra exist but scan numbers were not
    #   found
    def spectrum_from_scan_num(scan_num)
      @scan_to_index ||= @index_list[0].create_scan_index
      raise ScanNumbersNotUnique if @scan_to_index == false
      raise ScanNumbersNotFound if @scan_to_index == nil
      spectrum(@scan_to_index[scan_num])
    end

    # @return [MS::Mzml::IndexList] or nil if there is no indexList in the
    # mzML
    def read_index_list
      if offset=MS::Mzml::Index.index_offset(@io)
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
    # @return [MS::Mzml::IndexList] 
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

    class ScanNumbersNotUnique < Exception
    end
    class ScanNumbersNotFound < Exception
    end
  end
end

