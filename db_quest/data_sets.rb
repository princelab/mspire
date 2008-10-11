require 'generator'
require 'vec'
require 'facets/enumerable/each_by'
require 'yaml'
require 'hash_by'


# class for extracting information out of the file label (dumb, yes)
class DSLabel < String

  def argerr
    raise ArgumentError("bad string: #{self}")
  end

  # returns an array that can be used as a hash key
  # (doesn't include inclue_deltacn)
  def hash_key
    [include_deltacn?, hash_type, shuffle_type, cat_type, hits_separate?]
  end

  # reflects the hash_key info
  def self.hash_key_labels
    %w(include_deltacn hash_type shuffle_type cat_type hits_separate)
  end

  def include_deltacn?
    if self =~ /dcn-t/
      true
    elsif self =~ /dcn-f/
      false
    else ; argerr
    end
  end
  # returns 'a', 'ac, or 's'
  def hash_type
    if self =~ /-a$/
      'a'
    elsif self =~ /-ac$/
      'ac'
    elsif self =~ /-s$/
      's'
    else ; argerr
    end
  end
  # returns string: inv shuff or normal
  def shuffle_type
    if self =~ /inv_/
      'inv'
    elsif self =~ /shuff_/
      'shuff'
    elsif self =~ /normal_/
      'normal'
    else ; argerr
    end
  end
  # returns cat or sep
  def cat_type
    if self =~ /_cat/
      'cat'
    elsif self =~ /_sep[^a]/
      'sep'
    elsif self =~ /normal/
      'normal'
    else ; argerr
    end
  end
  # returns true or false
  def hits_separate?
    if self =~ /hits_separate/
      true
    else
      false
    end
  end
end

class DataSet 
  attr_accessor :xdata, :ydata, :label, :tp

  def initialize(xdata=[], ydata=[], val_hash=nil)
    if val_hash
      @label = get_label(val_hash)
      @tp = val_hash[:type]
    end
    @xdata = xdata
    @ydata = ydata
    if block_given?
      yield(self)
    end
  end

  # takes that many data points and averages them
  # plots the average x value of the group
  def avg_points!(number)
    (newxdata, newydata) = [xdata, ydata].map do |st|
      avgs = []
      st.each_by(number) {|v| avgs.push( v.inject(0.0) {|sum,obj| sum + obj}/v.size )}
      avgs
    end
    @xdata = newxdata ; @ydata = newydata
    self
  end

  # sorts by x and then y (maintains x/y relationship)
  # returns self
  def sort_by_x!
    sorted_doublets = xdata.zip(ydata).map do |x,y|
      [x,y]
    end.sort
    sorted_doublets.each_with_index do |doublet, i|
      @xdata[i] = doublet[0]
      @ydata[i] = doublet[1]
    end
    self
  end

  # takes the max yvalue in that range of x axis values... takes the x value at that
  # max y
  # returns self
  def max_in_points!(number)
    hashed_by_x = xdata.zip(ydata).hash_by {|couple| couple[0] }
    max_x = hashed_by_x.keys.sort.last

    iterations = max_x / number
    max_per_group = []
    (iterations+1).times do |i|
      start_i = i * number
      end_i = (i+1) * number ## exclusive
      this_group = []
      (start_i...end_i).each do |num_hits|
        if hashed_by_x.key? num_hits
          this_group.push( *(hashed_by_x[num_hits]) )
        end
      end
      max_per_group.push( this_group.sort_by {|couple| couple.reverse }.last )  # sorting by [y,x]
    end

    new_xs = []
    new_ys = []
    max_per_group.compact.each do |couple|
      new_xs << couple[0]
      new_ys << couple[1]
    end
    
    @xdata = new_xs
    @ydata = new_ys
    self
  end

  def to_plot(fh)
    fh.puts @label 
    if @xdata
      fh.puts @xdata.join(" ")
    else
      fh.puts((0..(@ydata.size)).to_a.join(" "))
    end
    fh.puts @ydata.join(" ")
  end

  def get_label(validator_hash)
    vh = validator_hash
    case vh[:type]  
    when 'badAA'
      'cysteine (dig)'
    when 'badAAEst'
      'cysteine (est)'
    when 'tmm'
      if vh[:transmem_file] =~ /phobius/
        'tmm (phobius)'
      else
        'tmm (toppred)'
      end
    when 'bias'
      if vh[:file] =~ /mrna/i
        'bias (mRNA)'
      else
        'bias (prot)'
      end
    when 'prob'
      if vh[:prob_method] == :initial_probability
        'prob (init)'
      else
        'prob (nsp)'
      end
    else
      vh[:type]
    end
  end
end


class DataSets < Array

  def self.background_datasets_from_prob_file(file)
    struct = YAML.load_file(file)
    prec_arrays = struct[:pephits_precision].map {|v| v[:values] }
    
    xaxis_data = (0...(prec_arrays.first.size)).to_a

    data_sets = struct[:params][:validators].zip( prec_arrays ).map do |validator, prec_ar|
      DataSet.new(xaxis_data, validator[:calculated_backgrounds], validator)
    end

    self.new(data_sets)
  end

  # factors out num_hits and prints out a csv style document that can be
  # loaded into R with this cmd:
  #
  #     read.table("filename", sep="\t", header=TRUE))
  #
  # assumes all datasets have the same length.  First dataset is used for the
  # numhits.
  # prob, decoy, qval datasets are put last in order
  def to_r(filename)
    self.put_last {|v| v.tp =~ /prob|qval/}
    self.put_last {|v| v.tp =~ /decoy/}
    # R wants the first row to be header-less and just be the row #
    File.open(filename, 'w') do |out|
      headers = self.map {|v| v.label.gsub(/[\(\) _]/,'.').gsub(/\.+/,'.').sub(/\.$/,'') }
      headers.unshift('numhits')  # the blank column
      out.puts( headers.join("\t") )
      (0...(self.first.ydata.size)).each do |i|
        ar = self.map {|v| v.ydata[i]}
        ar.unshift(self.first.xdata[i])
        out.puts( ar.join("\t") )
      end
    end
  end


  def single_badAA!(new_label=nil)
    # use only one of the cys ones:
    v.tp = new_name
    v.label = v.tp
    new_ds
    index = nil
    self.each_with_index {|v,i| index = i if v.tp == 'badAA' }
    self.delete_at(index)
    if new_label
      self.each {|v,i| v.label = new_label if v.tp == 'badAA' }
    end
  end

  def to_csv(file, delim="\t")
    cols = []
    self.each do |ds|
      if ds.xdata
        cols << ds.xdata.dup.unshift("(x) #{ds.label}")
      end
      cols << ds.ydata.dup.unshift("(y) #{ds.label}")
    end
    File.open(file, 'w') do |out|
      SyncEnumerator.new(*cols).each do |row|
        out.puts(row.join(delim))
      end
    end
  end

  def print_to_plot(header_hash)
    File.open(header_hash[:file] + '.to_plot', 'w') do |out|
      %w(type file title xaxis yaxis).each do |heading|
        out.puts(header_hash[heading.to_sym])
      end
      to_plot(out)
    end
  end

  # loads the calculated background
  def self.load_backgrounds_from_filter_file(filename)

    data_sets = nil
    x_vals = []
    File.open( filename ) do |fh|
      num_docs = 0
      YAML.load_documents( fh ) do |ydoc|

        data_sets or data_sets = DataSets.new( ydoc['params']['validators'].map {|val_hash| DataSet.new([], [], val_hash) } )

        ydoc['params']['validators'].zip(data_sets) do |val_hash, data_set|  
          data_set.ydata << val_hash[:calculated_background]
        end

        num_docs += 1
      end
      x_vals = (0...num_docs).to_a 
    end
    data_sets.each {|ds| ds.xdata = x_vals }
    data_sets
  end

  # removes the decoy dataset and plots each less decoy yvalues
  def less_decoy!
    (decoy, others) = self.partition {|v| v.tp == 'decoy'}
    self.replace(others)
    dec_ds = decoy.first
    if dec_ds
      self.each do |ds|
        new_vals = []
        dec_ds.ydata.zip(ds.ydata) do |dec,other|
          new_vals << (other - dec)
        end
        ds.ydata = new_vals
      end
    end
  end

  ## returns (DataSets [y values to each validator, x values to num_hits], hash of arrays of sequest param values, num_hits ar)
  def self.load_filter_file(filename)
    ## These are the three things we'll track:
    dsets = DataSets.new
    sequest_params = {}
    num_hits = []
    File.open( filename ) do |fh|
      num_docs = 0
      YAML.load_documents( fh ) do |ydoc|
        ydoc['params']['validators'].each do |val|
          dsets << DataSet.new([],[],val) 
        end
        ydoc['params']['sequest'].keys.each do |key|
          sequest_params[key] = []
        end
        fh.rewind
        break
      end
      ## load up the datasets
      YAML.load_documents( fh ) do |ydoc|
        ydoc['pephits_precision'].each_with_index do |val,i|
          dsets[i].ydata << val['value']
        end
        ydoc['params']['sequest'].each do |k,v|
          sequest_params[k] << v
        end
        num_hits << ydoc['pephits']
      end
    end
    dsets.each do |ds|
      ds.xdata = num_hits
    end
    [dsets, sequest_params, num_hits]
  end

  # num_hits means that the xaxis will be the number of hits passing threshold
  # DEPRECATED!!!!! here for backwards junk
  # use load_filter_file
  def self.load_from_filter_file(filename, opt)
    (by_sequest_att, num_hits) = opt.values_at(:by_sequest_att, :num_hits)

    data_sets = nil
    x_vals = []
    num_hits_ar = []
    File.open( filename ) do |fh|
      num_docs = 0
      YAML.load_documents( fh ) do |ydoc|

        data_sets or data_sets = DataSets.new( ydoc['params']['validators'].map {|val_hash| DataSet.new([], [], val_hash) } )

        ydoc['pephits_precision'].zip(data_sets) do |lil_val_hash, ds|
          ds.ydata.push( lil_val_hash['value'] )
        end

        if num_hits
          num_hits_ar << ydoc['pephits']
        end

        if by_sequest_att 
          x_vals << ydoc['params']['sequest'][by_sequest_att]
        end
        num_docs += 1
      end
      if !by_sequest_att
        x_vals = (0...num_docs).to_a 
      end
    end
    if num_hits
      x_vals = num_hits_ar
    end
    data_sets.each {|ds| ds.xdata = x_vals }
    if opt[:minus_decoy]
      data_sets.less_decoy! 
    end
    data_sets
  end

  
  # creates a file: <file>(.csv) with columns: [precision num_hits xcorr1 xcorr2 xcorr3
  # dcn ppm] tab separated
  def self.file_to_csv(filename)
    data_sets = nil
    base = filename.sub(/\.yaml$/,'')
    newfile = base + '.csv'
    File.open(newfile, 'w') do |out|
      sequest_params = %w(xcorr1 xcorr2 xcorr3 deltacn ppm)
      params_ars = {}
      sequest_params.each do |par|
        params_ars[par] = []
      end

      num_hits_ar = []
      File.open( filename ) do |fh|
        YAML.load_documents( fh ) do |ydoc|

          data_sets or data_sets = DataSets.new( ydoc['params']['validators'].map {|val_hash| DataSet.new([], [], val_hash) } )

          ydoc['pephits_precision'].zip(data_sets) do |lil_val_hash, ds|
            ds.ydata.push( lil_val_hash['value'] )
          end

          num_hits_ar << ydoc['pephits']

          sequest_params.each do |par|
            params_ars[par] << ydoc['params']['sequest'][par]
          end
        end
      end
      #data_sets.each {|ds| ds.xdata = x_vals }
      # print columns:
      data_vals = [num_hits_ar]
      col_headings = ['num_hits']
      data_sets.each do |ds|
        col_headings << ds.label 
        data_vals << ds.ydata
      end
      sequest_params.each do |par|
        col_headings << par
        data_vals << params_ars[par]
      end
      out.puts col_headings.join("\t")
      
      SyncEnumerator.new(*data_vals).each do |row|
        out.puts row.join("\t")
      end
    end
  end



  def put_first(&block)
    put_somewhere(:unshift, &block)
  end

  def put_last(&block)
    put_somewhere(:push, &block)
  end

  def put_somewhere(where, &block)
    matching = self.select(&block)
    if matching.size >= 1
      matching.each {|v| self.delete(v) }
      self.send(where, *matching)
    end
  end

  def to_plot(fh)
    self.each do |ds|
      ds.to_plot(fh)
    end
  end

  # returns a single data set that contains two arrays of data for the ydata:
  # mean and stdev
  # (takes x data from first data set)
  def average_stdev(label=nil, &block)
    sets_to_average = self.select(&block)
    
    xdata = sets_to_average.first.xdata
    
    ds = DataSet.new(xdata, nil)
    ds.label = label || 'errorbars'
    ds.tp = 'errorbars'

    avgs = []
    stdevs = []

    ydatas = sets_to_average.map {|ds| ds.ydata }
    SyncEnumerator.new(*ydatas).each do |col|
      (mean, stdv) = VecD.new(col).sample_stats
      avgs.push(mean)
      stdevs.push(stdv)
    end
    ds.ydata = [avgs, stdevs]
    ds
  end
  
  # the block selects the whatever
  def average(new_name=nil, &block)
    to_average = self.select(&block)

    if to_average.size > 1

      ydatas = to_average.map {|ds| ds.ydata }
      avgs = SyncEnumerator.new(*ydatas).inject([]) do |sum_ar, col|
        avg = (col.inject(0.0) {|sum,v| sum + v })/col.size 
        sum_ar.push(avg) 
      end

      to_average.each {|v| self.delete(v) }
      first_guy = to_average.first
      new_ds = DataSet.new( first_guy.xdata, avgs) do |v| 
        v.tp = first_guy.tp
        if new_name
          v.label = new_name
          v.tp = new_name
        else
          v.label = v.tp
        end
      end
      self.push( new_ds )
    end
  end

  # takes x data from first guy
  def average_to_new_ds(new_name='avg', &block)
    to_average = self.select(&block)
    new_ds = nil
    if to_average.size > 1

      ydatas = to_average.map {|ds| ds.ydata }
      avgs = SyncEnumerator.new(*ydatas).inject([]) do |sum_ar, col|
        avg = (col.inject(0.0) {|sum,v| sum + v })/col.size 
        sum_ar.push(avg) 
      end

      first_guy = to_average.first
      new_ds = DataSet.new( first_guy.xdata, avgs) do |v| 
        v.tp = new_name
        v.label = v.tp
      end
    end
    new_ds
  end

end

