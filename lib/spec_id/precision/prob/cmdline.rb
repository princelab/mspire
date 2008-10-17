
require 'validator/cmdline'
require 'spec_id'

module SpecID
  module Precision
    class Prob
      class CmdlineParser

       DEFAULTS = SpecID::Precision::Prob::PN_DEFAULTS.merge( { :output => [[:csv, nil]], } )

       
        COMMAND_LINE = {
          :sort_by_init => ['--sort_by_init', "sort the proteins based on init probability"],
          :perc_qval => ['--perc_qval', "use percolator q-values to calculate precision"],
          :to_qvalues => ['--to_qvalues', "transform probabilities into q-values",
                                       "(includes pi_0 correction)",
                                       "uses PROB [TYPE] if given and supercedes",
                                       "the prob validation type",
                                       "*NOTE: include all PeptideProphet results",
                                       "(don't use any low prob cutoff) for",
                                       "accurate results!"],
          :prob => ['--prob [TYPE]', "use prophet probabilites to calculate precision",
                                     "TYPE = nsp [default] prophet nsp",
                                     "     (nsp also should be used for PeptideProphet results)",
                                     "     = init (for ProteinProphet results) use initial",
                                     "probability instead of nsp probability",
        ],
          # OUTPUT
          :proteins => ["--proteins", "includes proteins (and validation)"],
          :output => ["-o", "--output format[:FILENAME]", "format to output filtering results.",
                                                       "can be used multiple times", 
                                                       ":FILENAME is the filename to use (defaults to STDOUT)",
                                                       "valid formats are:",
                                                       "    csv  (default)",
                                                       "    to_plot",
                                                       "    calc_bkg_to_plot",
                                                       "    yaml",
                                                       #"    protein_summary (need to implement)",
                                                       #"    html_table      (need to implement)"
                                               ],

          # VALIDATION MODIFIERS:
          :pephits => ["--pephits <file>.srg", "an srg file pointing to the srf files for",
                                               "the given -prot.xml run",
                                               "[this or --digestion must be used for applicable]",
                                               "validators (validators depending on a",
                                               "false/total ratio)]"],
        }.merge( Validator::Cmdline::COMMAND_LINE )


        # returns (spec_id_obj, options, option_parser_obj)
        def parse(args)
          opts = {}
          opts[:output] = []
          @out_used = false
          opts[:sequest] = {}
          opts[:validators] = []
          # defaults

          option_parser = OptionParser.new do |op|
            def op.opt(arg, &block)
              on(*COMMAND_LINE[arg], &block)
            end

            def op.val_opt(arg, opts)
              on(*COMMAND_LINE[arg]) {|ar| Validator::Cmdline::PrepArgs[arg].call(ar, opts) }
            end

            def op.exact_opt(opts, arg)
              on(*COMMAND_LINE[arg]) {|v| opts[arg] = v}
            end

            op.banner = "USAGE: #{File.basename($0)} [OPTS] <file>-prot.xml | <file>.sqg"
            op.separator ""
            op.separator "    RETURNS: precision across the number of hits"
            op.separator "             (based on probability or q-value)"
            op.separator "             (optional) other validation of the results."
            op.separator ""

            op.separator "OUTPUT OPTIONS: "
            op.opt(:proteins) {|v| opts[:proteins] = true }
            op.opt(:output) do |output|
              # copied from rspec:
              # This funky regexp checks whether we have a FILE_NAME or not
              where = nil
              if (output =~ /([a-zA-Z_]+(?:::[a-zA-Z_]+)*):?(.*)/) && ($2 != '')
                output = $1
                where = $2
              else
                raise "When using several --output options only one of them can be without a file" if @out_used
                @out_used = true
              end
              opts[:output] << [output, where]
            end

            op.separator "GENERAL OPTIONS:"
            op.separator ""
            op.opt(:sort_by_init) {|v| opts[:sort_by_init] = true }
            op.separator "VALIDATION OPTIONS: "
            op.separator "   each option will calculate the precision"
            op.separator ""

            op.val_opt(:prob, opts)
            op.val_opt(:perc_qval, opts)
            op.val_opt(:to_qvalues, opts)
            op.val_opt(:decoy, opts)
            op.val_opt(:pephits, opts)       # sets opts[:ties] = false
            op.val_opt(:digestion, opts)
            op.val_opt(:bias, opts)
            op.val_opt(:bad_aa, opts)
            op.val_opt(:bad_aa_est, opts)

            op.val_opt(:tmm, opts)
            op.val_opt(:fasta, opts)
            op.val_opt(:tps, opts)

            op.separator ""
            op.separator "VALIDATION MODIFIERS: "
            op.val_opt(:false_on_tie, opts)  # sets opts[:ties] = false

          end
          option_parser.parse!(args)

          # prepare validators

          if args.size > 0
            spec_id_obj = ::SpecID.new(args[0])
            if opts[:ties] == nil   # will be nil or false
              opts[:ties] = Validator::Cmdline::DEFAULTS[:ties]
            end
            postfilter = 
              if spec_id_obj.class == SQTGroup or spec_id_obj.class == Proph::PepSummary
                #puts 'making background estimates with: top_per_scan'
                :top_per_scan
              else
                #puts 'making background estimates with: top_per_aaseq_charge'
                :top_per_aaseq_charge
              end

            opts[:validators] = Validator::Cmdline.prepare_validators(opts, !opts[:ties], opts[:interactive], postfilter, spec_id_obj)

            if opts[:output].size == 0
              opts[:output] = DEFAULTS[:output]
            end
          else
            spec_id_obj = nil
          end

          [spec_id_obj, opts, option_parser]
        end # parse
      end # CmdlineParser
    end # Prob
  end # Precision
end # SpecID





