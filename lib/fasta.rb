require 'sample_enzyme'
require 'each_index'
require 'optparse'
require 'delegate'
require 'hash_by'
require 'digest/md5'


tmp = $VERBOSE ; $VERBOSE = nil
class String

  def each_index
    (0...self.size).each do |c|
      yield c
    end
  end

  # modifies and returns self
  def shuffle!
    each_index {|j| i = rand(size-j); self[j], self[j+i] = self[j+i], self[j]}
    self
  end

  def shuffle
    out = self.dup
    out.shuffle!
    out
  end

end
$VERBOSE = tmp


module FastaManipulation ; end

class Fasta < DelegateClass(Array)
  include FastaManipulation
  SHUFF_PREFIX = "SHUFF_"
  SHUFF_FILE_POSTFIX = "_SHUFF"
  CAT_SHUFF_FILE_POSTFIX = "_CAT_SHUFF"
  FILE_CONNECTOR = "__"
  INV_PREFIX = "INV_"
  INV_FILE_POSTFIX = "_INV"
  CAT_INV_FILE_POSTFIX = "_CAT_INV"

  attr_writer :prots
  # this will probably be relative
  attr_accessor :filename

  # for backwards compatibility
  def prots
    @prots
  end

  def self.to_fasta(file_or_obj)
    if file_or_obj.is_a? Fasta
      file_or_obj
    else
      Fasta.new(file_or_obj)
    end
  end

  # arg can be:
  #   Fasta::Prot objects (Array)
  #   filename (String)
  #   Another Fasta object (Fasta) (shallow copy!)
  def initialize(arg=nil, filename=nil)
    @filename = filename
    @prots = []
    if arg 
      if arg.is_a? Fasta
        self.prots = arg.prots
        self.filename = arg.filename
      elsif arg.is_a? Array
        @prots = arg
      else
        read_file(arg)
      end
    end
    super(@prots)
  end

  # uses the filename (if available, otherwise returning nil) to grab the md5 sum of the file
  def md5_sum
    if File.exist?(@filename)
      Digest::MD5.hexdigest(File.read(@filename))
    else
      nil
    end
  end

  # returns the length of the file (in terms of the total number of amino
  # acids represented)
  def aa_seq_length
    tot = 0
    self.each do |prot|
      tot += prot.aaseq.size
    end
    tot
  end

  # searches proteins for a match to the exact sequence and returns a single
  # protein header (with > & no newline)
  # exact matches). nil if no matches
  def header_from_exact_sequence(aaseq)
    hash = self.hash_by(:aaseq)
    answ = hash[aaseq].map{|v| v.header}
    if answ.size == 1
      answ
    elsif answ.size == 0
      nil
    else
      answ
    end
  end

  # searches all headers to see if they include input string
  # returns true if one matches, false otherwise
  # (remember that headers are not stored with newline chars but do contain
  # beginning '>'
  def included_in_header?(input)
    @prots.any? do |prot|
      prot.header.include? input
    end
  end

  # takes an io object or string (which is the fasta data) This is not as
  # stringent as 'read_file' which is recommended for industrial type use. For
  # instance, this will fail if your newlines are different in your file from
  # those defined on your operating system.  If you have a string, simply pass
  # in StringIO.new(your_string) to be read.
  # returns self
  def load(io)
    current_prot = nil
    current_aaseq = nil
    @prots.clear
    io.each do |line|
      if line[0,1] == '>'
        current_prot = Prot.new
        @prots << current_prot
        current_prot.header = line.chomp
        current_aaseq = ''
        current_prot.aaseq = current_aaseq
      elsif (line =~ /[^ ]/) && (line.size > 1)
        current_aaseq << line.chomp 
      end
    end
    self
  end

  # uses 'load' to create a fasta object from a fasta string
  def self.from_string(string)
    Fasta.new.load(StringIO.new(string))
  end

  # Reads fasta files (under windows or unix newlines)
  # Always outputs LF separated files
  # Checks that the first character per line is '>' or character class [A-Za-z*]
  # returns a fasta object for stringing commands
  # if fn not given, will read the :filename attribute
  # will set :filename to fn is given
  def read_file(fn=nil)
    @filename = fn if fn
    first_char_re = /[A-Za-z*]/o
    obj = nil
    regex = /(\r\n)|\n/o
    fh = File.new(fn).binmode
    lines = fh.read.split(regex)
    fh.close
    first_char = nil
    lines.each do |line|
      if line =~ /[^ \n\r]/
        first_char = line[0,1]
        if first_char == '>'
          obj = Prot.new
          @prots << obj
          obj.header = line.dup
        elsif first_char =~ first_char_re
          obj.aaseq << line.chomp
        else
          raise "Line not in fasta format (between arrows): -->#{line}<--"
        end
      end
    end
    self
  end

  # if no fn, will write to :filename attribute
  def write_file(fn=nil)
    fn = @out unless fn
    File.open(fn, "wb") do |out|
      @prots.each do |prot|
        out.print(prot.to_s)
      end
    end
  end

  # duplicates the object (deep copy)
  def dup
    other = self.class.new
    other.filename = self.filename
    self.prots.each do |prot|
      other.prots << prot.dup
    end
    other
  end

end

class FastaShaker
 
  def reverse(fasta_file_or_obj, opts={})
    shake_it(:reverse, fasta_file_or_obj, opts)
  end

  def shuffle(fasta_file_or_obj, opts={})
    shake_it(:shuffle, fasta_file_or_obj, opts)
  end

  # sets the outbound filename attribute from opts
  def create_filename(fasta, method, opts={})
    file = fasta.filename || 'fasta'
    filebase = file.sub(/\..*$/,'')
    parts = [filebase]
    parts << 'cat' if opts[:cat]
    parts << method
    parts << 'prefix' << opts[:prefix] if opts[:prefix]
    parts << 'fraction' << opts[:fraction] if opts[:fraction]
    parts << 'tryptic_peptides' if opts[:tryptic_peptides]
    parts.join("_") << ".fasta" 
  end

  protected
  def shake_it(method, fasta_file_or_obj, opt)
    fasta = Fasta.to_fasta(fasta_file_or_obj)
    if opt[:cat] && !opt[:prefix]
      message = "WARNING: concatenated proteins don't have unique headers\n[you probably wanted to use the '--prefix' option!]"
      warn message
    end

    unless opt[:out]
      opt[:out] = create_filename(fasta, method, opt)
    end

    ## CAT (save an original copy)
    fasta_orig = fasta.dup if opt[:cat]

    ## FRACTION the proteins
    if f = opt[:fraction]
      prefix = nil
      if f > 1.0
        prefix = proc {|cnt| "f#{cnt}_" }
      end
      fasta = fasta.fraction_of_prots(f, prefix)
    end

    ## PREFIX the proteins
    if pre = opt[:prefix]
      fasta.header_prefix!(pre)
    end

    ## MODIFY the proteins
    fasta.aaseq!((method.to_s + '!').to_sym, opt[:tryptic_peptides])

    ## CAT (finish it up)
    if opt[:cat]
      fasta_orig << fasta
      fasta = fasta_orig
    end

    ## WRITE out the file
    fasta.write_file(opt[:out])
  end

  


  #############################################
  # END MAIN METHODS
  #############################################
   
  # takes command line input, and sends it to shake
  def FastaShaker.shake_from_argv(argv)
    opt = {}

    opts = OptionParser.new do |op|
      prog = File.basename(__FILE__)
      op.banner = "USAGE: #{prog} <method> [OPTIONS] <file>.fasta"
      op.separator "   <method> = reverse | shuffle"
      op.separator ""
      op.separator "fasta_shaker is kind of like a salt shaker:"
      op.separator "shake up your fasta proteins and let them"
      op.separator "season your dinner (hopefully a protein dinner).  Mmmm."
      op.separator "false identification rates never tasted so good :)"
      op.separator ""
      op.on("-c", "--cat", "catenates the output to copy of original") {|v| opt[:cat] = v }
      op.on("-o", "--out <string>", "name of output file (default is descriptive)") {|v| opt[:out] = v }
      op.on("-p", "--prefix <string>", "give a header prefix to modified prots") {|v| opt[:prefix] = v }
      op.on("-f", "--fraction <float>", Float, "creates some fraction of proteins") {|v| opt[:fraction] = v }
      op.separator "        [if fraction > 1 then the tag 'f<frac#>_' prefixed to proteins"
      op.separator "         (after any given prefix) so that proteins are unique]"
      op.on("--tryptic_peptides", "applies method to [KR][^P] peptides") {|v| opt[:tryptic_peptides] = v }

      op.separator ""
      op.separator "EXAMPLES: "
      op.separator "   #{prog} reverse file.fasta -o protein_aa_sequence_reversed.fasta" 
      op.separator "   #{prog} shuffle file.fasta -o protein_aa_sequence_shuffled.fasta" 
      op.separator "   #{prog} shuffle file.fasta -c -p SH_ -o normal_cat_shuffled_with_prefix.fasta" 
      op.separator "   #{prog} reverse file.fasta --tryptic_peptides tryptic_peptides_reversed.fasta" 
    end

    #p argv
    opts.parse!(argv)

    if argv.size < 2
      puts opts
      exit 
    end

    (method, file) = argv
    fs = FastaShaker.new
    fs.send(method.to_sym, file, opt)
  end

  private

  

end

module FastaManipulation

  # concatenates the filenames like this:
  #   cat_filenames('fn1.ext1', 'fn2.ext2', '__') # -> 'fn1__fn2.ext1'
  #   the path and extension of the first filename are kept intact.
  #   other files only use the basename (with no extension)
  def self.cat_filenames(filenames, connector="")
    fn1 = filenames.shift
    fn1_ext = File.extname(fn1)
    filenames.collect! do |fn|
      fn_ext = File.extname(fn)
      fn_base_no_ext = File.basename(fn, fn_ext)
    end
    con_filenames = filenames.join(connector)
    fn1.gsub(/#{Regexp.escape(fn1_ext)}$/, connector + con_filenames + fn1_ext)
  end

  # returns a new fasta object using some fraction of proteins randomly
  # selected (fraction may be > 1).  Always rounds up.  Will not choose a
  # protein twice unless all other proteins have been chosen
  #
  # fraction_prefix ensures that a unique header is given even if multiple
  # fraction of proteins are being created
  # fraction_cnt = (prot_cnt/num_prots).floor.to_i
  # so for the first n proteins, it will be 0,
  # the 2n proteins will be 1, etc.  
  # e.g. prefix_proc = proc {|frac_cnt| "f#{frac_cnt}_" } 
  # would give headers like this: >f0_<some_real_header>,
  # >f1_<some_real_header>, ...
  def fraction_of_prots(fraction=1, prefix_proc=nil)
    new_num = (fraction.to_f * self.prots.size).ceil
    arr = []
    orig_num_prots = @prots.size

    # initialize
    new_prots = @prots.map {|prt| prt.dup }
    frac_cnt = 0
    ind_cnt = 0
    prt_cnt = orig_num_prots
    while ind_cnt < new_num
      arr << new_prots.delete_at(rand(new_prots.size))
      if prefix_proc
        prefix = prefix_proc.call(frac_cnt)
        arr.last.header_prefix!(prefix)
      end
      prt_cnt -= 1  # index
      if prt_cnt == 0
        frac_cnt += 1
        new_prots = @prots.map {|prt| prt.dup }
        prt_cnt = orig_num_prots
      end
      ind_cnt += 1
    end
    fasta_fraction = Fasta.new(arr)
  end

  # Convenience method to concatenate an array of fasta files.  Filenames are
  # concatenated according to 'cat_filenames') and prefixes the proteins
  # according to the values in 'file_prot_header_prefixes' array
  def self.cat_and_prefix(files, file_prot_header_prefixes=nil, file_connector=nil)
    fastas = files.collect do |file|
      Fasta.new.read_file(file)
    end
    outfile = cat_filenames(files, file_connector)
    if file_prot_header_prefixes
      file_prot_header_prefixes.each_with_index do |prefix,i|
        fastas[i].header_prefix!(prefix) if prefix
      end
    end
    fasta1 = fastas.shift
    fastas.each do |fasta|
      fasta1 << fasta
    end
    fasta1.write_file(outfile)
    outfile
  end

  def <<(other)
    # case when with class names uses === operator
    case other
    when Fasta
      @prots.push(*(other.prots)) 
    when Fasta::Prot
      @prots.push(other)
    end
  end

  # method = :shuffle! | :reverse!
  def aaseq!(method_as_symbol=:shuffle!, tryptic_peptides=false)
    if tryptic_peptides
      @prots.each {|prot| prot.tryptic_peptides!( method_as_symbol) }
    else
      @prots.each {|prot| prot.aaseq!(method_as_symbol) }
    end
  end

  # shuffles the aa sequence of each protein (each protein within itself)
  def aaseq_shuffle!
    @prots.each {|prot| prot.shuffle! }
  end

  # shuffles the aa sequence of each protein (each protein within itself)
  def aaseq_invert!
    @prots.each {|prot| prot.invert! }
  end


  def aaseq_invert_tryptic_peptides!
    @prots.each {|prot| prot.invert_tryptic_peptides! }
  end

  def aaseq_shuffle_tryptic_peptides!
    @prots.each {|prot| prot.invert_tryptic_peptides! }
  end

  def header_prefix!(prefix)
    @prots.each do |prot|
      prot.header_prefix!(prefix)
    end
  end

end

# requires that object respond_to? :reference
module ProteinReferenceable
  # gives the string up to the first space (without the leading '>')
  def first_entry
    ref = reference
    if ref
      if ref.size > 1
        ls_ref = ref.lstrip
        index = ls_ref.index(' ')
        if index
          ls_ref[0...index]
        else
          ls_ref.dup
        end
      else
        ''
      end
    else
      nil
    end
  end

end




class Fasta::Prot
  include ProteinReferenceable

  # header given as full line with starting '>' (but no newline chars!).
  # aaseq also given without any newline chars
  attr_accessor :header, :aaseq
  def initialize(header=nil, aaseq=nil)
    @header = header || ''
    if aaseq
      @aaseq = aaseq
    else
      @aaseq = ""
    end
  end

  def ==(other)
    other && other.class == self.class && other.aaseq == self.aaseq && other.header == self.header 
  end

  # gives the string up to the first space (without the leading '>')
  def first_entry
    
    if @header
      if @header.size > 1
        index = @header.index(' ')
        if index
          @header[1...index]
        else
          @header[1..-1]
        end
      else
        ''
      end
    else
      nil
    end
  end

  # returns the fasta header information without the leading '>'
  def reference
    @header[1..-1]
  end

  # returns the value after the first '|' and before the second '|'
  # according to this regexp: /\|(.*?)\|/
  # This will typically be the gi code
  # Returns nil if it doesn't match
  def gi
    if @header =~ /\|(.*?)\|/
      $1.dup
    else
      nil
    end
  end

  # convenience
  def invert_tryptic_peptides! ; tryptic_peptides!(:reverse) end
  def shuffle_tryptic_peptides! ; tryptic_peptides!(:shuffle) end

  # modifies tryptic peptides as given by SampleEnzyme.tryptic(@aaseq)
  # [cuts after K or R but not if followed by a P]
  # if method_as_symbol = :reverse
  # :reverse | :shuffle OR :reverse! | :shuffle!
  #  aaseq = 'ABCKCDERDEKDGEKWXYRRKDER'
  #  -> 'ABCKCDERDEKDGEKWXYRRKDER'
  def tryptic_peptides!(method_as_symbol)
    peps = SampleEnzyme.tryptic(@aaseq)
    ends_in_RK = /[KR]/o

    ## if the last peptide doesn't end in R or K we want to flip it completely
    last_pep_special = nil
    if peps.last[-1,1] !~ /[KR]/
      last_pep_special = peps.pop
    end
    rev_peps = peps.map{|pep| pep[0..-2].send(method_as_symbol) << pep[-1]}
    if last_pep_special
      rev_peps << last_pep_special.send(method_as_symbol)
    end
    @aaseq = rev_peps.join
  end

  # takes :reverse! | :shuffle!
  def aaseq!(method_as_symbol)
    @aaseq.send(method_as_symbol)
  end

  def invert!
    @aaseq.reverse!
  end

  def shuffle!
    @aaseq.shuffle!
  end

  # adds a prefix to the protein header (which comes after the '>' char) if
  # one is not already there.
  def header_prefix!(prefix)
    unless @header =~ /^>#{Regexp.escape(prefix)}/
      @header.gsub!(/^>/, ">#{prefix}")
    end
  end

  def dup
    self.class.new(@header.dup, @aaseq.dup) 
  end

  # returns the header line and aaseq with trailing newlines as one might find
  # in a fasta file
  def to_s
    @header + "\n" + @aaseq + "\n"
  end

end


# For reference, my code is about 15X faster than the first code I wrote
# below!  It turns out that the major slowdown is in the randomize routine.
# Using my own randomize routine with the below way of reading fasta
# files is 2X faster than below (in other words, my reader is 2X as fasta).
#
##!/usr/bin/ruby -w
#
#require 'bio'
#
#SHUFF_EXT = "_shuffled"
#
#if ARGV.size < 1
#  puts <<END
#usage: #{File.basename(__FILE__)} file.fasta ...  # -> file#{SHUFF_EXT}.fasta ...
#Shuffles the amino acid sequence of each protein.
#END
#  exit
#end
#
#ARGV.each do |fn|
#  fn_ext = File.extname(fn)
#  fn_out = fn.gsub(fn_ext, SHUFF_EXT + fn_ext)
#  File.open(fn_out, "w") do |fh|
#    f = Bio::FlatFile.auto(fn)
#    f.each_entry do |e|
#      fh.puts '>' + e.definition
#      fh.puts e.aaseq.randomize
#    end
#  end
#end
by=:protein, num=1
