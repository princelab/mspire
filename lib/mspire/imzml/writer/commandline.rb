# encoding: UTF-8

require 'mspire/imzml/writer'
require 'trollop'
require 'yaml'

module Mspire
  module Imzml
    class Writer
    end
  end
end

module Mspire::Imzml::Writer::Commandline

  # generates the Trollop parser
  def self.parser
    return @parser if @parser

    default_config = "config.yaml"
    scan_patterns = %w(flyback meandering random)
    scan_types = %w(horizontal vertical)
    scan_direction = %w(left-right right-left bottom-up top-down none)
    scan_sequence = %w(top-down bottom-up left-right right-left)
    default_dims = '800x600'
    default_pixel_size = '1x1'
    matrix_application_types = %w(sprayed precoated printed drieddroplet)

    @parser = Trollop::Parser.new do
      banner <<-EOS
usage: mspire to_imzml [OPTIONS] <file>.mzML ..."
output: <file>.imzML and <file>.ibd

* imzML docs: 
    http://www.maldi-msi.org/index.php?option=com_content&view=article&id=187&Itemid=67
* explanation of vocabulary (followed here): 
    http://www.maldi-msi.org/index.php?option=com_content&view=article&id=193&Itemid=66
* github repository:
    https://github.com/princelab/mzml_to_imzml
      EOS
      text "\ngeneral:"
      opt :config, "read a config file for default values. Command line options overide those from the config file ", :type => :string
      opt :print_config, "print current options to #{default_config} and exit"
      opt :omit_zeros, "remove zero values"
      opt :combine, "combine all files and set the base name of resulting imzML and ibd files", :type => String
      opt :outfile, "use a specific basename for the resulting file. Acts like --combine for multiple files", :type => String

      text "\nimaging:"
      opt :continuous, "assumes m/z values are the same for every scan. The 'processed' storage format is used unless this flag is given."
      opt :scan_pattern, scan_patterns.join('|'), :default => scan_patterns.first
      opt :scan_type, scan_types.join('|'), :default => scan_types.first
      opt :linescan_direction, scan_direction.join('|'), :default => scan_direction.first
      opt :linescan_sequence, scan_sequence.join('|'), :default => scan_sequence.first
      opt :max_dimensions_pixels, "maximum X by Y pixels (e.g. 300x100)", :default => default_dims
      opt :shots_per_position, "number of spectra per position", :default => 1
      opt :pixel_size, "X by Y of a single pixel in microns (μm)", :default => default_pixel_size 
      opt :max_dimensions_microns, "maximum X by Y in microns (e.g. 25x20)", :default => default_dims

      text "\ncontact: "
      opt :name, "name of the person or organization", :type => :string
      opt :address, "address of the person or organization", :type => :string
      opt :url, "url of person or organization", :type => :string
      opt :email, "email of person or organization", :type => :string
      opt :organization, "home institution of contact", :type => :string

      text "\nDESI: "
      opt :solvent, "the solvent used", :type => :string
      opt :solvent_flowrate, "flowrate of the solvent (ml/min)", :type => :float
      opt :spray_voltage, "spray voltage in kV", :type => :float
      opt :target_material, "the material the target is made of", :type => :string

      text "\nMALDI: "
      opt :matrix_application_types, "#{matrix_application_types.join('|')} (comma separated)", :type => :string
      opt :matrix_solution_concentration, "in grams per liter", :type => :float
      opt :matrix_solution, "the chemical solution used as matrix (e.g., DHB)", :type => :string

      # things to add: data types for m/z and intensity
      # filters (cutoff / max # peaks, etc.)
      # ms_level, etc.
    end
  end

  def self.run(argv, globalopts)
    begin
      opts = parser.parse(argv)
    rescue Trollop::HelpNeeded
      return parser.educate
    end

    opts = Hash[YAML.load_file(opts[:config]).map {|k,v| [k.to_sym, v]}].merge(opts) if opts[:config]

    opts[:combine] ||= opts.delete(:outfile)

    if opts.delete(:print_config)
      puts "writing defaults to: #{default_config}"
      string_opts = Hash[ opts.map {|k,v| [k.to_s, v] } ]
      %w(help).each {|key| string_opts.delete key }
      string_opts.delete_if {|k,v| k =~ /_given$/ }
      File.write(default_config, string_opts.to_yaml) 
      exit
    end

    if argv.size == 0
      return parser.educate
    end

    opts[:data_structure] = (opts.delete(:continuous) ? :continuous : :processed)
    opts[:matrix_application_types] = opts[:matrix_application_types].split(',') if opts[:matrix_application_types]

    # prep args a little
    writer = Mspire::Imzml::Writer.new
    writer.write(argv, opts)

  end
end
