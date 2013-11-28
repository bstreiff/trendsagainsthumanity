#!/usr/bin/ruby
#
# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require "rexml/document"
require "multi_json"

def read_deck_file(filename)
   file = File.new(filename);
   doc = REXML::Document.new(file);

   deck = Hash.new

   cards = []

   if doc.root.attributes["woeid"].nil? then
      deck["woeid"] = 1 # "World"
   else
      deck["woeid"] = doc.root.attributes["woeid"].to_i
   end

   doc.root.each_element("card") do |card|
      obj = Hash.new

      if !card.attributes["pick"].nil? then
         obj["pick"] = card.attributes["pick"].to_i
      end

      if !card.attributes["draw"].nil? then
         obj["draw"] = card.attributes["draw"].to_i
      end

      if !card.attributes["woeid"].nil? then
         obj["woeid"] = card.attributes["woeid"].to_i
      end

      text = ""
      card.each do |child|
         text = text + child.to_s
      end

      obj["text"] = text;

      cards << obj;
   end

   deck["cards"] = cards;

   return deck;
end

deck_names = ["base_us", "base_uk", "1stexp", "2ndexp", "3rdexp", "4thexp", "holiday", "canada"];

decks = Hash.new

deck_names.each do |d|
   decks[d] = read_deck_file("decks/#{d}.xml")

   decks[d]["icon"] = "base.svg"
   # I have icons for these.
   decks[d]["icon"] = "#{d}.svg" if (d == "1stexp" || d == "2ndexp" || d == "3rdexp")
end

str = MultiJson.dump(decks)
puts "var decks = #{str}"
