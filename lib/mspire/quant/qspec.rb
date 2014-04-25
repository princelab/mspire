module Mspire ; end
module Mspire::Quant ; end

class Mspire::Quant::Qspec
  # This is my current best guess based on the behavior of the original QSpec
  # and going into the source code and looking at the paired and param
  # versions.
  
  # qspec: discrete spectral count data
  # qprot: continuous protein abundance data (could be non-discrete spectral
  # counts or quantitation data)
  # paired: one sample against another sample
  # param: one sample against another sample but with one or more replicates
  EXE = {
    qspec: {
      paired: 'qspec-paired',  # <- the old qspec (use qspec here if you have old software)
      param: 'qspec-param',    # <  the old qspecgp (use qspecgp if you have old software)
    },
    qprot: {
      paired: 'qprot-paired',
      param: 'qprot-param',
    },
    getfdr: 'getfdr',
  }

  # personal communication with Hyungwon Choi: "We typically use nburn=2000,
  # niter=10000, which is quite sufficient to guarantee the reproducibility of
  # results using the same data."
  NBURNIN = 2000
  NITER = 10000
  INIT_HEADER = %w(protid protLen)
  DELIMITER = "\t"

  # takes an ordered list of conditions ['cond1', 'cond1', 'cond2', 'cond2'] and
  # returns an array of ints [0,0,0,1,1,1...]
  def self.conditions_to_ints(conditions)
    i = 0
    current_condition = conditions.first
    conditions.map do |cond| 
      if current_condition == cond ; i
      else
        i += 1
        current_condition = cond
        i
      end
    end
  end

  # returns an array of Results structs which is each row of the returned file
  # works with version 1.2.2 of Qprot
  def self.results_array(resultsfile)
    rows = IO.readlines(resultsfile).map {|line| line.chomp.split("\t") }
    headers = rows.shift
    start_log_fold = headers.index {|v| v =~ /LogFoldChange/i }
    rows.map do |row| 
      data = [row[0]]
      data.push( row[1...start_log_fold].map(&:to_f) )
      data.push( *row[start_log_fold,5].map(&:to_f) )
      Results.new(*data)
    end
  end

  # returns the right executable based on the array of conditions
  def executable
    biggest_size = conditions.group_by {|v| v }.values.map(&:size).max
    EXE[@protnames ? :qprot : :qspec][(biggest_size >= 3) ? :param : :paired]
  end

  # protname is a list of protein names.
  # by default, qprot will be run.  If you really want qspec to be run, then
  # supply a [protname, length] doublet in place of each protname.
  # condition_to_count_array is an array doublets: [condition, array_of_counts]
  def initialize(protnames, condition_to_count_array)
    @protnames = protnames
    if @protnames.first.is_a?(Array)
      @protname_length_pairs = @protnames
      @protnames = nil
    end
    @condition_to_count_array = condition_to_count_array
  end

  def conditions
    @condition_to_count_array.map(&:first)
  end

  # writes a qspec formatted file to filename
  def write(filename)
    header_cats = %w(protid)
    header_cats << 'protLen' if @protname_length_pairs
    header_cats.push(*Mspire::Quant::Qspec.conditions_to_ints(conditions))
    ar = @protnames || @protname_length_pairs
    rows = ar.map {|obj| Array(obj) }
    @condition_to_count_array.each do |cond,counts|
      rows.zip(counts) {|row,cnt| row << cnt }
    end
    File.open(filename,'w') do |out|
      out.puts header_cats.join(DELIMITER)
      rows.each {|row| out.puts row.join(DELIMITER) }
    end
  end

  # returns an array of Qspec::Results objects (each object can be considered
  # a row of data)
  def run(normalize=true, opts={})
    exe = executable
    puts "using #{exe}" if $VERBOSE
    executable_base = exe.split('-')[0]

    puts "normalize: #{normalize}" if $VERBOSE
    tfile = Tempfile.new(executable_base)
    write(tfile.path)
    if opts[:keep]
      local_file = File.join(Dir.pwd,File.basename(tfile.path))
      FileUtils.cp(tfile.path, local_file, :verbose => $VERBOSE)
      puts "(copy of) file submitted to #{exe}: #{local_file}" if $VERBOSE
    end
    cmd = [exe, tfile.path, NBURNIN, NITER, (normalize ? 1 : 0)].join(' ')
    if $VERBOSE
      puts "running #{cmd}" if $VERBOSE
    else
      cmd << " 2>&1"
    end
    reply = `#{cmd}`
    puts reply if $VERBOSE
    outfile = tfile.path + '_' + executable_base
    system EXE[:getfdr], outfile
    fdr_file = outfile + "_fdr"
    puts "FDR_FILE: #{fdr_file} exists? #{fdr_file}" if $VERBOSE
    results = self.class.results_array(fdr_file)
    if opts[:keep]
      local_outfile = File.join(Dir.pwd, File.basename(outfile))
      local_fdrfile = File.join(Dir.pwd, File.basename(fdr_file))
      FileUtils.cp(outfile, local_outfile, :verbose => $VERBOSE)
      FileUtils.cp(fdr_file, local_fdrfile, :verbose => $VERBOSE)
      if $VERBOSE
        puts "(copy of) file returned from qspec: #{outfile}"
        puts "(copy of) file returned from qspec: #{fdr_file}"
      end
    end
    tfile.unlink
    results
  end

  # for version 2 of QSpec
  # counts array is parallel to the experiment names passed in originally
  #Results = Struct.new(:protid, :counts_array, :bayes_factor, :fold_change, :rb_stat, :fdr, :flag)
  
  # for version 1.2.2 of QProt
  # counts array is parallel to the experiment names passed in originally
  Results = Struct.new(:protid, :counts_array, :log_fold_change, :z_statistic, :fdr, :fdr_up, :fdr_down)
end

