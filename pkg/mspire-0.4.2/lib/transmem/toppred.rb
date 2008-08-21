require 'transmem'
require 'xml_style_parser'

class TopPred ; end


class TopPred::Index < Hash
  include TransmemIndex

  # we need to match whatever function toppred uses to generate identifiers if
  # we want derivative processes to be fast and accurate
  def reference_to_key(reference)
    if reference
      ri = reference.index(' ')
      frst =
        if ri 
          reference[0...reference.index(' ')]
        else 
          reference
        end
      if frst
        frst.gsub(/[^0-9a-zA-Z]/,'_')
      else
        nil
      end
    else
      nil
    end
  end

  def initialize(file, kind=:default)
    case kind
    when :default
      TopPred.default_index(file, self)
    else
      abort "can't do #{kind}"
    end
  end

  # This class will probably change its interface some in the future
  # That's the web portal
  # http://bioweb.pasteur.fr/seqanal/interfaces/toppred.html
  # How to run:
  # uncheck 'Produce hydrophobicity graph image (-g)'
  # choose 'Xml' or 'New: new text' output
  # type in your email, then hit 'Run toppred'
end

class TopPred
  include TransmemIndex

  # returns the default index
  def self.default_index(file, index={})
    TopPred::Parser.new(TopPred::Parser.filetype(file)).file_to_index(file, index)
  end

end

module TopPred::Parser
  # returns :xml or :text
  def self.filetype(file)
    File.open(file) do |fh|
      case fh.gets
      when /<\?xml version.*>/
        :xml 
      when /Algorithm specific/
        :text
      else
        nil
      end
    end
  end

  # type = :xml or :text
  def self.new(parser_type=:xml)
    klass = 
      case parser_type
      when :xml
        TopPred::Parser_XML
      when :text
        TopPred::Parser_Text
      else
        abort "don't recognize parser type: #{parser_type}"
      end
    klass.new
  end

  def file_to_index(file, index={})
    File.open(file) {|fh| to_index(fh, index) }
  end

  # where each segment = [prob, first, last] and aaseq is a string each
  # segment may also be a hash => first, last, probability (adding key
  # 'aaseq') 
  # first/last '1' indexed returns segments where each is [prob,
  # first, last, aaseq] or hash (above)
  def add_sequences_to_segments(segments, aaseq)
    if segments.first.is_a? Array
      segments.each do |seg|
        first_index = seg[1] - 1
        length = (seg[2] - seg[1]) + 1
        seg.push( aaseq[first_index, length] )
      end
    else
      segments.each do |seg|
        first_index = seg[:start] - 1
        length = (seg[:stop] - seg[:start]) + 1
        seg[:aaseq] = ( aaseq[first_index, length] )
      end
    end
    segments
  end



end

module TopPred::Parser_XML
  include TopPred::Parser
  include XMLStyleParser

  def self.new(meth=:to_index)
    parser = XMLStyleParser.choose_parser(self, meth).new
    @method = meth
    parser
  end

  def parse(file)
    send(@method, file)
  end
end

class TopPred::Parser_XML::DOM
  include TopPred::Parser_XML
  include XMLStyleParser

=begin
  YAL010C: 
  num_putative_transmembrane_segments: 1
  aaseq: MLPYMDQVLRAFYQSTHWSTQNSYEDITATSRTLLDFRIPSAIHLQISNKSTPNTFNSLDFSTRSRINGSLSYLYSDAQQLEKFMRNSTDIPLQDATETYRQLQPNLNFSVSSANTLSSDNTTVDNDKKLLHDSKFVKKSLYYGRMYYPSSDLEAMIIKRLSPQTQFMLKGVSSFKESLNVLTCYFQRDSHRNLQEWIFSTSDLLCGYRVLHNFLTTPSKFNTSLYNNSSLSLGAEFWLGLVSLSPGCSTTLRYYTHSTNTGRPLTLTLSWQPLFGHISSTYSAKTGTNSTFCAKYDFNLYSIESNLSFGCEFWQKKHHLLETNKNNNDKLEPISDELVDINPNSRATKLLHENVPDLNSAVNDIPSTLDIPVHKQKLLNDLTYAFSSSLRKIDEERSTIEKFDNKINSSIFTSVWKLSTSLRDKTLKLLWEGKWRGFLISAGTELVFTRGFQESLSDDEKNDNAISISATDTENGNIPVFPAKFGIQFQYST
  best_structure_probability: 1.0
  transmembrane_segments: 
  - aaseq: SLGAEFWLGLVSLSPGCSTTL
    stop: 252
    start: 232
    probability: 1.0
  num_certain_transmembrane_segments: 1
  num_found: 2
=end

  # should return a index
  def to_index(io, index = {})
    get_root_node_from_io(io) do |toppreds_n|

      abort if toppreds_n.name != 'toppreds'
      toppreds_n.find('child::toppred').each do |toppred_n|
        att_hash = {}
        sequence_n = toppred_n.find_first('child::sequence')
        index[sequence_n['id']] = att_hash
        att_hash[:aaseq] = sequence_n.content.gsub(/[\s\n]/,'')
        abort if att_hash[:aaseq].size != sequence_n['size'].to_i
        tmsummary_n = sequence_n.find_first('following-sibling::tmsummary')

        num_found = tmsummary_n['segments'].to_i
        att_hash[:num_found] = num_found
        if num_found > 0

          num_certain_transmembrane_segments = 0
          num_putative_transmembrane_segments = 0
          tmsummary_n.find('child::segment').each do |segment_n|
            abort if segment_n.name != 'segment'
            case segment_n['type']
            when 'certain'
              num_certain_transmembrane_segments += 1
            else # putative
              num_putative_transmembrane_segments += 1
            end
          end
          att_hash[:num_putative_transmembrane_segments] = num_putative_transmembrane_segments
          att_hash[:num_certain_transmembrane_segments] = num_certain_transmembrane_segments

          topologies_n = tmsummary_n.next
          abort if topologies_n.name != 'topologies'
          # get the top probability topology:
          top_prob_topology_n = topologies_n.find('child::topology').to_a.max {|a,b| a['prob'].to_f <=> b['prob'].to_f }
          tmsegments = []
          top_prob_topology_n.find('child::tmsegment').each do |tmsegment_n|
            tmhash = {}
            tmhash[:start] = tmsegment_n['start'].to_i
            tmhash[:stop] = tmsegment_n['stop'].to_i
            ## WARNING! it appears the probability is broken on xml output!!
            tmhash[:probability] = tmsegment_n['prob'].to_f
            tmsegments << tmhash
          end
          add_sequences_to_segments(tmsegments, att_hash[:aaseq])
          att_hash[:transmembrane_segments] = tmsegments
        end
      end
    end
    index
  end

end

class TopPred::Parser_Text
  include TopPred::Parser


  # returns a hash structure in this form: {identifier => {aaseq => String,
  # num_found: Int, num_certain_transmembrane_segments => Int,
  # num_putative_transmembrane_segments => Int, best_structure_probability =>
  # Float, transmembrane_segments => [probability => Float, start => Int, stop
  # => Int, aaseq => String] } }
  def to_index(io, index={})
    current_record = nil

    io.each do |line|
      if line =~ /^Sequence : (.*?) +\(/
        current_identifier = $1.dup
        index[current_identifier] = {}
        current_record = index[current_identifier]
        current_record[:aaseq] = read_aaseq(io)
        read_segment_summary(io, current_record)
      elsif line =~ /^HEADER\s+START\s+STOP/
        top_struc = top_structure( read_structures(io) )
        current_record[:best_structure_probability] = top_struc[:probability]
        current_record[:transmembrane_segments] = top_struc[:tm]
        add_sequences_to_segments(current_record[:transmembrane_segments], current_record[:aaseq])
        segment_arrays_to_hashes(current_record[:transmembrane_segments])
      end
    end
    index
  end

  private 

  # returns a list of all structures given a filehandle starting just after
  # the first "HEADER START STOP ..." line
  def read_structures(fh)
    structures = []
    loop do
      structures.push( read_structure(fh) )
      break if fh.eof?
      line = fh.readline
      unless line =~ /^HEADER\s+START\s+STOP/
        break
      end
    end
    structures
  end

  # returns a hash with key :probability and key :tm contains an array of
  # arrays: [prob(Float), start(Int), stop(Int)]
  def read_structure(fh)
    structure = {}
    # READ the first line
    line = fh.readline
    structure[:probability] = line.split(/\s+/)[2].to_f
    structure[:tm] = read_segments(fh)
    structure
  end

  # returns an array of arrays of transmembrane segments: [prob(Float),
  # start(Int), stop(Int)]
  # returns after seeing '//'
  def read_segments(fh)
    segments = []
    st = Regexp.escape('//') ; end_regex = /#{st}/
    fh.each do |line|
      if line =~ /^TRANSMEM/
        (header, start, stop, len, prob) = line.split(/\s+/)[0,5]
        segments << [prob.to_f, start.to_i, stop.to_i]
      elsif line =~ end_regex
        break
      end
    end
    segments
  end

  # returns the top probability structure (first on tie)
  def top_structure(list)
    top_prob = list.first[:probability]
    top_struc = list.first
    list.each do |st|
      if st[:probability] > top_prob 
        top_struc = st
        top_prob = st[:probability]
      end
    end
    top_struc
  end

  def read_aaseq(fh)
    aaseq = '' 
    fh.each do |line|
      line.chomp!
      unless line =~ /[\w\*]/
        break
      end
      aaseq << line 
    end
    aaseq
  end

  def segment_arrays_to_hashes(list)
    list.map! do |ar|
      { :probability => ar[0],
      :start => ar[1],
      :stop => ar[2],
      :aaseq => ar[3],
      }
    end
  end

  # returns [certain, putative]
  # expects first line to be a tm segment
  def num_certain_putative(fh)
    certain = 0
    putative = 0
    fh.each do |line|
      certainty = line.chomp.split(/\s+/).last
      if !certainty
        break
      else
        certain += 1 if certainty == 'Certain'
        putative += 1 if certainty == 'Putative'
      end
    end
    [certain, putative]
  end

  def read_segment_summary(fh, rec)
    fh.each do |line|
      if line =~ /Found: (.*?) segments/
        rec[:num_found] = $1.to_i
        break if rec[:num_found] == 0
      elsif line =~ /Helix\s+Begin/
        (cert, putat) = num_certain_putative(fh) 
        rec[:num_certain_transmembrane_segments] = cert
        rec[:num_putative_transmembrane_segments] = putat
        break
      end
    end
  end
end

class TopPred::Parser_XML::LibXML < TopPred::Parser_XML::DOM
  def get_root_node_from_io(io, &block)
    # turn off warnings because this doesn't seem to work:
    # XML::Parser.default_load_external_dtd = false
    # (There is a warning about not finding DTD)
    xml_parser_warnings = XML::Parser.default_warnings
    XML::Parser.default_warnings = false
    doc = XML::Parser.io(io).parse
    root = doc.root
    block.call(root)
    # reset the warning level of XML::Parser:
    XML::Parser.default_warnings = xml_parser_warnings
  end
end

class TopPred::Parser_XML::AXML < TopPred::Parser_XML::DOM
  def get_root_node_from_io(io, &block)
    root = ::AXML.parse(io)
    block.call(root)
  end
end

