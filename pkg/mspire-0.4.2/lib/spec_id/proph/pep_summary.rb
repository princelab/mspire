
require 'arrayclass'
require 'spec_id/sequest/pepxml'
require 'spec_id/parser/proph'

module Sequest ; end
class Sequest::PepXML ; end
class Sequest::PepXML::MSMSRunSummary ; end
class Sequest::PepXML::SearchHit ; end

module SpecID ; end
module SpecID::Prot ; end
module SpecID::Pep ; end



module Proph

  class PepSummary
    include SpecID

    Filetype_and_version_re_new = /version="PeptideProphet v([\d\.]+) /

    # inherits prots and peps

    # the protein groups
    # currently these are just xml nodes returned!
    attr_accessor :peptideprophet_summary
    attr_accessor :msms_run_summaries
    attr_accessor :version

    def hi_prob_best ; true end

    def get_version(file)
      answer = nil
      File.open(file) do |fh|
        8.times do
          line = fh.gets
          answer = 
            if line =~ Filetype_and_version_re_new
              $1.dup
            end
          break if answer
        end
      end
      raise(ArgumentError, "couldn't detect version in #{file}") unless answer
      answer
    end

    def search_hit_class
      PepSummary::Pep
    end

    def initialize(file=nil)
      if file
        @version = get_version(file)
        spec_id = SpecID::Parser::PepProph.new(:spec_id).parse(file, :spec_id => self)
      end
    end
  end

  # this is a SpecID::Pep (by interface: not including stuff yet)
  class PepSummary::Pep < Sequest::PepXML::SearchHit
    # aaseq is defined in SearchHit
    
    %w(probability fval ntt nmc massd prots).each do |guy|
      self.add_member(guy)
    end

    # returns self
    def from_pepxml_node(node)
      super(node)

      an_res = node.find_first('child::analysis_result')
      pp_n = an_res.find_first('child::peptideprophet_result')
      self.probability = pp_n['probability'].to_f
      pp_n.find('descendant::parameter').each do |par_n|
        case par_n['name']
        when 'fval'
          self.fval = par_n['value'].to_f
        when 'ntt'
          self.ntt = par_n['value'].to_i
        when 'nmc'
          self.nmc = par_n['value'].to_i
        when 'massd'
          self.massd = par_n['value'].to_f
        end
      end
      self
    end
  end

  ::Proph::PepSummary::Prot = Arrayclass.new(%w(name protein_descr peps))

  class PepSummary::Prot
    def first_entry ; self[0] end ## name
    def reference ; self[0] + ' ' + self[1] end
  end

end




