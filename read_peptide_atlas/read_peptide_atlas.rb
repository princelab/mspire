#!/usr/bin/ruby

require 'yaml'
require 'open-uri'
require 'ms/msrun'
require 'optparse'
require 'ms/parser/mzxml'

PeptideAtlasRepositoryURL = "http://www.peptideatlas.org/repository/"


# returns a hash of url for groups of mzXML files and the .tgz file they
# should be output into
def get_mzxml_url_to_file_hash(url)
  url_to_file = {}

  html = open(url) {|fh| fh.read }
  regexp = '<a href="(http\:\/\/db\.systemsbiology\.net\/webapps\/repository/sForm\?expTagAndReqFile\=PAe000245\:mzXML_format)">mzXML_format<\/a>'
  html.scan(/http:\/\/db\.systemsbiology\.net.*?expTagAndReqFile=.*?:mzXML_format/) do |mtch|
    file_base = mtch.match(/expTagAndReqFile=(.*?):mzXML/)[1]
    file = file_base + '.tgz'
    url_to_file[mtch] = file
  end
  url_to_file
end


# returns a hash with scan num, first peak and last peak
def scan_hash(scan)
  hash = {}
  hash['num'] = scan.num 
  hash['first_peak'] = [scan.spectrum.mzs.first, scan.spectrum.intensities.first]
  hash['last_peak'] = [scan.spectrum.mzs.last, scan.spectrum.intensities.last]
  hash
end



opt = {}
opts = OptionParser.new do |op|
  op.banner = "usage: #{File.basename(__FILE__)} all,fl not,string,io_bad,io_good"
  op.separator "reads every mzXML file on PeptideAtlas and writes information"
  op.on('-d', "--download", 'downloads fresh links into yml file') {|v| opt[:download] = v }
  op.on('-l', "--limit <MB>", Float, "megabyte file limit for using no lazy eval") {|v| opt[:limit] = v * 1_048_576 }
  op.on("--match <regexp>", "regexp to match for filename") {|v| opt[:match] = Regexp.new(v) }
  op.on("--disk", "read set from dir on disk if possible") {|v| opt[:disk] = v }
end

opts.parse!

URL_LINKS_FILE = "peptide_atlas_url_to_file.yaml"
if opt[:download]
  url_to_file = get_mzxml_url_to_file_hash(PeptideAtlasRepositoryURL)
  File.open(URL_LINKS_FILE, 'w') {|fh| fh.print(url_to_file.sort.to_yaml) }
  puts "Wrote #{url_to_file.size} url links to: #{URL_LINKS_FILE}"
  abort 'exiting... [rerun without -d flag now]'
end


if ARGV.size != 2
  puts opts.to_s
 exit
end


abort "you need to run with -d option to get url links" if !File.exist?(URL_LINKS_FILE)
url_to_file = YAML.load_file(URL_LINKS_FILE)

(str, lts) = ARGV
scans_to_read_ar = str.split(',')
lazy_types = lts.split(',').map do |lazy_t|
  lazy_t.to_sym
end

if opt[:match]
  url_to_file = url_to_file.select {|v| v.last =~ opt[:match] }
end

url_to_file.each do |url, file|
  base = file.sub /\.tgz$/, ''

  have_dir_on_disk = opt[:disk] && File.exist?(base)

  if have_dir_on_disk
    puts "have #{base} on disk!"
  else
    error_reading = false
    print "Downloading #{file}" ; $stdout.flush 
    open(url) do |fh| 
      File.open(file,'wb') do |out| 
        while !fh.eof? do
          out.print( fh.read(16384) )
        end
      end
    end
    puts "...done!" ; $stdout.flush 
  end

  unless have_dir_on_disk
    `rm -rf #{base}`
    `mkdir #{base}`
    `mv #{file} #{base}`
  end
  Dir.chdir(base) do |base_dir|
    puts "made and working in '#{base}' directory"
    unless have_dir_on_disk
      `tar -xzf #{file}`
      `rm #{file}`
    end
    all_files = Dir["*.*"]
    mzXML_files = Dir["*.*"].select {|f| f =~ /\.mzxml$/i }

    File.open('../' + base + '.status', 'w') do |fh| 
      fh.puts "#{all_files.size} files"
      fh.puts "#{mzXML_files.size} mzXML files"
      fh.puts "files: #{all_files.join(", ")}"
      fh.puts "mzXML files: #{mzXML_files.join(", ")}"
    end

    scans_to_read_ar.each do |scans_to_read|
      lazy_types.each do |lazy_type|
        File.open("../" + base + "_#{scans_to_read}" + "_#{lazy_type}"+ '.yml', 'w') do |fh|
          mzXML_files.each do |mzXML|
            base_mzxml = mzXML.sub(/\.mzxml$/, '')
            hash = {}
            hash['file_size'] = File.size(mzXML)
            hash['file'] = mzXML
            if opt[:limit] && lazy_type == :not && hash['file_size'] > opt[:limit]
              puts "skipping: #{mzXML} since #{hash['file_size']} > #{opt[:limit]} bytes"
              hash['limit'] = opt[:limit]
            else  # within file limit tolerance
              read_start_time = Time.now
              mzXML_io = File.open(mzXML)
              begin
                use_lazy_type =
                  if lazy_type.to_s =~ /io/
                    lazy_type.to_s.split('_').first.to_sym
                  else
                    lazy_type
                  end
                ms = MS::MSRun.new(mzXML_io, :lazy => use_lazy_type)
                hash['scans_to_read'] = scans_to_read
                hash['lazy_type'] = lazy_type
                hash['time_to_read'] = Time.now - read_start_time
                hash['start_time'] = ms.start_time
                hash['end_time'] = ms.end_time
                hash['scan_count'] = ms.scan_count
                start_time_to_access = Time.now
                case scans_to_read
                when 'all'
                  ms.scans.each do |scan|
                    spec = scan.spectrum
                    if lazy_type == :io_good
                      (mz_ar, intensity_ar) = spec.mzs_and_intensities
                      mz_ar.first
                      intensity_ar.first
                    elsif lazy_type == :io_bad
                      spec.mzs.first
                      spec.intensities.first
                    else
                      spec.mzs.first
                      spec.intensities.first
                    end
                  end
                when 'fl'
                  hash['first_scan'] = scan_hash(ms.scans.first)
                  hash['last_scan'] = scan_hash(ms.scans.last)
                end
                hash['time_to_access'] = Time.now - start_time_to_access
                hash['total_time_to_read_and_access'] = Time.now - read_start_time
              rescue
                hash['error'] = $!
                error_reading = mzXML
                File.open("../" + base + "_#{mzXML}.error",'w') {|err| err.puts $! }
              end
              mzXML_io.close
            end
            fh.print [hash].to_yaml
          end
        end
      end
    end
  end
  puts "finished reading #{file}"
  if error_reading
    puts "Error reading: #{file} :: #{error_reading}"
  else
    `rm -rf #{base}`
  end
end


