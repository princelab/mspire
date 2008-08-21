
require 'spec_id'
require 'optparse'
require 'ostruct'
require 'generator'
require 'roc'

## silence this bad boy
tmp = $VERBOSE ; $VERBOSE = nil
require 'gnuplot'
$VERBOSE = tmp

class String
  def margin
    self.gsub(/^\s*\|/,'')
  end
end

class Prec ; end

module Prec::PlotHelper

  PLOT_TYPE = 'XYData'
  TITLE = 'Precision vs. Num Hits [ Precision = Positive Predictive Value = TP/(TP+FP) ]'
  XAXIS = 'Num Hits (excludes known false positives)'
  EXT = '.toplot'
  IMAGE_EXT = '.png'

  def create_to_plot_file(all_arrs, key, files, filename_noext)
    ## CREATE the PLOT IMAGE:
    to_plot = filename_noext + EXT
    png = filename_noext + IMAGE_EXT


    File.open(to_plot,'w') do |out|
      out.puts PLOT_TYPE
      out.puts filename_noext
      out.puts TITLE
      out.puts XAXIS
      out.puts escape_to_gnuplot(y_axis_label(key))
      files.each_with_index do |file,i|
        #p key[i]
        #p all_arrs[i]

        key[i].each_with_index do |k,j|
          out.puts(escape_to_gnuplot("#{file}: #{k[1][1]}"))
          out.puts all_arrs[i][j][0].join(' ')
          out.puts all_arrs[i][j][1].join(' ')
        end
      end
    end
  end


  ## outputs a .toplot file based on filename_noext, creates a png file, and
  ## writes  html to fh that will load the png file up
  ## This is a self contained module that can be swapped out for a
  ## completely different plotting program if desired.
  def plot_figure(all_arrs, key, files, filename_noext)

    ## CREATE the PLOT IMAGE:
    to_plot = filename_noext+'.toplot'
    png = filename_noext+'.png'

    tmp = $VERBOSE ; $VERBOSE = nil
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.terminal "png noenhanced" 
        plot.output png
        plot.title TITLE
        plot.xlabel XAXIS
        plot.ylabel escape_to_gnuplot(y_axis_label(key))
        plot.style "line 1 lt 1"
        plot.style "line 2 lt 12"
        #plot.style  "line 1 lt 1 lw #{opts.lw} pt 7 ps #{opts.ps}",
        plot.yrange "[-0.05:#{1.05 + 0.020*files.size}]"
        files.each_with_index do |file,i|
          key[i].each_with_index do |k,j|
            plot.data << Gnuplot::DataSet.new( [ all_arrs[i][j][0], all_arrs[i][j][1] ] ) do |ds|
              ds.with = "lines"
              ds.title = escape_to_gnuplot("#{file}: #{k[1][1]}")
            end
          end
        end
      end
    end
    $VERBOSE = tmp

    ## CREATE the HTML to load the plot:
    basename_filename_noext = File.basename(filename_noext)
    output = "<div id=\"plot\"><table class=\"image\" align=\"center\">\n"
    #output << "<caption align=\"bottom\">Additional views of this data may be obtained by using the <span class=\"code\">plot.rb</span> command on '#{to_plot}' (type <span class=\"code\">plot.rb</span> for more details). Plot generated with command: &nbsp;&nbsp; <span class=\"code\">#{plot_cmd}</span></caption>\n"
    output << "<tr><td><img src=\"#{basename_filename_noext}.png\" title=\"File #{basename_filename_noext} must be in the same directory as this html.\"/></td></tr>\n"
    output << "</table></div>\n"
    output
  end  # plot_figure

end

module Prec::HTML

  # html and body tags
  def html
        "|<html>
         |#{yield}
         |</html>\n".margin
  end

  def body
        "|<body>
         |  #{yield}
         |</body>\n".margin
  end

  def header
        "|<head>
         |  #{style}
         |</head>\n".margin
  end

  def td
        "<td>#{yield}</td>"
  end


  def style
        '
     <style type="text/css">
        div#tp_table {
          text-align: center;
          margin-top: 50px;
          margin-bottom: 50px;
        }
        span.code {
        font-family: Courier,Monospace;
        font-size: 80%;
        }
          table {
              border-width:1px;
              border-color:#CCCCCC;
              border-collapse: collapse;
          }
          caption {
            font-size: 90%;
          }
          td,th {
              padding-top: 2px;
              padding-bottom: 2px;
              padding-left: 1;
              padding-right: 1;
          }
          th.small {
            font-size: 80%;
            font-weight: normal;
            padding: 1px;
          }
          td.redline {
              background-color: #FF0000;
              color: #FFFFFF
          }
      div#plot {
        margin: 30px;
     text-align:center
      }
      hr {color: sienna}
      body { font-size: 8pt; font-family: Arial,Helvetica,Times}
      </style> 
        '

  end

  def table
        "|<table border=\"1\" align=\"center\" style=\"font-size:100%\">
         |  #{yield}
         |</table>\n".margin
  end

  def tr
        "|<tr>
         |  #{yield}
         |</tr>\n".margin
  end
end # module HTML

class Prec
  include Prec::PlotHelper

  ###########################################################
  # GLOBAL SETTINGS:
  DATA_PREC = 4   # decimal places of precision for ppv data
  STDOUT_JTPLOT_BASE = "ppv"  # if there is no outfile
  ###########################################################

  include Prec::HTML

  ## returns an html string
  def precision(argv)
    opt = parse_args(argv)
    files = argv.to_a
    out_string = create_precision_data(files, opt)
    [out_string, opt]
  end

  def run_cmd_line(argv)
    output_string, opt, file_as_decoy = precision(argv)
    if file_as_decoy
      puts output_string
    else
      ## open file and write to it..
      if opt.o == 'STDOUT'
        print output_string
      else
        File.open(opt.o,'w') do |fh| fh.print output_string end
      end
    end
  end

  # returns the outfile with no extension
  def outfile_noext(opt)
    if opt == 'STDOUT'
      "#{STDOUT_JTPLOT_BASE}"
    else
      opt.sub(/#{Regexp.escape(File.extname(opt))}$/, '')
    end
  end

  def file_noext(file)
    file.sub(/#{Regexp.escape(File.extname(file))}$/, '')
  end

  def parse_args(argv)

    opt = OpenStruct.new
    opt.o = 'STDOUT'
    opts = OptionParser.new do |op|
      op.banner = "Usage: #{File.basename(__FILE__)} [options] bioworks.xml|proph-prot.xml ..."
      op.separator ""
      op.separator "Abbreviations and Definitions:"
      op.separator "  TP = True Positives"
      op.separator "  FP = False Positives"
      op.separator "  Precision = Positive Predictive Value = [TP/(TP+FP)]"
      op.separator ""  
      op.separator "Output: "
      op.separator "  1. Decoy as separate search: PPV to STDOUT"
      op.separator "  2. Decoy proteins from concatenated database: '.html'" 
      op.separator ""
      op.separator "Options:"

      op.on("-f", "--fp_data <prefix_or_file>", "flag -or- decoy FILE") {|v| opt.f = v }
      op.separator ""
      op.separator "        If searched with a concatenated DB, give a false flag to decoy proteins."
      op.separator "        If files have different flags, separate with commas."
      op.separator "        If searched with a separate decoy DB, give the FILE name of decoy data"
      op.on("--prefix", "false flag as prefix only") {|v| opt.prefix = v }
      op.separator ""
      ## NOT YET FUNCTIONAL: op.on("-e", "--peptides", "do peptides instead of proteins")
      op.separator ""
      op.on("-o", "--outfile <file>", "write output to file (def: #{opt.o})") {|v| opt.o = v}
      op.on("-a", "--area", "output area under the curve instead of the plot") {|v| opt.a = v}
      op.on("-j", "--plot_file", "output to_plot file") {|v| opt.j = v}
      op.on_tail("
Example: 
  For a search on a concatenated database where the decoy proteins have
  been flagged with the prefix 'INV_' for both Bioworks and ProteinProphet
  output:

    #{File.basename(__FILE__)} -f INV_ bioworks.xml proph-prot.xml

  ")
    end
    opts.parse!(argv)

    if argv.size < 1
      puts opts
      exit
    end

    opt
  end


  ## collapses arrays to one level deep so we can sync them up
  def arrays_to_one_level_deep(all_arrs)
    mostly_flat = []
    all_arrs.each do |per_file|
      per_file.each do |per_style|
        mostly_flat << per_style[0]
        mostly_flat << per_style[1]
      end
    end
    mostly_flat
  end

  # prints rows and th for the data
  def table_cells(all_arrs, key)
    ## columns specific headings:
    all_string = ""
    all_string << tr do
      line = ""
      key.each do |per_file|
        per_file.each do |per_ds|
          line << "<th class=\"small\">#{per_ds[1][0]}</th><th class=\"small\">#{per_ds[1][1]}</th>"
        end
      end
      line
    end
    mostly_flat = arrays_to_one_level_deep(all_arrs)
    SyncEnumerator.new(*mostly_flat).each do |row|
      all_string << tr do 
        string = row.map {|it| 
          sty="%d"
          if it.class == Float ; sty="%.#{DATA_PREC}f" end
          td{ sprintf(sty,it)} 
        }.join
      end
    end
    all_string
  end

  def html_table_output(all_arrs, key, files, filename_noext)
    num_datasets_per_file = all_arrs.first.size
    num_cols_per_dataset = 2
    big_colspan = num_datasets_per_file * num_cols_per_dataset 
    output = table do 
      tr do 
        files.map do |file|
        "<th colspan=\"#{big_colspan}\">#{file}</th>"
        end.join
      end +
        tr do 
        key.map do |arr|
          arr.map do |ds|
        "<th colspan=\"2\">#{ds.first}</th>"
          end
        end
        end + 
          table_cells(all_arrs, key)
    end
    "<div id=\"tp_table\">" + output + "</div>"
  end


  def y_axis_label(key)
    ## We only take the keys for the first file, as it's assumed that the major
    ## labels will be identical for all of them
    labels = key.first.map {|tp| tp.first }.uniq
    labels.join "  |  "
  end

  # escapes any ' chars
  def escape_to_gnuplot(string)
    # long way, but it works.
    new_string = ""
    string.split(//).each do |chr|
      if chr == "'" ; new_string << "\\" end 
      new_string << chr
    end
    new_string
  end

  # if opt.f, then a prefix is assumed.
  # if a file =~ /-prot.xml$/ then a precision plot based on probability is
  # also created
  def create_precision_data(files, opt)
    #$stderr.puts "using prefix #{opt.f} ..."

    if opt.f
      prefix_arr = SpecID.extend_args(opt.f, files.size)
    end
    all_arrs = [] 
    key = []
    out_noext = outfile_noext(opt.o)
    files.each_with_index do |file,i|
      all_arrs[i] = []
      key[i] = []
      sp = SpecID.new(file)
      #headers = ["#{file_noext(file)} Precision [TP/(TP+FP)]", "#{file_noext(file)} FPR [FP/(FP+TP)]"]
      if opt.f
        (num_hits, ppv) = sp.num_hits_and_ppv_for_prob(prefix_arr[i], opt.prefix)
        all_arrs[i] << [num_hits,ppv] 
        key[i] << ["Precision",  ["# hits", "Prec (decoy)"]]
      end
      if file =~ /-prot\.xml$/
        ## These are just from protein prophet probabilities:
        (num_hits, ppv) = sp.num_hits_and_ppv_for_protein_prophet_probabilities
        all_arrs[i] << [num_hits,ppv] 
        key[i] << ["Precision",  ["# hits", "Prec (prob)"]]
      end
    end

    string = ''
    if opt.a
      roc = ROC.new
      #string << "***********************************************************\n"
      #string << "AREA UNDER CURVE:\n"
      key.each_with_index do |file,i| 
        string << "#{files[i]} (area under curve)\n"
        key[i].each_index do |j| 
          string << "#{key[i][j][0]} [#{ key[i][j][1]}]:\t" 
          num_hits = all_arrs[i][j][0]
          oth = all_arrs[i][j][1]
          string << roc.area_under_curve(num_hits, oth).to_s << "\n"
        end
      end
      #string << "***********************************************************\n"
    else
      if opt.j
        create_to_plot_file(all_arrs, key, files, out_noext)
      end
      string = html do
        header +
          body do
          plot_figure(all_arrs, key, files, out_noext) +
            html_table_output(all_arrs, key, files, out_noext)
          end
      end
    end
    string
  end

end # class SpecID

