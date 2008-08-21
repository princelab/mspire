

require 'axml'
require 'hash_by'
require 'optparse'
require 'ostruct'
require 'spec_id'
#require 'spec_id/precision'  # gone now
require 'gi'

#############################################################
# GLOBALS:
PRECISION_PROGRAM_BASE = 'precision'
DEF_PREFIX = "INV_"
DEF_PERCENT_FP = "5.0"
#############################################################


# @TODO: add group probability title (showin all group probabilities) for protein prob

#class String
#  def margin
#    self.gsub(/^\s*\|/,'')
#  end
#end


class ProteinSummary
  module HTML
    def header
    %Q{<html>
    <head
    #{style}
    </head>
    <body>
    <script type="text/javascript">
    <!--
    function toggle_vis(id) {
      var e = document.getElementById(id);
      if(e.style.display == 'none')
        e.style.display = 'block';
      else
        e.style.display = 'none';
    }
    //-->
    </script>
    }
      end

      def style
   '
   <style type="text/css">
        table {
            border-width:1px;
            border-color:#DDDDDD;
            border-collapse: collapse;
        }
        td,th {
            padding-top: 2px;
            padding-bottom: 2px;
            padding-left: 5;
            padding-right: 5;
        }
        td.redline {
            background-color: #FF0000;
            color: #FFFFFF
        }
        div.file_info, div.software, div.fppr, div.num_proteins{
            margin-left: 20px;
            margin-top: 20px;
        }
        div.main {
          margin-left: 10px;
          margin-right: 10px;
          margin-top: 50px; 
          margin-bottom: 50px; 
        }
    div#error {
      margin: 30px;
   text-align:center
    }
    hr {color: sienna}
    body { font-size: 8pt; font-family: Arial,Helvetica,Times}
    </style> 
      '
      end

      # an anchor and a title
      def at(display, title)
    "<a title=\"#{title}\">#{display}</a>"
      end

      def trailer
    %q{
    </body>
    </html>
    }
      end

      def tr
    "|<tr> 
     |  #{yield}
     |</tr>\n".margin
      end

      def table
    "|<div class=\"main\"><table align=\"center\" border=\"1\" style=\"font-size:100%\" width=\"800px\">
     |  #{yield}
     |</table></div>\n".margin
      end

      def tds(arr)
        arr.map {|v| "<td>#{v}</td>"}.join
      end

      def ths(arr)
        str = arr.map {|v| "<th>#{v}</th>"}.join
        str << "\n"
      end
    end

  end


class ProteinSummary

  include ProteinSummary::HTML

  def ref_html(gi, name)
  "<a href=\"http://www.ncbi.nlm.nih.gov/entrez/viewer.fcgi?db=protein&val=#{gi}\" title=\"#{name}\">#{gi}</a>"
  end

  # Takes the -prot.xml filename and grabs the png file (if available)
  def error_info(prot_file_name)
    img = prot_file_name.gsub('.xml', '.png')
    img_bn = File.basename(img)
      "<div id=\"error\"><img src=\"#{img_bn}\" alt=\"[ Optional: To view error/sensitivity image, put #{img_bn} in the same directory as #{File.basename(prot_file_name)} ]\"/>\n</div>"
  end

  # attempts to get the NCBI gi code
  def accession(name)
    if (name.include? '|') && (name[0,3] == 'gi|')
      name.split('|')[1]
    else
      name
    end
  end

  def flag_to_regex(flag, prefix=false)
    if flag
      if prefix
        /^#{Regexp.escape(flag)}/
      else
        /#{Regexp.escape(flag)}/
      end
    else
      nil
    end
  end

  # given a list of proteins, output a tab delimited textfile with protein
  # name and the total number of peptides found
  def output_peptide_counts_file(prots, filename)
    File.open(filename, "w") do |fh_out|
      prots.each do |prot|
        fh_out.puts [prot._protein_name, prot._total_number_peptides].join("\t")
      end
    end
  end

  # filters on the false positive regex and sorts by prot probability
  def filter_and_sort(uniq_prots, flag=nil, prefix=false)
    false_flag_re = flag_to_regex(flag, prefix) 
    sorted = uniq_prots.sort_by {|prt| [prt._probability, prt.parent._probability]}.reverse
    ## filter on prefix
    if prefix
      sorted = sorted.reject {|prot| prot._protein_name =~ false_flag_re }
    end
    sorted
  end

  # assumes that these are sorted on probability
  # desired_fppr is a float
  # returns [number_of_prots, actual_fppr]
  def num_prots_above_fppr(prots, desired_fppr)
    current_fppr_rate_percent = 0.0
    previous_fppr_rate_percent = 0.0
    current_sum_one_minus_prob = 0.0
    proteins_within_fppr = 0
    actual_fppr = nil
    already_found = false
    prot_cnt = 0
    prots.each do |prot|
      prot_cnt += 1
      # SUM(1-probX)/#prots
      current_sum_one_minus_prob += 1.0 - prot._probability.to_f
      current_fppr_rate_percent = (current_sum_one_minus_prob / prot_cnt) * 100

      if current_fppr_rate_percent > desired_fppr && !already_found
        actual_fppr = previous_fppr_rate_percent
        proteins_within_fppr = prot_cnt
        already_found = true
      end
      previous_fppr_rate_percent = current_fppr_rate_percent
    end
    [proteins_within_fppr, actual_fppr]
  end

    ####    #readable_previous_fppr_rate_percent = sprintf("%.2f", previous_fppr_rate_percent)

  # returns a string of the table rows
  # false_positive_rate (give as a %) is the cutoff mark
  # returns the number of proteins at the desired_fppr (if given)
  def table_rows(uniq_prots, prefix, false_positive_rate_percent, num_cols, desired_fppr, actual_percent_fp, annotations=nil, peptide_count_filename=nil)
    prot_cnt = 0
    an_cnt = 0
 
    uniq_prots.map do |prot| 
      tr do
        prot_cnt += 1
        gi = accession(prot._protein_name)

        if annotations
          protein_description = annotations[an_cnt]
          an_cnt += 1
        else
          if prot.annotation.size > 0
            protein_description = prot.annotation.first._protein_description
          else
            protein_description = 'NA'
          end
        end
        tds([prot_cnt, prot._probability, ref_html(gi, prot._protein_name), protein_description, prot._percent_coverage, peptide_cell(prot_cnt, prot._unique_stripped_peptides.split('+')), prot._total_number_peptides, prot._pct_spectrum_ids])
      end
    end.join
  end

  def print_html_pieces(file, *pieces)
    File.open(file, "w") do |out|
      pieces.each do |piece|
        out.print piece
      end
    end
  end

  def file_info(file)
    "<div class=\"file_info\"><h3>Source File Information</h3>File: #{File.expand_path(file)}
    <br/>Last Modified: #{File.mtime(file)}
    <br/>Size: #{File.size(file)/1000} KB
    </div>"
  end

  def bioworks_script_info(obj)
    version = "3.2??"
    if obj.version
      version = obj.version
    end
    script_info{"Bioworks version #{version}"}
  end

  def protproph_script_info
    begin
      where = `which xinteract`
      reply = `#{where}`
    rescue Exception
      reply = ""
    end
    prophet = "TPP (version unknown)"  # put your version here if you can't get it dynamically
    if reply =~ /xinteract.*?\((TPP .*)\)/
      prophet = $1.dup
    end
    script_info { "ProteinProphet from: #{prophet}" }
  end

  def mspire_version
    string = "mspire"
    begin
      if `gem list --local mspire` =~ /mspire \((.*?)\)/
        string << (" v" + $1)
      end
    rescue Exception
    end
    string
  end

  def script_info
    "<div class=\"software\"><h3>Software Information</h3>#{yield}<br/>Ruby package: #{mspire_version}<br/>Command: #{[File.basename(__FILE__), *@orig_argv].join(" ")}</div>"
  end

  def proph_output(file, outfn, opt, fppr_output_as_html)
    header_anchors = [at('#', 'number'), at('prob','protein probability (for Prophet, higher is better)'), at('ref', 'gi number if available (or complete reference)'), at('annotation', 'annotation from the fasta file'), at('%cov', 'percent of protein sequence covered by corresponding peptides'), at('peps', 'unique peptides identified (includes non-contributing peptides). Click number to show/hide'), at('#peps', 'total number of corresponding peptides that contributed to protein probability'),  at('%ids', 'fraction of correct dataset peptide identifications corresponding to protein')]
    num_cols = header_anchors.size
    theaders = ths(header_anchors)

    root = AXML.parse_file(file)
    prots = []
    ## find the min_prob at a fppr of XX
    min_prob_redline = 1.01  # if no fppr is less than what they give, then all are redlined!

    if opt.c 
      actual_percent_fp = opt.c.to_f
    elsif opt.cut_at
      actual_percent_fp = opt.cut_at.to_f
    else
      actual_percent_fp = nil
    end
    root.protein_group.each do |group|
      group.protein.each do |prt|
        prots << prt 
      end
    end
    uniq_prots = prots.hash_by(:_protein_name).map{|name,prot_arr| prot_arr.first }
    filtered_sorted_prots = filter_and_sort(uniq_prots, opt.f, opt.prefix)

    ## num proteins above cutoff (if opt.c)
    num_prots_html = ''
    if opt.c || opt.cut_at
      (num_prots, actual_fppr) = num_prots_above_fppr(filtered_sorted_prots, actual_percent_fp)
      num_prots_html = num_prots_to_html(actual_percent_fp, actual_fppr, num_prots)
    end
    if opt.cut_at
      filtered_sorted_prots = filtered_sorted_prots[0,num_prots]
    end

    output_peptide_counts_file(filtered_sorted_prots, opt.peptide_count) if opt.peptide_count

    # get an array of annotations (or nil if no option)
    annotations =
      if opt.get_annotation
        gis = filtered_sorted_prots.map {|prot| accession(prot._protein_name) }
        GI.gi2annot(gis) 
      end

    table_string = table do 
      tr{theaders} + table_rows(filtered_sorted_prots, opt.f, actual_percent_fp, num_cols, opt.c.to_f, actual_percent_fp, annotations, opt.peptide_count)
    end
    er_info = opt.precision ? error_info(file) : ""
    html_pieces = [outfn, header, fppr_output_as_html, er_info, file_info(file), protproph_script_info, num_prots_html, table_string, trailer]
    print_html_pieces(*html_pieces)
  end # proph_output

  # given a list of peptide sequences creates javascript to hide/show them
  def peptide_cell(prot_num, peptide_sequences)
    "<a href=\"#prot#{prot_num}\" onclick=\"toggle_vis('#{prot_num}');\">#{peptide_sequences.size}</a><div id=\"#{prot_num}\" style=\"display:none;\">#{peptide_sequences.join(', ')}</div>"
  end

  # takes spec_id object
  # the outfn is the output filename
  # opt is an OpenStruct that holds opt.f = the false prefix
  def bioworks_output(spec_id, outfn, file=nil, false_flag_re=nil, fppr_output_as_html=nil)
    fppr_output_as_html ||= ''
    header_anchors = [at('#', 'number'), at('prob','protein probability (for Bioworks, lower is better)'), at('ref', 'gi number if available (or complete reference)'), at('annotation', 'annotation from the fasta file'), at('%cov', 'percent of protein sequence covered by corresponding peptides'), at('peps', 'unique peptides identified (at any confidence) Click number to show/hide.'), at('#peps', 'total number of peptides seen (not unique)')]
    num_cols = header_anchors.size
    theaders = ths(header_anchors)
    proteins = spec_id.prots
    protein_num = 0
    rows = ""
    proteins.each do |prot|
      if false_flag_re && prot.reference =~ false_flag_re
        next
      end
      uniq_peps = Hash.new {|h,k| h[k] = true; }
      protein_num += 1
      prot.peps.each do |pep|
        uniq_peps[pep.sequence.split('.')[1]] = true
      end
      pieces = prot.reference.split(' ')
      long_prot_name = pieces.shift 
      annotation = pieces.join(' ')
      accession = prot.accession
      if accession == '0' ; accession = long_prot_name end
      rows << tr{ tds([protein_num, prot.protein_probability, ref_html(accession, long_prot_name), annotation, prot.coverage, peptide_cell(protein_num, uniq_peps.keys), prot.peps.size]) }
    end
    table_string = table do 
      tr{theaders} + rows
    end
    print_html_pieces(outfn, header, fppr_output_as_html, file_info(file), bioworks_script_info(spec_id), table_string, trailer)
  end # bioworks_output

  def num_prots_to_html(desired_cutoff, actual_cutoff, num_proteins)
    actual_cutoff = sprintf("%.3f", actual_cutoff)
    desired_cutoff = sprintf("%.3f", desired_cutoff)
    "<div class=\"num_proteins\"><h3>False Positive Predictive Rate [ FP/(TP+FP) ]</h3>
    Desired FPPR: #{desired_cutoff} %<br/>
    Actual FPPR: #{actual_cutoff} %<br/>
    Number of Proteins at Actual FPPR: #{num_proteins}
    </div>"
  end

  # transforms the output string of file_as_decoy into html
  def file_as_decoy_to_html(string)  
    lines = string.split("\n")
    #puts lines ?? is this supposed to be commented out?
    lines = lines.reject do |obj| obj =~ /\*{10}/ end
    lines.map! do |line| "#{line}<br/>" end
    "<div class=\"fppr\">
    <h3>Classification Analysis</h3>
    #{lines.join("\n")} 
    </div>"
  end

  # transforms the output string of file_as_decoy into html
  def prefix_as_decoy_to_html(string)  
    "<div class=\"fppr\">
    <h3>Classification Analysis</h3>
    </div>" +
    string
  end

  def create_from_command_line_args(argv)
    @orig_argv = argv.dup

    opt = OpenStruct.new
    opt.f = DEF_PREFIX
    opts = OptionParser.new do |op|
      op.banner = "usage: #{File.basename(__FILE__)} [options] <file>.xml ..."
      op.separator "    where file = bioworks -or- <run>-prot (prophet output)"
      op.separator "    outputs: <file>.summary.html"
      op.separator ""
      op.on("-f", "--false <prefix>", "ignore proteins with flag (def: #{DEF_PREFIX})") {|v| opt.f = v }
      op.on("--prefix", "false flag for prefixes only") {|v| opt.prefix = v }
      op.on("-p", "--precision", "include the output from precision.rb") {|v| opt.p = v }
      op.separator("             if --precision then -f is used to specify a file or prefix")
      op.separator("             that indicates the false positives.")
      op.on("--peptide_count <filename>", "outputs text file with # peptides per protein") {|v| opt.peptide_count = v}
      op.separator ""
      op.separator "Options for #{PRECISION_PROGRAM_BASE}.rb :"
      op.on("--#{PRECISION_PROGRAM_BASE}", "include output of #{PRECISION_PROGRAM_BASE}.rb,") {|v| opt.precision = v}
      op.separator("                                     type '#{PRECISION_PROGRAM_BASE}.rb' for details")
      op.separator ""
      op.separator "specific to ProteinProphet (with no concatenated DB):"
      op.on("-c", "--cutoff percent", "false positive predictive rate (FPPR)% for given cutoff") {|v| opt.c = v }
      op.on("--cut_at percent", "only reports proteins within FPPR %") {|v| opt.cut_at = v }
      op.on("--get_annotation", "retrieves annotation by gi code") {|v| opt.get_annotation = v}
      op.separator "             (use if your proteins have gi's but no annotation) "
    end

    opts.parse!(argv)

    if argv.size < 1
      puts opts
      return
    end

    fppr_output_as_html = ''
    files = argv.to_a
    files.each do |file| 
      outfn = file.sub(/\.xml$/, '.summary.html')
      outfn = outfn.sub(/\.srg$/, '.summary.html')
      ## False Positive Rate Calculation:
      if opt.precision
        opt.o = outfn # won't actually be written over, but used
        to_use_argv = create_precision_argv(file, opt)
        (out_string, opt) = Prec.new.precision(to_use_argv)
        fppr_output_as_html = prefix_as_decoy_to_html(out_string)
      end

      case SpecID.file_type(file)
      when "protproph"
        #spec_id = SpecID.new(file)
        proph_output(file, outfn, opt, fppr_output_as_html)
      when "bioworks"
        spec_id = SpecID.new(file)

        false_regex = flag_to_regex(opt.f, opt.prefix)
        bioworks_output(spec_id, outfn, file, false_regex, fppr_output_as_html)
      else 
        abort "filetype for #{file} not recognized!"
      end
    end

  end # method create_from_command_line

  def create_precision_argv(file, opt)
    # include only those options specific
    new_argv = [file]
    if opt.prefix ; new_argv << '--prefix' end
    if opt.f ; new_argv << '-f' << opt.f end
    if opt.o ; new_argv << '-o' << opt.o end
    new_argv
  end

end   # ProteinSummary

##################################################################
# MAIN
##################################################################


