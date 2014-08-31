#!/usr/bin/ruby

# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require_relative "common/configreader"
require_relative "common/statereader"
require_relative "common/trendgetter"
require "twitter"

cfg = TrendsAgainstHumanity::ConfigReader.new

client = Twitter::Client.new({
   :consumer_key => cfg.consumer_key,
   :consumer_secret => cfg.consumer_secret});

state = TrendsAgainstHumanity::StateReader.new

woeids = [ 1, 23424977, 23424975, 23424775 ]

woeids.each do |woeid|
   trends = TrendsAgainstHumanity::TrendGetter.new.get_trends(
      :client => client,
      :woeid => woeid);

   trends.each do |trend|
      state.add_top_trend(trend, woeid);
   end
end
