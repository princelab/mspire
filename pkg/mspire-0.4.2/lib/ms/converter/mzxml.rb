
module MS ; end
module MS::Converter ; end
module MS::Converter::MzXML
  Potential_mzxml_converters = %w(readw.exe readw t2x)

  # takes PT2.7500000S and returns it as 2.700000 (no PT or S)
  #def strip_time(time)
  #  return time[2...-1]
  #end

   # first, converts backslash to forward slash in filename.
  # if .mzXML returns the filename
  # if .raw or .RAW converts the file to .mZXML and returns mzXML filename
  # if no recognized extension, looks for .mzXML file, then .RAW file (and
  # converts)
  # aborts if file was not able to be converted
  # returns nil if a file that can be converted or used was not found
  def self.file_to_mzxml(file)
    file.gsub!("\\",'/')
    old_file = file.dup
    if file =~ /\.mzXML$/
      return file
    elsif file =~ /\.RAW$/i
      old_file = file.dup
      ## t2x outputs in cwd (so go to the directory of the file!)
      dir = File.dirname(file)
      basename = File.basename(file)
      converter = MS::MzXML.find_mzxml_converter
      Dir.chdir(dir) do 
        if converter =~ /readw/
          cmd = "#{converter} #{basename} c #{basename.sub(/\.RAW$/i, '.mzXML')}"
        else
          cmd = "#{converter} #{basename}"
        end
        #puts cmd
        #puts `#{cmd}`
        reply = `#{cmd}`
        puts reply if $VERBOSE
      end
      file.sub!(/\.RAW$/i, '.mzXML')
      unless File.exist? file
        abort "Couldn't convert #{old_file} to #{file}"
      end
      return file
    else 
      if File.exist?( file + '.mzXML' )
        return file_to_mzxml(file + '.mzXML')
      elsif File.exist?( file + '.RAW' )
        return file_to_mzxml(file + '.RAW')
      elsif File.exist?( file + '.raw' )
        return file_to_mzxml(file + '.raw')
      else
        return nil
      end
    end
      
  end


  # Searchs each path element and returns the first one it finds
  # returns nil if none found
  def self.find_mzxml_converter
    ENV['PATH'].split(/[:;]/).each do |path|
      Dir.chdir(path) do
        Potential_mzxml_converters.each do |pc|
          if File.exist? pc
            return File.join(path, pc)
          end
        end
      end
    end
    nil
  end
 
end

