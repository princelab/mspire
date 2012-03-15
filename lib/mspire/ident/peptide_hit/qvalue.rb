require 'mspire/ident/search'
require 'mspire/ident/peptide_hit'

module Mspire ; end
module Mspire::Ident ; end

class Mspire::Ident::PeptideHit
  module Qvalue
    FILE_EXTENSION = '.phq.tsv'
    FILE_DELIMITER = "\t"
    HEADER = %w(run_id id aaseq charge qvalue)

    class << self

      # writes to the file, adding an extension
      def to_phq(base, hits, qvalues=[])
        to_file(base + FILE_EXTENSION, hits, qvalues)
      end

      # writes the peptide hits to a phq.tsv file. qvalues is a parallel array
      # to hits that can provide qvalues if not inherent to the hits
      # returns the filename.
      def to_file(filename, hits, qvalues=[])
        File.open(filename,'w') do |out|
          out.puts HEADER.join(FILE_DELIMITER)
          hits.zip(qvalues) do |hit, qvalue|
            out.puts [hit.search.id, hit.id, hit.aaseq, hit.charge, qvalue || hit.qvalue].join(FILE_DELIMITER)
          end
        end
        filename
      end

      # returns an array of PeptideHit objects from a phq.tsv
      def from_file(filename)
        searches = Hash.new {|h,id|  h[id] = Mspire::Ident::Search.new(id) }
        peptide_hits = []
        File.open(filename) do |io|
          header = io.readline.chomp.split(FILE_DELIMITER)
          raise "bad headers" unless header == HEADER 
          io.each do |line|
            line.chomp!
            (run_id, id, aaseq, charge, qvalue) = line.split(FILE_DELIMITER)
            ph = Mspire::Ident::PeptideHit.new
            ph.search = searches[run_id]
            ph.id = id; ph.aaseq = aaseq ; ph.charge = charge.to_i ; ph.qvalue = qvalue.to_f
            peptide_hits << ph
          end
        end
        peptide_hits
      end

      alias_method :from_phq, :from_file

    end
  end # Qvalue
end # Peptide Hit
