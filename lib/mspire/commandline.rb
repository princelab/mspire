require 'trollop'
require 'mspire/imzml/writer/commandline'

module Mspire
  module Commandline
    SUB_COMMANDS = {
      to_imzml: 'convert mzml to imzml',
    }

    def self.run(argv)

      parser = Trollop::Parser.new do
        banner "usage: mspire <subcommand> [OPTIONS]"
        text ""
        text "subcommands: "
        SUB_COMMANDS.each do |k,v|
          text "  #{k}  #{v}"
        end
        text ""
        stop_on SUB_COMMANDS.keys.map(&:to_s)
      end

      begin 
        global_opts = parser.parse(argv)
      rescue Trollop::HelpNeeded
        parser.educate && exit 
      end

      parser.educate && exit unless argv.size > 0

      cmd = argv.shift
      cmd_parser = 
        case cmd.to_sym
        when :to_imzml
          Mspire::Imzml::Writer::Commandline.run(argv, global_opts)
        end
    end
  end
end
