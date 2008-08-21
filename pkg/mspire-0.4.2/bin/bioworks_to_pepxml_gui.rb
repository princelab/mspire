#!/usr/bin/ruby -w

tmp = $VERBOSE ; $VERBOSE = nil
require 'fox16'
$VERBOSE = tmp

include Fox


class Opt
  attr_accessor :flag, :value
  def initialize(flag, value=nil)
    @flag = flag
    @value = value
  end

  def self.[](flag, value=nil)
    self.new(flag, value)
  end

  def to_s
    st = @flag
    if @value
      st << " " << @value
    end
    st
  end
  
end


NCOLS = 40

srf_dir = nil
output_dir = '.'
msdata_dir = '.'
$progname = 'bioworks_to_pepxml.rb'
$sequest_folder = '/project/marcotte/marcotte/ms/john/sequest'
$data_folder = '/project/marcotte/marcotte/ms/john/data'
$isb_folder = '/var/www/tpp'

# This is a directory selector consisting of: Label | FieldText | BrowseButton
# if you pass in patterns, then you can select multiple files!
class DirSelector 
  attr_writer :directory

  def directory
    @directory_data.to_s
  end

  # You should pass in the frame that you want filled up!
  def initialize(parent, label='select directory', init_dir='.', text_field_width=30)
    @directory_data = FXDataTarget.new(init_dir)

    FXLabel.new(parent, label , nil, LAYOUT_CENTER_Y|LAYOUT_RIGHT|JUSTIFY_RIGHT)
    srf_field = FXTextField.new(parent, text_field_width, @directory_data) do |tf|
      tf.text = @directory_data.to_s
    end
    srf_field.connect(SEL_COMMAND) do |sender, sel, message|
      @directory_data.value = message
    end
    but = FXButton.new(parent, "Browse")
    but.connect(SEL_COMMAND) do |sender, sel, message|
      @directory_data.value = FXFileDialog.getOpenDirectory(parent, "Open directory_data", @directory_data.to_s)
      srf_field.text = @directory_data.value
    end
  end
end

# This is a directory selector consisting of: Label | FieldText | BrowseButton
# if you pass in patterns, then you can select multiple files!
class MultipleFilesSelector
  # an array of filenames
  attr_writer :files

  # You should pass in the frame that you want filled up!
  def initialize(parent, label='select multiple files', init_dir='.', text_field_width=30, patterns=["All Files (*)"])
    @directory_data = FXDataTarget.new(init_dir)

    FXLabel.new(parent, label , nil, LAYOUT_CENTER_Y|LAYOUT_RIGHT|JUSTIFY_RIGHT)
    srf_field = FXTextField.new(parent, text_field_width, @directory_data) do |tf|
      tf.text = @directory_data.to_s
    end
    srf_field.connect(SEL_COMMAND) do |sender, sel, message|
      @directory_data.value = message
    end
    but = FXButton.new(parent, "Browse")
    if patterns.is_a?(Array)
      pattern_string = patterns.join("\n") 
    else
      pattern_string = patterns
    end
    but.connect(SEL_COMMAND) do |sender, sel, message|
      reply = FXFileDialog.getOpenFilenames(parent, "Open directory_data", @directory_data.to_s, pattern_string)
      p reply
      abort
      srf_field.text = @directory_data.value
    end
  end
end


class MainWindow < FXMainWindow

  def action(*args)
    p args

    cmd = []
    cmd << $progname
    #cmd << args
    #cmd << Opt['-o', output_dir]

    puts cmd.join(" ")
  end

  def initialize(anApp)
    labels = ["&SRF files (select multiple)", "&Output Directory (ISB)", "&Directory with RAW files"]
    super(anApp, "bioworks_to_pepxml", nil, nil, DECOR_ALL)

    gb = FXGroupBox.new(self, "Specify input/output", FRAME_RIDGE)
    mat = FXMatrix.new(gb, 3, MATRIX_BY_COLUMNS|LAYOUT_SIDE_TOP)

    srf_files_selector = MultipleFilesSelector.new(mat, labels[0], $sequest_folder, NCOLS, ["SRF files (*.srf)"])

    isb_files_selector = DirSelector.new(mat, labels[1], $isb_folder, NCOLS)

    hf = FXHorizontalFrame.new(self)
    create_mzxml = FXCheckButton.new(hf, 'create mzXML files')
    copy_mzxml = FXCheckButton.new(hf, 'copy mzXML files to ISB dir') {|v| v.checkState = TRUE }
    copy_mzxml.hide

    @mat2 = FXMatrix.new(self, 3, MATRIX_BY_COLUMNS|LAYOUT_SIDE_TOP)
    srf_dir_selector = DirSelector.new(@mat2, labels[2], $data_folder, NCOLS)

    submit = FXButton.new(self, "Submit")
    submit.connect(SEL_COMMAND) do |sender, sel, message|
      action(srf_dir_selector.files)
    end

    create_mzxml.connect(SEL_COMMAND) do |button,b,checked|
      if checked 
        copy_mzxml.show
        @mat2.show
        self.resize(self.width, @large_height)
      else
        copy_mzxml.hide
        @mat2.hide
        self.resize(self.width, @small_height)
      end
    end

  end

  def create
    super
    show(PLACEMENT_SCREEN)
    @large_height = self.height

    # setup hidden state
    @mat2.hide 
    @small_height = @large_height - @mat2.height
    self.resize(self.width, @small_height)
  end

end


application = FXApp.new("Hello", "FXRuby") do |theApp|
  MainWindow.new(theApp)
  theApp.create
  theApp.run
end


application.run()




=begin


---------------------------------
class MyMainWindow < FXMainWindow

   attr :advancedFrame

   def initialize(app)
      super(app, "MyMainWindow")
      
      contents = FXVerticalFrame.new(self,
         LAYOUT_FILL_X|LAYOUT_FILL_Y)

      advancedButton = FXButton.new(contents, "Advanced >>",
         nil, self, 0, FRAME_RAISED|FRAME_THICK)

      advancedButton.connect(SEL_COMMAND) do
         if @advancedFrame.shown?
            self.height -= @advancedFrame.height
            @advancedFrame.hide
            advancedButton.text = "Advanced >>"
         else
            self.height += @advancedFrame.height
            @advancedFrame.show
            advancedButton.text = "<< Basic"
         end
         
         self.recalc
      end
   end
end
#---------------------------
app = FXApp.new

mainWindow = MyMainWindow.new(app)

app.create
mainWindow.advancedFrame.hide
mainWindow.height -= mainWindow.advancedFrame.height

mainWindow.show(PLACEMENT_SCREEN)

app.run

=end
