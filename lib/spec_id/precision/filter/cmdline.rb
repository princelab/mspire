require 'validator/cmdline'
require 'spec_id'


module SpecID
  module Precision
    class Filter
      class CmdlineParser

       DEFAULTS = SpecID::Precision::Filter::FV_DEFAULTS.merge( { :output => [[:text_table,nil]], } )

       
        COMMAND_LINE = {
          # SEQUEST
          :xcorr1 => ["-1", "--xcorr1 N", Float, "xcorr at +1 charge  default: #{DEFAULTS[:sequest][:xcorr1]}"],
          :xcorr2 => ["-2", "--xcorr2 N", Float, "xcorr at +2 charge  default: #{DEFAULTS[:sequest][:xcorr2]}"],
          :xcorr3 => ["-3", "--xcorr3 N", Float, "xcorr at +3 charge  default: #{DEFAULTS[:sequest][:xcorr3]}"],

          :deltacn => ["-d", "--deltacn N", Float, ">= deltacn          default: #{DEFAULTS[:sequest][:deltacn]}"],
          :ppm => ["-p", "--ppm N", Float,     "<= ppm              default: #{DEFAULTS[:sequest][:ppm]}",
                                               "if bioworks.xml, then ppm = deltamass*10^6/mass"],
          :no_deltacnstar => ["--no_deltacnstar", "Do not pass deltacn of top hit with no 2nd hit",
                                                  "(these are set at 1.1 by bioworks)"],

          # OUTPUT
          :proteins => ["--proteins", "includes proteins (and validation)"],
          :output => ["-o", "--output format[:FILENAME]", "format to output filtering results.",
                                                       "can be used multiple times", 
                                                       ":FILENAME is the filename to use (defaults to STDOUT)",
                                                       "valid formats are:",
                                                       "    text_table      (default)",
                                                       "    yaml",
                                                       #"    protein_summary (need to implement)",
                                                       #"    html_table      (need to implement)"
                                               ],

          # VALIDATION MODIFIERS:
          :hits_separate => ["--hits_separate", "target/decoy hits are normally together when choosing",
                                                "the top hit per peptide (in prefilter and postfilter)",
                                                "in BOTH catenated and separate searches.  This flag",
                                                "separates them when finding the top hit per scan.",
                                                "[This option modifies behavior of --decoy options]"],

          # OTHER:
          :prefilter => ["--prefilter", "finds the top hit per file+scan+charge and removes",
                                        "others.  Speeds up filtering with '--interactive'."],
          :postfilter => ["--postfilter ARG", "ARG = top_per_scan | top_per_aaseq[_charge]",
                                            "'top_per_scan' hashes on filename+scan.",
                                            "'top_per_aaseq' hashes only on aaseq",
                                            "'top_per_aaseq_charge' hashes on aaseq+charge."],
          :top_hit_by => ["--top_hit_by ARG", "ARG = xcorr | probability    (xcorr default)"],



          :interactive => ["-i", "--interactive [FILENAME]", "interactive filtering",
                                                             "FILENAME given, then the interactive commands are",
                                                             "read out of that file.  NOTE: The flag without the",
                                                             "filename must not be placed in front of an input",
                                                             "file argument!  e.g., -i bioworks.xml # -> bad!",
                                                             "e.g., bioworks.xml -i # -> ok!"],

          :interactive_verbose => ["--interactive_verbose", "give help and hints in interactive mode"],

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

            op.banner = "USAGE: #{File.basename($0)} [OPTS] <bioworks.xml | bioworks.srg | .srf ....srf>"
            op.separator ""
            op.separator "    EXPECTS: the multiconsensus XML export of Bioworks 3.X (bioworks.xml) -or- *.srf files"
            op.separator "             grouped together (bioworks.srg) [type 'srf_group.rb' at the cmd line]"

            op.separator "             multiple .srf files may also be entered."
            op.separator "    RETURNS: the number of peptides/proteins ID'd at given thresholds with"
            op.separator "             (optional) validation of the results."
            op.separator ""

            #op.separator("** 'dcn*' is the number of peptides with deltacn == 1.1")
            #op.separator("   (these are peptides who are the only hit with xcorr > 0)")
            op.separator "SEQUEST OPTIONS: "
            op.exact_opt(opts[:sequest], :xcorr1)
            op.exact_opt(opts[:sequest], :xcorr2)
            op.exact_opt(opts[:sequest], :xcorr3)
            op.exact_opt(opts[:sequest], :deltacn)
            op.exact_opt(opts[:sequest], :ppm)
            op.opt(:no_deltacnstar)     {|v| opts[:sequest][:include_deltacnstar] = false} 
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

            op.separator ""
            op.separator "VALIDATION OPTIONS: "
            op.separator "   each option will calculate the precision"
            op.separator ""

            op.val_opt(:decoy, opts)
            op.exact_opt(opts, :decoy_pi_zero)
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

            op.opt(:hits_separate) { opts[:hits_together] = false } # :top_hits_together

            op.separator ""
            op.separator "OTHER OPTIONS: "
            op.opt(:interactive) do |v| 
              opts[:interactive] = 
                if v
                  v 
                else
                  true
                end
            end
            op.opt(:interactive_verbose) {|v| opts[:interactive_verbose] = v }
            
            op.opt(:top_hit_by) {|v| opts[:top_hit_by] = v.to_sym}
            op.opt(:postfilter) {|v| opts[:postfilter] = v.to_sym}
            op.opt(:prefilter) {|v| opts[:prefilter] = true }


            #op.on("--yaml", "spits out yaml-ized data") {|v| opts[:tabulate = v }
            #op.on("--combined_score", "shows the combined score") {|v| opts[:combined_score = v }
            #op.on("--marshal", "will write marshaled data or read existing") {|v| opts[:marshal = v }
            #op.on("--log <file>", "also writes all output to file") {|v| opts[:log = v }
            ### NEED TO IMPLEMENT THIS:
            ##op.on("--protein_summary", "writes passing proteins to .summary.html files") {|v| opts[:protein_summary = v }
            #op.on("-z", "--occams_razor", "will show minimal set of proteins") {|v| opts[:occams_razor = v }

          end
          option_parser.parse!(args)

          # prepare interactive object if necessary:
          if v = opts[:interactive]
            klass = SpecID::Precision::Filter::Interactive
            if v.is_a? String
              opts[:interactive] = klass.new(v, opts[:interactive_verbose])
            else
              opts[:interactive] = klass.new(nil, opts[:interactive_verbose])
            end
          end


          opts[:sequest] = DEFAULTS[:sequest].merge(opts[:sequest])

          # prepare validators

          if args.size > 0
            spec_id_obj = 
              if args[0] =~ /\.srf$/i
                ::SpecID.new(args)
              else
                ::SpecID.new(args[0])
              end
            if opts[:ties] == nil   # will be nil or false
              opts[:ties] = Validator::Cmdline::DEFAULTS[:ties]
            end
            opts[:validators] = Validator::Cmdline.prepare_validators(opts, !opts[:ties], opts[:interactive], opts[:postfilter], spec_id_obj)

            if opts[:output].size == 0
              opts[:output] = DEFAULTS[:output]
            end
          else
            spec_id_obj = nil
          end

          [spec_id_obj, opts, option_parser]
        end # parse
      end # CmdlineParser
    end # Filter
  end # Precision
end # SpecID





