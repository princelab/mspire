require 'yaml'
require 'table'
require 'spec_id/precision/output'

module SpecID ; end
module SpecID::Precision ; end
class SpecID::Precision::Filter ; end

class SpecID::Precision::Filter::Output 
  include SpecID::Precision::Output
  
  ProtPrecAbbr = {
    :normal => 'nrm',
    :normal_stdev => 'nrm_std',
    :worst => 'worst',
  }

  GTE = '>='
  LTE = '<='
  MSial_operator = {
    'xcorr1' => GTE,
    'xcorr2' => GTE,
    'xcorr3' => GTE,
    'deltacn' => GTE,
    'ppm' => LTE,
  }

  # takes a hash {:normal => x, :normal_stdev => y :worst => z }
  # and returns a string
  def protein_precision_to_s(hash)
    "#{hash[:worst]}--#{hash[:normal]}+/-#{hash[:normal_stdev]}"
  end

  #      num tps tmm badAA decoy
  # pep
  # prot  
  #
  def params_as_string(params_hash)
    hash = SpecID::Precision::Output.symbol_keys_to_string(params_hash)
    cleanup_params_hash(hash)
    hash_as_string(hash)
  end

  def text_table(fh, answer)
    col_headings = ['num']
    if answer[:params][:validators]
      val_strings = answer[:params][:validators].map do |val|
        Validator::Validator_to_string[val.class.to_s]
      end
      col_headings.push( *val_strings )
    end

    data_rows = []
    # push on the peptide row
    row_headings = ['peps']
    pep_row = []
    pep_row << answer[:pephits].size
    if answer[:params][:validators]
      answer[:params][:validators].zip( answer[:pephits_precision] ) do |val, precision|
        pep_row << precision
      end
    end
    data_rows << pep_row

    # push on the protein row
    if answer[:prothits]
      [:worst, :normal, :normal_stdev].each do |guy|
        prot_row = []
        row_headings << "prots(#{ProtPrecAbbr[guy]})"
        if guy == :worst
          prot_row << answer[:prothits].size 
        else
          prot_row << '"'
        end
        answer[:prothits_precision].each do |precision|
          prot_row.push(precision[guy])
        end
        data_rows << prot_row
      end
    end
    params_string = params_as_string(answer[:params])
    table = Table.new( data_rows, row_headings, col_headings )
    fh.puts params_string
    fh.puts ""
    fh.puts( table.to_formatted_string )
    fh.puts ""
  end
  
  def yaml(fh, answer)
    final_output = { :params => answer[:params].dup }
    #"PEPHITS"
    #answer[:pephits]
    final_output[:pephits] = answer[:pephits].size 
    if answer[:prothits]
      final_output[:prothits_precision] = answer[:params][:validators].zip( answer[:prothits_precision] ).map do |val, precision|
        {'validator' => Validator::Validator_to_string[val.class.to_s], 'values' => precision }
      end
      final_output[:prothits] = answer[:prothits].size 

      #final_output[:prothits_precision] = {} if answer[:prothits_precision]
      #final_output[:prothits] = answer[:prothits].size 
      #answer[:params][:validators].zip( answer[:prothits_precision] ) do |val, precision|
      #  final_output[:prothits_precision][Validator::Validator_to_string[val.class.to_s]] = precision
      #end
    end
    final_output[:pephits_precision] = answer[:params][:validators].zip( answer[:pephits_precision] ).map do |val, precision|
      { 'validator' => Validator::Validator_to_string[val.class.to_s], 'value' => precision }
    end
    final_output[:pephits] = answer[:pephits].size 
    final_output_as_strings = SpecID::Precision::Output.symbol_keys_to_string(final_output)
    cleanup_params_hash(final_output_as_strings['params'])
    fh.print(final_output_as_strings.to_yaml )
  end


  # returns nil
  def cleanup_params_hash(hash)
    ################################
    # OUTPUT
    ################################
    hash['output'] = hash['output'].map do |output|
      if output[1] == nil
        output[1] = 'STDOUT'
      end
      output.join(" => ")
    end
    %w(postfilter top_hit_by).each do |st|
      hash[st] = hash[st].to_s
    end
    if hash['interactive']
      if file = hash['interactive'].file
        hash['interactive'] = file
      else
        hash['interactive'] = true
      end
    end
    if hash['decoy']
      if hash['decoy']['regexp']
        hash['decoy']['regexp'] = hash['decoy']['regexp'].inspect
      end
    end
    if x = hash['validators']
      hash['validators'] = Validator.sensible_validator_hashes(x)
    end
    nil
  end

end
