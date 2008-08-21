

module XMLParserWrapper
  def parse_and_report(file, const, report_method=:report)
    parse_and_report_string(IO.read(file), const, report_method)
  end

  def parse_and_report_string(string, const, report_method=:report)
    parser = self.class.const_get(const).new
    parser.parse(string)
    parser.send(report_method)
  end

  def parse_and_report_io(io, const, report_method=:report) 
    parser = self.class.const_get(const).new
    parser.parse(io)
    parser.send(report_method)
  end
end
