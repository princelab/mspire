#!/usr/bin/ruby

require 'spec_id/precision/filter'

SpecID::Precision::Filter.new.filter_and_validate_cmdline(ARGV)
