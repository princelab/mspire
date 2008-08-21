require 'transmem'

class Phobius ; end

# This class will probably change its interface some in the future
# That's the web portal
# http://phobius.cgb.ki.se/
# How to run:
# Select output format as 'Short'
# then hit 'Submit Query'

# note: to implement some of the TransmemIndex features, the update_aaseq
# method must be called!
class Phobius::Index < Hash
  include TransmemIndex

  # will update_aaseq if given a fasta_obj
  def initialize(file, fasta_obj = nil )
    Phobius.default_index(file, self)
    if fasta_obj
      update_aaseq(fasta_obj)  
    end
  end

  # we need to match whatever function toppred uses to generate identifiers if
  # we want derivative processes to be fast and accurate
  def reference_to_key(reference)
    if reference
      if reference.size > 0
        index = reference.index(' ')
        string = 
          if index
            reference[0...index]
          else
            reference
          end
        string.gsub('"','')
      else
        ''
      end
    else
      nil
    end
  end

  # adds an :aaseq key to each hash (necessary for avg_overlap method)
  # these are shallow references to the aaseq in the fasta obj
  def update_aaseq(fasta)
    fasta.each do |prot|
      self[reference_to_key(prot.reference)][:aaseq] = prot.aaseq
    end
  end

end

class Phobius
  include TransmemIndex

  # returns the default index
  def self.default_index(file, index={})
    parser = Phobius::Parser.new(:short)
    parser.file_to_index(file, index)
  end

end

module Phobius::Parser

  def self.new(parser_type=:short)
    klass = 
      case parser_type
      when :short
        Phobius::ParserShort
      else
        raise ArgumentError, "don't recognize parser type: #{parser_type}"
      end
    klass.new
  end

  def file_to_index(file, index={})
    File.open(file) {|fh| to_index(fh, index) }
  end

end


class Phobius::ParserShort
  include Phobius::Parser

  # takes a phobius prediction string (e.g., i12-31o37-56i63-84o96-116i123-143o149-169i)
  # and returns an array of hashes with the keys :start and :stop
  def prediction_to_array(string)
    segments = []
    string.scan(/[io](\d+)-(\d+)/) do |m1, m2|
      segments << { :start => m1.to_i, :stop => m2.to_i }
    end
    segments
  end

  # returns a hash structure in this form: { identifier => {
  # :num_certain_transmembrane_segments => Int,
  # :transmembrane_segments => [:start => Int, :stop
  # => Int] }
  # can parse io even if there is no header to key in on.
  def to_index(io, index={})
    init_pos = io.pos
    cnt = 0
    found_header = false
    loop do
      if io.gets =~ /SEQENCE/ 
        found_header = true
        break
      end
      cnt += 1
      break if cnt > 10
    end
    if !found_header
      io.pos = init_pos
    end
    current_record = nil
    io.each do |line|
      line.chomp!
      # grab values
      ar = line.split(/\s+/)
      next if ar.size != 4
      (key, num_tms, signal_peptide, prediction) = ar
      # cast the values
      num_tms = num_tms.to_i
      signal_peptide = 
        case signal_peptide
        when 'Y'
          true
        when '0'
          false
        end
      index[key] = { 
        :num_certain_transmembrane_segments => num_tms, 
        :signal_peptide => signal_peptide,
      }
      if num_tms > 0
        index[key][:transmembrane_segments] = prediction_to_array(prediction)
      end
    end
    index
  end

end
