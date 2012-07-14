
module Mspire
  class Mzml
    # A simple array of indices but #[] has been overloaded to find an index
    # by name
    #
    #     index_list[0]  # the first index
    #     index_list.map(&:name) # -> [:spectrum, :chromatogram] 
    #     index_list[:spectrum]  # the spectrum index
    #     index_list[:chromatogram]  # the chromatogram index
    class IndexList < Array
      alias_method :old_bracket_slice, :'[]'

      # @param [Object] an Integer (index number) or a Symbol (:spectrum or
      #   :chromatogram)
      # @return [Mspire::Mzml::Index] an index object
      def [](int_or_symbol)
        if int_or_symbol.is_a?(Integer)
          old_bracket_slice(int_or_symbol)
        else
          self.find {|index| index.name == int_or_symbol }
        end
      end

      def keys
        self.map(&:name)
      end

      # returns each name and associated index object
      def each_pair(&block)
        block or return enum_for __method__
        each {|index| block.call([index.name, index]) }
      end

      class << self

        # either reads in from file or creates an IndexList
        def from_io(io)
          read_index_list(io) || create_index_list(io)
        end

        # returns an Integer or nil if not found
        # does a single jump backwards from the tail of the file looking for
        # an xml element based on tag.  If it is not found, returns nil
        def index_offset(io, tag='indexListOffset', bytes_backwards=200)
          tag_re = %r{<#{tag}>([\-\d]+)</#{tag}>}
            io.pos = (io.size - 1) - bytes_backwards
          md = io.readlines("\n").map {|line| line.match(tag_re) }.compact.shift
          md[1].to_i if md
        end

        # @return [Mspire::Mzml::IndexList] or nil if there is no indexList in the
        # mzML
        def read_index_list(io)
          if (offset = index_offset(io))
            io.seek(offset)
            xml = Nokogiri::XML.parse(io.read, nil, @encoding, Parser::NOBLANKS)
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
          indices_hash = io.bookmark(true) do |inner_io|   # sets to beginning of file
            indices = {:spectrum => {}, :chromatogram => {}}
            byte_total = 0
            io.each do |line|
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

      end
    end
  end

end
