
require 'nokogiri'
require 'uuid'
require 'cv'
require 'mspire/mzml'
require 'mspire/mzml/spectrum'
require 'pathname'
require 'digest/sha1'

module Mspire end

module Mspire::Imzml
  # array length (number of values), the offset (start in file in bytes),
  # and the encoded length (in bytes).
  DataArrayInfo = Struct.new :array_length, :offset, :encoded_length

  class Writer

    DEFAULTS = {
      mz_data_type: :float,
      mz_precision: 64,
      intensity_data_type: :float, 
      intensity_precision: 32,
    }

    # Integer values (dtype=:int) may be stored with precision = 8, 16, 32,
    # 64 . Floating point values may be stored as 32 or 64 bit precision.
    # The byte order is always little endian (intel style).
    #
    # NOTE: the documentation is not clear whether they want signed or
    # unsigned integers!  Right now this outputs signed integers (my
    # educated guess as to what is required)
    def write_data_array(fh, values, dtype=:float, precision=32)
      pack_code = 
        case dtype
        when :float
          precision == 64 ? 'E*' : 'e*'
        when :int
          # using signed!!!! (should these be unsigned??? NOT DOCUMENTED in
          # imzml resources anywhere!)
          case precision
          when 8  ; 'c<*'
          when 16 ; 's<*'
          when 32 ; 'l<*'
          when 64 ; 'q<*'
          else
            raise 'precision must be 8, 16, 32, or 64 for dtype==:int'
          end
        else
          raise 'dtype must be :int or :float!'
        end
      fh.print values.pack(pack_code)
    end

    # returns an array of DataArrayInfo pairs
    #
    # These must be defined in the config hash with valid values (see
    # write_data_array for what those are):
    # 
    #     :mz_data_type
    #     :mz_precision
    #     :intensity_data_type
    #     :intensity_precision
    #
    # Also recognizes :data_structure (:processed or :continuous).  If
    # :continuous, then the first spectrum is used to write the initial m/z
    # and intensity pair, then in every spectrum after that the m/z data (if
    # any) is ignored and only the intensities are written).  The return is
    # the same, the data info for each intensity is coupled with the m/z
    # info from the first m/z data.
    def write_binary(filename, spectra_iterator, config)
      config = DEFAULTS.merge(config)
      raise ":data_structure must be :continuous or :processed" unless [:processed, :continuous].include?(config[:data_structure])
      (mz_dtype, mz_prec, int_dtype, int_prec) = config.values_at(:mz_data_type, :mz_precision, :intensity_data_type, :intensity_precision)
      mz_prec_in_bytes = mz_prec / 8
      int_prec_in_bytes = int_prec / 8
      File.open(filename, 'wb') do |out|
        out.print [config[:uuid]].pack("H*")

        if config[:data_structure] == :continuous
          # write the first m/z and get its info
          mzs = spectra_iterator.peek.mzs
          mz_info = Mspire::Imzml::DataArrayInfo.new mzs.size, out.pos, mzs.size * mz_prec_in_bytes
          write_data_array(out, mzs, mz_dtype, mz_prec)
        end
        spectra_iterator.map do |spec|

          if config[:data_structure] == :processed
            mzs = spec.mzs
            mz_info = Mspire::Imzml::DataArrayInfo.new mzs.size, out.pos, mzs.size * mz_prec_in_bytes
            write_data_array(out, spec.mzs, mz_dtype, mz_prec)
          end

          ints = spec.intensities
          int_info = Mspire::Imzml::DataArrayInfo.new ints.size, out.pos, ints.size * int_prec_in_bytes
          write_data_array(out, spec.intensities, int_dtype, int_prec)
          [mz_info, int_info]
        end
      end
    end

    # converts image related hash values to an array of loose describe!
    # params
    def image_hash_to_cvs(hash)
      cvs = []
      cvs << case hash[:data_structure].to_sym
      when :processed ; 'IMS:1000031'
      when :continuous ; 'IMS:1000030'
      else ; raise ":data_structure must be :processed or :continuous"
      end 

      cvs << case hash[:scan_pattern].to_sym
      when :meandering ; 'IMS:1000410'
      when :random ; 'IMS:1000412'
      when :flyback ; 'IMS:1000413'
      else ; raise ":scan_pattern must be :meandering, :random or :flyback"
      end

      cvs << case hash[:scan_type].to_sym
      when :horizontal ; 'IMS:1000480'
      when :vertical ; 'IMS:1000481'
      else ; raise ":scan_type must be :horizontal or :vertical"
      end

      cvs << case hash[:linescan_direction].to_s
      when 'left-right' ; 'IMS:1000402'
      when 'right-left' ; 'IMS:1000403'
      when 'bottom-up' ; 'IMS:1000400'
      when 'top-down' ; 'IMS:1000401'
      when 'none' ; 'IMS:1000404'
      else ; raise ":linescan_direction unacceptable"
      end

      cvs << case hash[:linescan_sequence].to_s
      when 'top-down' ; 'IMS:1000493'
      when 'bottom-up' ; 'IMS:1000492'
      when 'left-right' ; 'IMS:1000491'
      when 'right-left' ; 'IMS:1000490'
      else ; raise "linescan_sequence unacceptable"
      end

      max_pix_dims = hash[:max_dimensions_pixels].split(/x/i)
      cvs.push *['IMS:1000042', 'IMS:1000043'].zip(max_pix_dims).to_a

      real_dims = hash[:max_dimensions_microns].split(/x/i)
      cvs.push *['IMS:1000044', 'IMS:1000045'].zip(real_dims).map {|pair| [*pair, "UO:0000017"] }

      pix_dims = hash[:pixel_size].split(/x/i)
      cvs.push *["IMS:1000046", "IMS:1000047"].zip(pix_dims).map {|pair| [*pair, "UO:0000017"] }
      cvs
    end

    def experiment_hash_to_cvs(hash)
      cvs = { 
        :matrix_solution_concentration => "MS:1000835",
        :matrix_solution => "MS:1000834",
        :solvent => 'IMS:1001211',
        :solvent_flowrate => 'IMS:1001213',
        :spray_voltage => 'IMS:1001212',
        :target_material => 'IMS:10000202'
      }.map do |key,cv_acc|
        [cv_acc, hash[key]] if hash[key]
      end.compact

      mats = hash[:matrix_application_types]
      if mats
        app_types = mats.map do |typ|
          case typ.to_s
          when 'sprayed' ; 'MS:1000838'
          when 'precoated' ; 'MS:1000839'
          when 'printed' ; 'MS:1000837'
          when 'drieddroplet' ; 'MS:1000836'
          else ; raise "invalid matrix_application_type"
          end
        end
        cvs.push(*app_types)
      end
      cvs
    end

    # returns an array with x, y pairs in the correct order
    # accounts for scan_pattern, scan_type, linescan_direction,
    # linescan_sequence and shots_per_position
    def x_y_positions(config)
      (scan_pattern, scan_type, scan_direction, scan_sequence, shots_per_pos) = config.values_at(:scan_pattern, :scan_type, :linescan_direction, :linescan_sequence, :shots_per_position).map(&:to_s)
      shots_per_pos = shots_per_pos.to_i
      #puts "EXAMIN ARGS: "
      #p [ scan_pattern, scan_type, scan_direction, scan_sequence, shots_per_pos, shots_per_pos]

      # the true dimensions we need to work off come from the pixel dimensions.
      (slen, plen) = config[:max_dimensions_pixels].split(/x/i).map(&:to_i)

      flip = (scan_type == 'vertical')
      plen, slen = slen, plen if flip

      pindices = (1..plen).to_a  # mindices if linescan_direction is 'horizontal'
      sindices = (1..slen).to_a  # nindices if linescan_direction is 'horizontal'

      if flip
        sindices.reverse! if scan_direction == 'bottom-top' || scan_direction == 'right-left'
        pindices.reverse! if scan_sequence == 'right-left' || scan_sequence == 'bottom-top'
      end

      indices = pindices.map do |a|
        row = sindices.map do |b|
          flip ? [a,b] : [b,a]
        end
        sindices.reverse! if scan_pattern == 'meandering'
        row
      end.flatten(1)

      indices.map {|pair| shots_per_pos.times.map { pair } }.flatten(1)
    end

    def create_file_description(source_files, config)
      Mspire::Mzml::FileDescription.new  do |fd|

        fd.file_content = Mspire::Mzml::FileContent.new :params => [
          'MS:1000579', # MS1 Spectrum
          config[:profile] ? 'MS:1000128' : 'MS:1000127',
          ['IMS:1000080', "{"+config[:uuid_hyphenated]+"}"],
          ['IMS:1000091', config[:ibd_sha1]],
          (config[:data_structure] == :processed) ? 'IMS:1000031' : 'IMS:1000030',
        ]

        fd.source_files.replace(source_files)
        if [:name, :organization, :address, :email].any? {|key| config[key] }
          contact = Mspire::Mzml::Contact.new
          [ [:name, 'MS:1000586'], 
            [:organization, 'MS:1000590'],
            [:address, 'MS:1000587'],
            [:email, 'MS:1000589']
          ].each do |key, accession|
            contact.describe!(accession, config[key]) if config[key]
          end
          fd.contacts << contact
        end
      end
    end

    def create_referenceable_params_by_id_hash
      # m/z array and no compression (because we'll ref peaks in different
      # file)
      rparms = {
        :mz_array => [
          ["MS:1000514", "MS:1000040"], # m/z array, units = m/z
          "MS:1000576",                 # no compression
          ["IMS:1000101", true],        # external data
          'MS:1000523'                  # 64-bit float
      ],
        :intensity_array =>  [
          ["MS:1000515", "MS:1000131"], # intensity array, units = number of counts
          "MS:1000576",                 # no compression
          ["IMS:1000101", true],        # external data
          'MS:1000521'                  # 32-bit float
      ],
        :scan1 => [
          # this should probably be ascertained from the mzml file:
          "MS:1000093", # increasing m/z scan
          # "MS:1000095" # linear  # <- this should probably be gathered
          # from mzml (leave outfor now)
          # could include the filter string here in future
      ],
      :spectrum1 => [
        "MS:1000579", # MS1 spectrum
        ["MS:1000511", 1], # ms level - default implementation uses 0 but I disagree...
        "MS:1000127",  # centroid spectrum
        "MS:1000130" # <- positive scan
      ]}.map do |id, list|
        Mspire::Mzml::ReferenceableParamGroup.new id, params: list
      end
      Hash[ rparms.map {|parm| [parm.id, parm]} ]
    end

    # mzml_filenames can each be a partial or relative path
    # by default the file will write to the same directory and basename
    #
    #     contact:
    #       :name => name of the person or organization
    #       :address => address of the person or organization
    #       :url => url of person or organization
    #       :email => email of person or organization
    #       :organization => home institution of contact
    #     experiment:
    #       :solvent => the solvent used
    #       :solvent_flowrate => flowrate of the solvent (ml/min)
    #       :spray_voltage => spray voltage in kV
    #       :target_material => the material the target is made of
    #     editing:
    #       :trim_files => determines min # spectra in file and lops
    #                      off the ends of other files.
    #     general:
    #       :omit_zeros => remove zero values
    #       :combine => use this outfile base name to combine files
    #                   also works on single files to rename them.
    #                   MUST be present if more than one mzml given.
    #     imaging:
    #       :data_structure => :processed or :continuous  
    #       :scan_pattern => meandering random flyback
    #       :scan_type => horizontal or vertical
    #       :linescan_direction => scan_direction.join('|')
    #       :linescan_sequence => scan_sequence.join('|')
    #       :max_dimensions_pixels => maximum X by Y pixels (e.g. 300x100)
    #       :shots_per_position => number of spectra per position
    #       :pixel_size => X by Y of a single pixel in microns (μm)
    #       :max_dimensions_microns => maximum X by Y in microns (e.g. 25x20)
    def write(mzml_filenames, config={})

      base = config[:combine] || mzml_filenames.first.chomp(File.extname(mzml_filenames.first))
      config[:imzml_filename] = base + ".imzML"
      config[:ibd_filename] = base + ".ibd"

      uuid_with_hyphens = UUID.new.generate
      config[:uuid_hyphenated] = uuid_with_hyphens
      config[:uuid] = uuid_with_hyphens.gsub('-','')

      if config[:trim_files]
        config[:trim_to] = mzml_filenames.map(&:size).min
      end

      sourcefile_id_parallel_to_spectra = []
      sourcefile_ids = []
      all_spectra_iter = Enumerator.new do |yielder|
        mzml_filenames.each_with_index do |mzml_filename,i|
          sourcefile_id = "source_file_#{i}"
          sourcefile_ids << sourcefile_id
          Mspire::Mzml.open(mzml_filename) do |mzml|
            mzml.each_with_index do |spec,i| 
              break if config[:trim_to] && (i >= config[:trim_to])
              sourcefile_id_parallel_to_spectra << sourcefile_id 
              yielder << spec
            end
          end
        end
      end

      data_info_pairs = write_binary(config[:ibd_filename], all_spectra_iter, config)
      xy_positions_array = x_y_positions(config)

      unless data_info_pairs.size == xy_positions_array.size
        STDERR.puts "Input Error! The number of calculated scans must equal the number of actual scans!" 
        STDERR.puts "The number of calculated positions: #{xy_positions_array.size}"
        STDERR.puts "The number of actual scans: #{data_info_pairs.size}"
        raise
      end

      config[:ibd_sha1] = Digest::SHA1.hexdigest(IO.read(config[:ibd_filename]))

      source_files = mzml_filenames.zip(sourcefile_ids).map do |mzml_filename, source_file_id|
        sfile = Mspire::Mzml::SourceFile[ mzml_filename ]
        sfile.id = source_file_id
        sfile.describe! 'MS:1000584'
        sfile.describe! 'MS:1000569', Digest::SHA1.hexdigest(IO.read(mzml_filename))
        sfile
      end
      sourcefile_id_to_sourcefile = Hash[ source_files.group_by(&:id).map {|k,v| [k,v.first] } ]

      imzml_obj = Mspire::Mzml.new do |imzml|
        imzml.id = UUID.new.generate.gsub('-','')
        imzml.cvs = Mspire::Mzml::CV::DEFAULT_CVS

        imzml.file_description = create_file_description(source_files, config)

        rparms_by_id = create_referenceable_params_by_id_hash

        warn "using positive scan in every case but need to get this from original mzml!"

        imzml.referenceable_param_groups = rparms_by_id.values
        # skip sample list for now
        mspire_software = Mspire::Mzml::Software.new( "mspire", Mspire::VERSION, params: ["MS:1000799"] )
        imzml.software_list << mspire_software

        scan_setting_params = image_hash_to_cvs( config )
        scan_setting_params.push *experiment_hash_to_cvs( config )
        imzml.scan_settings_list = [Mspire::Mzml::ScanSettings.new("scansettings1", params: scan_setting_params)]

        warn 'todo: need to borrow instrumentConfiguration from original mzml'

        default_instrument_config = Mspire::Mzml::InstrumentConfiguration.new("borrow_from_mzml")
        warn 'todo: need to include default softare from mzml in default_instrument_config'
        #default_instrument_config.software = Software.new( from the mzml file! )
        imzml.instrument_configurations << default_instrument_config

        # this is a generic 'file format conversion' but its the closest we
        # have for mzml to imzml (which is really mzml to mzml)
        data_processing_obj = Mspire::Mzml::DataProcessing.new('mzml_to_imzml')
        data_processing_obj.processing_methods << Mspire::Mzml::ProcessingMethod.new(1, mspire_software, params: ['MS:1000530'] )
        imzml.data_processing_list << data_processing_obj

        warn "not implemented 'omit_zeros' yet"
        # low intensity data point removal: "MS:1000594"
        imzml.run = Mspire::Mzml::Run.new("run1", default_instrument_config) do |run|
          spec_list = Mspire::Mzml::SpectrumList.new(data_processing_obj)
          data_info_pairs.zip(xy_positions_array, sourcefile_id_parallel_to_spectra).each_with_index do |(pair, xy, sourcefile_id),i|
            # TODO: we should probably copy the id from the orig mzml (e.g.
            # scan=1)
            spectrum = Mspire::Mzml::Spectrum.new("spectrum#{i}", params: [rparms_by_id[:spectrum1]])
            spectrum.source_file = sourcefile_id_to_sourcefile[sourcefile_id]
            scan_list = Mspire::Mzml::ScanList.new(params: ['MS:1000795'])  # no combination
            scan = Mspire::Mzml::Scan.new( params: [rparms_by_id[:scan1], ["IMS:1000050", xy[0]], ["IMS:1000051", xy[1]]] )
            scan.instrument_configuration = default_instrument_config
            spectrum.scan_list = (scan_list << scan)
            
            data_arrays = %w(mz intensity).zip(pair).map do |type, data_array_info|
              rparmgroup = rparms_by_id[(type + "_array").to_sym]
              data_array = Mspire::Mzml::DataArray.new
              data_array.type = type
              data_array.external = true
              data_array.describe_many! [rparmgroup, *%w(IMS:1000103 IMS:1000102 IMS:1000104).zip(data_array_info).map.to_a]
              data_array
            end
            spectrum.data_arrays = data_arrays
            spec_list << spectrum
          end
          run.spectrum_list = spec_list
        end # run
      end # imzml
      imzml_obj.to_xml(config[:imzml_filename])
    end
  end
end
