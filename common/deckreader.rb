# Trends Against Humanity
#
# See LICENSE for license details.

require "rexml/document"
require_relative "cardtypes"

module TrendsAgainstHumanity
   class DeckReader
      def initialize(filename)
         file = File.new(filename);
         doc = REXML::Document.new(file);

         @deck = []

         if doc.root.attributes["woeid"].nil? then
            base_woeid = 1 # "World"
         else
            base_woeid = doc.root.attributes["woeid"].to_i
         end

         doc.root.each_element("card") do |card|
            pick = 0
            draw = 0
            woeid = 0

            if card.attributes["pick"].nil? then
               # If there's no 'pick' attribute, then determine it by looking at the number of <blank>s in the text.         
               blankCount = 0;
               card.each_element("blank") do
                  blankCount = blankCount + 1
               end

               # If there are no blanks in the text, then assume we pick one.
               if blankCount == 0 then
                  pick = 1
               else
                  pick = blankCount
               end

            else
               pick = card.attributes["pick"].to_i
            end

            if card.attributes["draw"].nil? then
               # At least in the official CAH sets, the only cards with a 'draw' indicator are those
               # where you pick three.
               # So, lets use the following rules:
               # For pick=1 or pick=2, draw=0.
               # For pick=3 or greater, draw=(pick-1).
               draw = pick - 1 if pick >= 3
            else
               draw = card.attributes["draw"].to_i
            end

            if card.attributes["woeid"].nil? then
               woeid = base_woeid
            else
               woeid = card.attributes["woeid"].to_i
            end

            text = ""
            card.each do |child|
               text = text + child.to_s
            end

            @deck << BlackCard.new(text, draw, pick, woeid)
         end
      end

      attr_reader :deck
   end
end
