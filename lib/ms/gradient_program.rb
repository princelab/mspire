
# This is modeled after the Thermo gradient
class GradientProgram
  attr_accessor :time_points
  attr_accessor :pump_type
  # array of solvents parallel to TimePoint percentages array
  attr_accessor :solvents

  def initialize(pump_type, time_points=[], solvents=[])
    @pump_type = pump_type
    @time_points = time_points
    @solvents = solvents
  end

  def ==(other)
    self.class == other.class and @pump_type==other.pump_type and @solvents == other.solvents and @time_points == other.time_points
  end

  # gets the first gradient program encountered in the filehandle
  def self.get_gradient_program(fh)
    thermo_newline = "\n\000"
    #gtable = "g\000r\000a\000d\000i\000e\000n\000t\000 \000t\000a\000b\000l\000e"
    gradient = "[Gg]\000r\000a\000d\000i\000e\000n\000t\000 \000"
    
    
    xcal_2x = gradient + "t\000a\000b\000l\000e\000:\000"
    xcal_1x = gradient + "P\000r\000o\000g\000r\000a\000m\000:\000"
    xcal_2x_regexp = Regexp.new(xcal_2x)
    xcal_1x_regexp = Regexp.new(xcal_1x)
    find_gtable_regexp = Regexp.new(gradient)

    found_one_2x = false
    found_one_1x = false
    pump_type = ''
    fh.each(thermo_newline) do |line|
      # first identify the line, then 
      if line =~ find_gtable_regexp
        if line =~ xcal_1x_regexp
          pump_type = ''  ## have to look way back in file for this
          found_one_1x = true
          break
        elsif line =~ xcal_2x_regexp
          grab_pump_type_regexp = /(.*) .g.r.a.d.i.e.n.t. .t.a.b.l.e/
          pump_type = read_thermo_string(grab_pump_type_regexp.match(line).captures[0])
          found_one_2x = true
          break
        end
      end
    end
    if found_one_2x
      fh.gets(thermo_newline) # nothing
      table_headers = fh.gets(thermo_newline)
      time_points = []
      while (line = fh.gets(thermo_newline)) != thermo_newline
        # 0   0.00  95.0  5.0   0.0   0.0   38.0   x   
        # 1   1.00  90.0  10.0  0.0   0.0   38.0   o

        pieces = table_row_to_pieces(line, '2.0')
        time_points << TimePoint.new(pieces[1].to_f, pieces[6].to_f, pieces[2,4].map{|x| x.to_f })
      end
      GradientProgram.new(pump_type, time_points, %w(A B C D))
    elsif found_one_1x
      fh.gets(thermo_newline) # nothing
      table_headers = fh.gets(thermo_newline)
      time_points = []
      null_char_regexp = Regexp.new("^\000\000\000\000")
      while (line = fh.gets(thermo_newline)) !~ null_char_regexp
        pieces = table_row_to_pieces(line, '1.0')
        time_points << TimePoint.new(pieces[1].to_f, pieces[6].to_f, pieces[2,4].map{|x| x.to_f })
      end
      GradientProgram.new(pump_type, time_points, %w(A B C D))
    else
      nil
    end
  end

  # returns the elements of a gradient table row properly cast
  # NOTE: Xcal 2.X starts index with 0, 1.X starts with 1
  # (and this is how it will be returned!)
  # NOTE: Xcal 1.X will be shorter by one (doesn't have the o/x string!)
  # [(Int) index, time (Float), %A (Float), %B (Float), %C (Float), %D (Float),
  # FlowRate (Float), o/x (String)]
  def self.table_row_to_pieces(line,xcal_version='2.0')
    string = read_thermo_string(line)
    if xcal_version >= '2.0'
      # at first, I thought you could just split on spaces, but the table is
      # designed to have a certain number of chars per column padded with
      # spaces.  This is hte way to do it.
      index = string[0,4].to_i
      (tm, a, b, c, d) = (0...5).to_a.map do |x|
        string[(x*6)+4,6].rstrip.to_f
      end
      fr = string[34,7].rstrip.to_f
      ox = string[41,4].rstrip
      [index, tm, a, b, c, d, fr, ox]
    else
      index = string[0,5].lstrip.to_i # correct
      tm = string[5,13].lstrip.to_f # correct
      #puts "**" + string[18,16] + "**"
      fr = string[18,16].lstrip.to_f
      (a,b,c,d) = (0..3).to_a.map do |x|
        string[(x*8)+34, 8].lstrip.to_f # correct
      end
      [index, tm, a, b, c, d, fr]
    end
  end

  # takes a filehandle
  # returns an array of gradient programs from a thermo filehandle.
  # Acceptable file types include a .meth file and a .raw file
  def self.all_from_handle(fh)
    # 0005340: 3000 2e00 3000 3000 0a00 0a00 5300 6100  0...0.0.....S.a.
    # 0005350: 6d00 7000 6c00 6500 2000 5000 7500 6d00  m.p.l.e. .P.u.m.
    # 0005360: 7000 2000 6700 7200 6100 6400 6900 6500  p. .g.r.a.d.i.e.
    # 0005370: 6e00 7400 2000 7400 6100 6200 6c00 6500  n.t. .t.a.b.l.e.
    # 0005380: 3a00 0a00 0a00 4e00 6f00 2e00 2000 5400  :.....N.o... .T.
    # 0005390: 6900 6d00 6500 2000 2000 4100 2500 2000  i.m.e. . .A.%. .
    # 00053a0: 2000 2000 2000 4200 2500 2000 2000 2000   . . .B.%. . . .
    # 00053b0: 2000 4300 2500 2000 2000 2000 2000 4400   .C.%. . . . .D.
    # 00053c0: 2500 2000 2000 2000 2000 b500 6c00 2f00  %. . . . ...l./.
    # 00053d0: 6d00 6900 6e00 2000 0a00 3000 2000 2000  m.i.n. ...0. . .
    # 00053e0: 2000 3000 2e00 3000 3000 2000 2000 3000   .0...0.0. . .0.
    # 00053f0: 2e00 3000 2000 2000 2000 3000 2e00 3000  ..0. . . .0...0.
    # 0005400: 2000 2000 2000 3100 3000 3000 2e00 3000   . . .1.0.0...0.
    programs = []
    while (gp = get_gradient_program(fh))
      programs << gp 
    end
    programs
  end

  def self.read_thermo_string(string)
    chars = []
    (0...string.size).step(2) do |i|
      chars << string[i,1]
    end
    chars.join
  end

  def self.read_thermo_string_as_hex(string)
    chars = []
    (0...string.size).step(4) do |i|
      chars << string[i,2]
    end
    [chars.join].pack('H*')
  end


end

class GradientProgram::TimePoint
  # time in minutes
  attr_accessor :time
  # flow_rate in ul/min
  attr_accessor :flow_rate
  # percentages
  attr_accessor :percentages

  def initialize(time=nil, flow_rate=nil, percentages=[])
    @time = time
    @flow_rate = flow_rate
    @percentages = percentages
  end

  def ==(other)
    self.class == other.class and @time==other.time and @flow_rate == other.flow_rate and @percentages == other.percentages
  end
end


