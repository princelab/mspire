require 'xml_style_parser'
require 'ms/spectrum'
require 'ms/scan'

module MS::Parser::MzData ; end

class MS::Parser::MzData::DOM
  include XMLStyleParser
  include MS::Parser::MzData

  def initialize(parse_type=:msrun, version='1.0')
    @method = parse_type
    @version = version
  end

  # true if there is a node <dataProcessing><software><name>Bioworks Browser</...>
  # otherwise false
  def is_bioworks33?(description_node)
    begin
      software_node = description_node.find_first('child::dataProcessing').find_first('child::software')
      name = software_node.find_first('child::name').content 
      version = software_node.find_first('child::version').content 
      ((name == 'Bioworks Browser') and (version == '3.3'))
    rescue
      false
    end
  end

  # OPTIONS:
  #   :msrun => MSRun    # use this object instead of creating one
  def msrun(file, opts={})
    msrun_obj = 
      if x = opts[:msrun]
        msrun_obj = x
      else
        MS::MSRun.new
      end
    # should ensure that parsing is not counting spaces...

    # a string we'd parse like this:
    # doc = XML::Parser.string(st).parse

    # WE NEED TO GET scan_count, start_time and end_time!!!!
    id_to_scan_hash = {}

    #    0   1       2             3       4     5          6
    # %w(num msLevel retentionTime startMz endMz precursor spectrum)

    io =
      if file.is_a? String
        filename = file
        File.open(file)
      else
        file
      end
    root = get_root_node_from_io(io)


    description = root.find_first('child::description')
    bioworks33 = is_bioworks33?(description)  
    spectrum_list = description.next

    scans = []

    # bioworks 33 gives incorrect scan count
    stated_num_scans = spectrum_list['count'].to_i

    # if I move from node to node, it means I've checked that it's a sequence
    # and that the elements are req'd
    if spectrum_list.child?
      spectrum_n = spectrum_list.child
      loop do
        scan = MS::Scan.new(9)
        id = spectrum_n["id"].to_i
        id_to_scan_hash[id] = scan
        spec_desc_n = spectrum_n.child   # required in sequence
        spec_settings_n = spec_desc_n.child # required in sequence
        if acq_n = spec_settings_n.find_first('descendant::acquisition')
          scan[0] = acq_n['acqNumber'].to_i
        else
          scan[0] = id
        end
        spec_inst_n = spec_settings_n.find_first('child::spectrumInstrument')
        scan[1] = spec_inst_n['msLevel'].to_i

        # we could use a scan_count, but in bioworks 33, we can't trust the
        # scan count!  So, we just collect them
        scans << scan 

        scan[3] = spec_inst_n['mzRangeStart'].to_f
        scan[4] = spec_inst_n['mzRangeStop'].to_f
        spec_inst_n.find('child::cvParam').each do |cv_param|
          if cv_param['name'] == 'TimeInMinutes'
            scan[2] = cv_param['value'].to_f * 60 #convert to seconds
          end
        end
        if scan[1] > 1  # precursormz info
          prec_list_n = spec_settings_n.next
          raise RuntimeError, "MSRun objects can only accept 1 precursor" if prec_list_n['count'] != '1'
          prec_n = prec_list_n.find_first('child::precursor')
          # %w(mz inten parent ms_level parent charge_states)
          prec = MS::Precursor.new
          unless bioworks33  # bioworks33 points to the wrong scan!!!
            prec[2] = id_to_scan_hash[prec_n['spectrumRef'].to_i]
          end
          # we're not keeping track of this guy anymore
          # prec[3] = prec_n['msLevel'].to_i
          charges = []
          prec_n.find('descendant::cvParam').each do |cv_param_n|
            case cv_param_n['name']
            when 'MassToChargeRatio'
              prec[0] = cv_param_n['value'].to_f
              # find the prec intensity
              unless bioworks33
                prec[1] = prec[2].spectrum.intensity_at_mz(prec[0])
              end
            when 'ChargeState'
              charges << cv_param_n['value'].to_i
            end
          end
          prec[3] = charges
          scan[5] = prec
        else  # no precursors
          scan[5] = nil
        end
        # here's the one line way of doing it, but it's probably more clear in
        # the loop
        #while ((mz_array_bin_n = spec_desc_n.next).name != 'mzArrayBinary') do
        unless opts[:lazy] == :no_spectra
          mz_array_bin_n = nil
          loop do
            mz_array_bin_n = spec_desc_n.next
            break if mz_array_bin_n.name == 'mzArrayBinary'
          end
          mz_data_n = mz_array_bin_n.child
          inten_array_bin_n = mz_array_bin_n.next
          inten_data_n = inten_array_bin_n.child
          case opts[:lazy]
          when :string
           scan[6] = MS::Spectrum::LazyString.from_base64_pair(mz_data_n.content, mz_data_n['precision'].to_i, ((mz_data_n['endian']=='little') ? false : true), inten_data_n.content, inten_data_n['precision'].to_i, ((inten_data_n['endian']=='little') ? false : true) )
          when :io
            mz_data_n_content = mz_data_n.content
            i_data_n_content = inten_data_n.content
            scan[6] = MS::Spectrum::LazyIO.new(io, mz_data_n_content.first, mz_data_n_content.last, mz_data_n['precision'].to_i, ((mz_data_n['endian']=='little') ? false : true), i_data_n_content.first, i_data_n_content.last, inten_data_n['precision'].to_i, ((inten_data_n['endian']=='little') ? false : true))
          when :not
            mz = MS::Spectrum.base64_to_array(mz_data_n.content, mz_data_n['precision'].to_i, ((mz_data_n['endian']=='little') ? false : true))
            inten = MS::Spectrum.base64_to_array(inten_data_n.content, inten_data_n['precision'].to_i, ((inten_data_n['endian']=='little') ? false : true))
            scan[6] = MS::Spectrum.new(mz, inten)
          end
        end

        # set up the next loop
        break unless spectrum_n = spectrum_n.next
      end
    end
    if bioworks33
      MS::MSRun.add_parent_scan(scans, ((opts[:lazy] == :not) ? true : false))
    end
    msrun_obj.scans = scans
    msrun_obj.scan_count = scans.size
    unless bioworks33  # we know the scan count is off here
      if msrun_obj.scan_count != stated_num_scans
        warn "num collected scans (#{scans.size}) does not agree with stated num scans (#{stated_num_scans})!"
      end
    end
    msrun_obj.start_time = msrun_obj.scans.first.time
    msrun_obj.end_time = msrun_obj.scans.last.time

    io.close if filename
  end

end



