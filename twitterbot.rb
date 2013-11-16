#!/usr/bin/ruby

# Trends Against Humanity
#
# See LICENSE for license details.

require "optparse"
require "common/twittergenerator"

options = {}

options[:dryrun] = true

opt_parser = OptionParser.new do |opt|
   opt.on("-p","--post","post to twitter (live mode)") do
      options[:dryrun] = false
   end
end

opt_parser.parse!

TrendsAgainstHumanity::TwitterGenerator.new(options[:dryrun]).generate
