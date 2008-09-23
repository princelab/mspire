require 'validator'

require 'validator/true_pos'
require 'validator/aa'
require 'validator/aa_est'
require 'validator/bias'
require 'validator/decoy'
require 'validator/transmem'
require 'validator/probability'
require 'validator/q_value'
require 'validator/prot_from_pep'

## these all for a stupid check...
require 'spec_id/sqt'
require 'spec_id/proph/prot_summary'
require 'spec_id/proph/pep_summary'

class Validator::Cmdline

  Validator_symbols_to_classes = {
    :tmm => Validator::Transmem::Protein,
    :decoy => Validator::Decoy,
    :bad_aa => Validator::AA,
    :bad_aa_est => Validator::AAEst,
    :tps => Validator::TruePos,
    :bias => Validator::Bias,
    :prob => Validator::Probability,
    :qval => Validator::QValue,
  }
  # was VAL_DEFAULTS
  DEFAULTS = {
    :tmm => 
    {
      # file                      
      :min_num_tmm_seqs => 1,     
      :expect_soluble => true,   
      :no_include_tm_peps => 0.8, 
      :bkg => 0.0,               
    },
    :decoy => 
    {
      :hits_together => true,
      :decoy_on_match => true,
      :decoy_to_target_ratio => 1.0,
    },
    :bad_aa => 
    {
      :false_if_found => true,
      :bkg => 0.0, 
    },
    :bad_aa_est => 
    {
      :false_if_found => true,
      :bkg => 0.0, 
    },
    :bias =>
    {
      :bkg => 0.0,
      :proteins_expected => true,
    },
    :ties => true,
  }
  COMMAND_LINE = {
    :decoy => ["--decoy /REGEXP/|FILENAME[,DTR,DOM]", Array, "REGEXP for decoy proteins (catenated searches) or a",
                                                "FILENAME of separate search on decoys.", 
                                                "All regular expressions must be surrounded by '/'",
                                                "(no extended options [trailing modifiers]).",
                                                "e.g., a run using concatenated reversed proteins that",
                                                "includes 'REVERSE' in the fasta heading:",
                                                "    --decoy /REVERSE/",
                                                "Anything fancier should be quoted:",
                                                "    --decoy '/^\\s*REVERSE/'",
                                                "If decoys proteins were searched in a separate file,",
                                                "then give the FILENAME (e.g., --decoy decoy.srg)",
                                                "DTR = Decoy to Target Ratio (default: #{DEFAULTS[:decoy][:decoy_to_target_ratio]})",
                                                "DOM = *true/false, decoy on match",],
        :tps => ["--tps <fasta>", "for a completely defined sample, this is the",
                                  "fasta file containing the true protein hits"],
         # may require digestion:
        :fasta => ["--fasta FASTA", "fasta file for phobius transmembrane",
                                    "(needed if PEPS options is not false)"],
        :digestion => ["--digestion ORIG_FASTA,PARAMS", Array, "[not recommended]",
                                                         "Creates the 'false/total' ratio with in silico",
                                                         "digestion.  Otherwise, the 3rd-10th best hits (sorted by",
                                                         "xcorr) are used.",
                                                         "The following validators will use this",
                                                         "information (shared between them) if option given",
                                                         "ORIG_FASTA = the fasta file used to do the run",
                                                         "PARAMS = the params file used to do the run",],
        :bias => ["--bias FASTA[,PE,BKG]", Array, "FASTA contains proteins expected to be in the sample",
                                                  "PE = *true|false proteins in fasta file expected in sample",
                                                  "BKG = Background frequency of fps (d: #{DEFAULTS[:bias][:bkg]})",],
        :bad_aa => ["--bad_aa AA,BKG]", Array, "An amino acid expected (or not expected) in legitimate hits",
                                                        "AA = The amino acid (e.g., 'C')",
                                                        "BKG = Background frequency of genuine pephits (d: #{DEFAULTS[:bad_aa][:bkg]}):",],
        :bad_aa_est => ["--bad_aa_est AA,BKG]", Array, "An amino acid expected (or not expected) in legitimate hits",
                                                        "AA = The amino acid (e.g., 'C')",
                                                        "BKG = Background frequency of genuine pephits (d: #{DEFAULTS[:bad_aa_est][:bkg]}):",],

        :tmm => ["--tmm <TM[,MIN,SOL,PEPS,BKG]>", Array, "TM = phobius.small or toppred.out file",
                                                         "phobius.small:",
                                                         "http://phobius.cgb.ki.se/",
                                                         "(select 'Short' output, and save output as file)",
                                                         "toppred.out:",
                                                         "http://bioweb.pasteur.fr/seqanal/interfaces/toppred.html",
                                                         "(output 'toppred.out' in 'New' or 'Xml' format)",
                                                         "MIN = Int, minimum number transmembrane seqs (def: #{DEFAULTS[:tmm][:min_num_tmm_seqs]})",
                                                         "SOL = true|false, this is a soluble fraction( def: #{DEFAULTS[:tmm][:expect_soluble]})",
                                                         "PEPS = Float | false, don't consider tm peps (>= fraction",
                                                         "                   tm content) (false skips) (def: #{DEFAULTS[:tmm][:no_include_tm_peps]})",
                                                         "BKG = Float , background contaminating insoluble (def: #{DEFAULTS[:tmm][:bkg]})"],


        # VALIDATION MODIFIERS
        :false_on_tie => ["--false_on_tie", "if peptide belongs to correct AND incorrect proteins",
                                            "it will be counted as correct"],

  }

      def self.boolean(arg, default)
        case arg
        when 'true' ; true
        when 'false' ; false
        else ; default
        end
      end

      PrepArgs = {
        :prob => lambda {|ar, opts|
        mthd = 
          if ar
            if ar == 'nsp'
              :probability
            elsif ar == 'init'
              :initial_probability
            else
              raise ArgumentError, "--prob [arg], optional arg can only be 'nsp' or 'init'!"
            end
          else
            :probability
          end
        opts[:validators].push([:prob, mthd])
      },
        :perc_qval => lambda {|ar, opts| opts[:validators].push([:perc_qval]) },
        :to_qvalues => lambda {|ar, opts| opts[:validators].push([:to_qvalues]) },
        :decoy => lambda {|ar, opts| 
        myargs = [:decoy] 
        first_arg = ar[0]
        val_opts = {}
        val_opts[:constraint] = 
          if first_arg[0,1] == '/' and first_arg[-1,1] == '/'
            # cast as a regular expression of has '/ /'
            Regexp.new(first_arg[1...-1])
          else
            # assume that it is a filename
            raise ArgumentError, "File does not exist: #{first_arg}\n(was this supposed to be a regular expression? if so, should be given: /#{first_arg}/)" unless File.exist?(first_arg)
            first_arg
          end
        val_opts[:decoy_to_target_ratio] = (ar[1] || DEFAULTS[:decoy][:decoy_to_target_ratio]).to_f
        val_opts[:decoy_on_match] = self.boolean(ar[2], DEFAULTS[:decoy][:decoy_on_match])
        myargs.push(val_opts)
        opts[:validators].push(myargs)
      },
        :fasta => lambda {|arg, opts|
        opts[:fasta] = Fasta.new(arg)
      },
        :digestion => lambda {|ar, opts|
        raise(ArgumentError, "need fasta and sequest params!") if ar.size != 2
        opts[:digestion] = ar.dup
        opts[:digestion_objects] = [Fasta.new(ar[0]), Sequest::Params.new(ar[1])]
      },
        :bias => lambda {|ar, opts|
        myargs = [:bias]
        myargs.push( Fasta.new(ar[0]) )
        val_opts = {}
        val_opts[:proteins_expected] = self.boolean(ar[1], DEFAULTS[:bias][:proteins_expected])
        val_opts[:background] = 
          if ar[2]
            ar[2].to_f
          else
            DEFAULTS[:bias][:bkg]
          end
        if ar[3]
          val_opts[:false_to_total_ratio] = ar[3].to_f
        end
        myargs.push(val_opts)
        opts[:validators].push(myargs)
      },
        :bad_aa => lambda {|ar, opts|
        ## GET the FREQUENCY
        myargs = [:bad_aa] 
        myargs.push( ar[0] )
        val_opts = {}
        val_opts[:background] = 
          if ar[1]
            ar[1].to_f
          else
            DEFAULTS[:bad_aa][:bkg]
          end
        if ar[2]
          val_opts[:false_to_total_ratio] = ar[2].to_f
        end
        myargs.push(val_opts)
        opts[:validators].push(myargs)
      },
        :bad_aa_est => lambda {|ar, opts|
        ## GET the FREQUENCY
        myargs = [:bad_aa_est] 
        myargs.push( ar[0] )
        val_opts = {}
        val_opts[:background] = 
          if ar[1]
            ar[1].to_f
          else
            DEFAULTS[:bad_aa_est][:bkg]
          end
        if ar[2]
          val_opts[:frequency] = ar[2].to_f
        end
        myargs.push(val_opts)
        opts[:validators].push(myargs)
      },

        :tmm =>  lambda {|ar, opts|
        myargs = [:tmm]
        myargs.push( ar[0] )
        val_opts = {}
        val_opts[:min_num_tms] =
          if ar[1] ; ar[1].to_i
          else ; DEFAULTS[:tmm][:min_num_tmm_seqs]
          end
        val_opts[:soluble_fraction] = self.boolean(ar[2], DEFAULTS[:tmm][:expect_soluble])
        val_opts[:no_include_tm_peps] =
          if ar[3]
            case ar[3]
            when 'false' ; false
            else ; ar[3].to_f
            end
          else ; DEFAULTS[:tmm][:no_include_tm_peps]
          end
        val_opts[:background] =
          if ar[4] ; ar[4].to_f
          else ; DEFAULTS[:tmm][:bkg]
          end
        if ar[5]
          val_opts[:false_to_total_ratio] = ar[5].to_f
        end
        myargs.push(val_opts)
        opts[:validators].push( myargs )
      },
      :pephits => lambda {|v,opts| opts[:pephits] = SpecID.new(v) },
      :tps => lambda {|v,opts| opts[:validators].push([:tps, Fasta.new(v)]) },
      :false_on_tie => lambda {|v,opts| opts[:ties] = false },
      }

      def self.requires_pephits?(spec_id_obj)
        case spec_id_obj
        when Proph::ProtSummary : true
        # at least currently (subject to change)
        when Proph::PepSummary : true
        when SQTGroup
          if spec_id_obj.peps.first.respond_to?(:q_value)  
            # its percolator output and we don't have other hits to use
            true
          else
            false
          end
        else ; false
        end 
      end

      # remove the keys from opts involved in validators and return an array
      # of validators
      # postfilter is one of :top_per_scan, :top_per_aaseq,
      # :top_per_aaseq_charge (of which last two are subsets of scan)
      def self.prepare_validators(opts, false_on_tie, interactive, postfilter, spec_id)      

        validator_args = opts[:validators]
        if validator_args.any? {|v| v.first == :to_qvalues }
          prob_val_args_ar = validator_args.select {|v| v.first == :prob }.first
          prob_method = 
            if prob_val_args_ar && prob_val_args_ar[1]
              prob_val_args_ar[1]
            else
              :probability
            end
          validator_args.reject! {|v| v.first == :prob }

          require 'vec'
          require 'qvalue'

          # get a list of p-values
          pvals = spec_id.peps.map do |pep| 
            val = 1.0 - pep.send(prob_method)
            val = 1e-9 if val == 0
            val
          end
          pvals = VecD.new(pvals)
          #qvals = pvals.qvalues(false, :lambda_vals => 0.30 )
          qvals = pvals.qvalues
          qvals.zip(spec_id.peps) do |qval,pep|
            pep.q_value = qval
          end
        end

        validator_args.map! do |v|
          if v.first == :to_qvalues || v.first == :perc_qval
            [:qval]
          else
            v
          end
        end

        correct_wins = !false_on_tie
        need_false_to_total_ratio = []
        need_frequency = []
        transmem_vals = []
        validators = validator_args.map do |args|
          tp = args.shift
          val_args = args.dup # protect the original keys
          val_args = 
            case tp
            when :tmm
              val_args[1][:correct_wins] = correct_wins
              if opts.key?(:fasta) 
                val_args[1][:fasta] = opts[:fasta]
              end
              val_args
            when :bias
              val_args[1][:correct_wins] = correct_wins
              val_args
            when :tps
              val_args = [val_args[0], correct_wins]
              val_args
            when :decoy
              val_args[0][:correct_wins] = correct_wins
              # don't delete the key here since we need the decoy = regexp key
              val_args
            else ## bad_aa, prob, and qval are represented here:
              val_args
            end
          val = Validator_symbols_to_classes[tp].new( *val_args )
          # make some lists of validators based on pre-processing needs:
          if tp == :tmm
            transmem_vals << val
          end
          potential_digestion_classes = /Transmem|AA|AAEst|Bias/
          if val.class.to_s =~ potential_digestion_classes
            if val.class.to_s == 'Validator::AAEst'
              need_frequency.push(val) if val.frequency.nil?
            elsif !(val.false_to_total_ratio.nil?)
              $stderr.puts "using false_to_total_ratio: #{val.false_to_total_ratio}"
            else
              need_false_to_total_ratio << val
            end
          end
          val
        end

        if ((need_false_to_total_ratio.size > 0) or (need_frequency.size > 0))
          if opts.key?(:digestion_objects)
            #raise ArgumentError, "requires --digestion fasta,params argument!" if !opts.key?(:digestion_objects)
            peps = Digestor.digest( *(opts[:digestion_objects]) )
            need_false_to_total_ratio.each do |val|
              val.set_false_to_total_ratio( peps )
            end
            if need_frequency.size > 0
              need_frequency.each do |val|
                val.set_frequency( opts[:digestion_objects][0] )
              end
            end
            opts.delete(:digestion_objects)
          else  ## do the new and improved selection of non-top hits to get false_to_total_ratios and freqs
            $stderr.puts "...using pephits to calculate background ratios"
            # first_index, last_index
            pephits = 
              if opts[:pephits]  ## protein prophet (since it needs to get ratios somewhere
                $stderr.puts "using --pephits"
                opts[:pephits].peps
              elsif requires_pephits?(spec_id)
                raise ArgumentError, "with objects of class '#{spec_id.class}', one of your validators requires --pephits or --digestion"
              else
                $stderr.puts "using given spec_id.peps"
                spec_id.peps
              end

            not_first_or_second_peps = Sequest.other_hits_sorted_by_xcorr(pephits, 2, 9, [:base_name, :first_scan, :charge])
            pephits = 
              case postfilter
              when :top_per_scan 
                $stderr.puts "using top_per_scan" ; not_first_or_second_peps
              when :top_per_aaseq
                # it doesn't matter which one is given since validators are
                # based on amino acid sequence
                $stderr.puts 'using top_per_aaseq'
                not_first_or_second_peps.hash_by(:aaseq).values.map {|pep| pep.first }
              when :top_per_aaseq_charge
                $stderr.puts 'using top_per_aaseq_charge'
                not_first_or_second_peps.hash_by(:aaseq, :charge).values.map {|pep| pep.first }
              else
                raise ArgumentError, "must have a valid postfilter method, yours: '#{postfilter}'"
              end

            need_false_to_total_ratio.each do |val|
              val.set_false_to_total_ratio( pephits )
              $stderr.puts "false_to_total_ratio for #{val.class.to_s}: #{val.false_to_total_ratio}"
            end
            if need_frequency.size > 0
              need_frequency.each do |val|
                $stderr.puts "Setting frequency!"
                val.set_frequency( pephits )
              end
            end
          end
        end

        if (transmem_vals.size > 0)   #  and interactive   ## we'd like to just run this for interactive
          # This is overkill if we are doing a single filtering job, but it
          # ensures that it works in all the ways I'm doing it.  Should
          # refactor eventually !!
          transmem_vals.each do |val|                      ## but, prob uses it too!
            val.transmem_status_hash = val.create_transmem_status_hash(spec_id.peps)
          end
        end
        validators

      end

end
