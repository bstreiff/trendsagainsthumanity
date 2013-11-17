#!/usr/bin/ruby

# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require "common/configreader"
require "common/statereader"
require "common/trendgetter"
require "multi_json"

cfg = TrendsAgainstHumanity::ConfigReader.new
state = TrendsAgainstHumanity::StateReader.new

woeids = [ 1, 23424977, 23424975, 23424775 ]

trends_root = Hash.new

woeids.each do |woeid|
   trends = state.get_top_trends({:woeid => woeid, :count => 30});

   trends_object = trends.map do |x|
      { "name" => x.name, "url" => x.url }
   end

   trends_root[woeid.to_s] = trends_object
end

str = MultiJson.dump(trends_root);
puts "/* trends data as of #{DateTime.now.to_s} */"
puts "var trends = #{str}"
