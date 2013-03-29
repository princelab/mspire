require 'hash/inverse'

module Mspire ; module Quant ; end ; end

module Mspire::Quant::Cmdline

  # expects arguments in one of two forms.  The first form is grouped by
  # condition as shown:
  #
  #     condition1=file1,file2,file3... condition2=file4,file5...
  #
  # The second is where each file is its own condition (1 replicate):
  #
  #     file1 file2 file3
  #
  # Returns three ordered hashes (only ordered for ruby 1.9): 
  #
  #     1) Condition to an array of samplenames
  #     2) Samplename to the filename  
  #     3) Samplename to condition
  def self.args_to_hashes(args, replicate_postfix="-rep")
    # groupname => files
    condition_to_samplenames = {}
    samplename_to_filename = {}
    args.each do |arg|
      (condition, files) = 
        if arg.include?('=')
          (condition, filestring) = arg.split('=')
          [condition, filestring.split(',')]
        else
          [basename(arg), [arg]]
        end
      sample_to_file_pairs = files.each_with_index.map do |file,i| 
        rep_string = (files.size == 1) ? "" : "#{replicate_postfix}#{i+1}"
        ["#{condition}#{rep_string}", file] 
      end
      sample_to_file_pairs.each {|name,file| samplename_to_filename[name] = file }
      condition_to_samplenames[condition] = sample_to_file_pairs.map(&:first)
    end
    [samplename_to_filename, condition_to_samplenames, condition_to_samplenames.inverse]
  end
end
