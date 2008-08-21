#!/usr/bin/ruby -w

require 'spec_id/protein_summary'

ProteinSummary.new.create_from_command_line_args(ARGV)

