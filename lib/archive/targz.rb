

require 'archive/tar/minitar'

require 'stringio'

module Archive::Tar::Minitar

  # entry may be a string (the name), or it may be a hash specifying the
  # following: 
  #   :name    (REQUIRED)
  #   :mode    33188 (rw-r--r--) for files, 16877 (rwxr-xr-x) for dirs
  #           (0O100644)                   (0O40755)
  #   :uid    nil
  #   :gid    nil
  #   :mtime  Time.now
  #
  # if data == nil, then this is considered a directory!
  # (use an empty string for a normal empty file)
  # data should be something that can be opened by StringIO
  def self.pack_as_file(entry, data, outputter) #:yields action, name, stats:
    outputter = outputter.tar if outputter.kind_of?(Archive::Tar::Minitar::Output)

    stats = {}
    stats[:uid] = nil
    stats[:gid] = nil
    stats[:mtime] = Time.now

    if data.nil?
      # a directory
      stats[:size] = 4096   # is this OK???
      stats[:mode] = 16877  # rwxr-xr-x
    else
      stats[:size] = data.size
      stats[:mode] = 33188  # rw-r--r--
    end

    if entry.kind_of?(Hash)
      name = entry[:name]

      entry.each { |kk, vv| stats[kk] = vv unless vv.nil? }
    else
      name = entry
    end
    
    if data.nil?  # a directory
      yield :dir, name, stats if block_given?
      outputter.mkdir(name, stats)
    else          # a file
      outputter.add_file_simple(name, stats) do |os|
        stats[:current] = 0
        yield :file_start, name, stats if block_given?
        StringIO.open(data, "rb") do |ff|
          until ff.eof?
            stats[:currinc] = os.write(ff.read(4096))
            stats[:current] += stats[:currinc]
            yield :file_progress, name, stats if block_given?
          end
        end
        yield :file_done, name, stats if block_given?
      end
    end
  end
end


require 'zlib'
file_names = ['wiley/dorky1', 'dorky2', 'an_empty_dir']
file_data_strings = ['my data', 'my data also', nil]


module Archive ; end

# usage:
#     require 'archive/targz'
#     Archive::Targz.archive_as_files("myarchive.tgz", %w(file1 file2 dir),
#          ['data for file1', 'data for file2', nil])
module Archive::Targz
  # requires an archive_name (e.g., myarchive.tgz) and parallel filename and
  # data arrays:
  #     filenames = %w(file1 file2 empty_dir)
  #     data_ar = ['stuff in file 1', 'stuff in file2', nil]
  # nil as an entry in the data_ar means that an empty directory will be
  # created
  def self.archive_as_files(archive_name, filenames=[], data_ar=[])
    Zlib::GzipWriter.open(File.open(archive_name, 'wb')) do |tgz|

      Archive::Tar::Minitar::Output.open(tgz) do |outp|
        filenames.zip(data_ar) do |name, data|
          Archive::Tar::Minitar.pack_as_file(name, data, outp)
        end
      end
    end
  end
end
