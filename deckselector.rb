# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require "pickup"
require "date"

module TrendsAgainstHumanity
   class DeckSelector
      def is_canada_day(d)
         raise TypeError, "is_canada_day requires a Date" unless d.kind_of?(Date)

         # Canada Day is 1 Jul, unless that date falls on a Sunday, in which
         # case it is observed on 2 Jul.

         weekday = Date.jd_to_wday(d.jd)
         is_sunday = (weekday == 0)
         is_monday = (weekday == 1)

         if (d.day == 1 && d.mon == 6 && !is_sunday) then
            return true
         elsif (d.day == 2 && d.mon == 6 && is_monday) then
            return true
         else
            return false
         end
      end

      def days_until_christmas(d)
         raise TypeError, "days_until_christmas requires a Date" unless d.kind_of?(Date)

         # Christmas is observed on 25 Dec.

         xmas = Date.new(d.year, 12, 25)

         # If Christmas is earlier than today, then Christmas already happened this year.
         # So use next year's.
         if (xmas < d) then
            xmas = Date.new(d.year + 1, 12, 25)
         end

         return (xmas - d)
      end

      def initialize
         today = Date.new(2012,12,25) #Date.today

         weights = Hash.new

         # For the base set and the expansions, the weight is the number of cards
         # in the set.
         weights["base"] = 89
         weights["1stexp"] = 20
         weights["2ndexp"] = 25
         weights["3rdexp"] = 25

         # The canada set is special. Normally, it has a weight of 9.
         # However, on Canada Day, we double the weight.

         if is_canada_day(today) then
            weights["canada"] = 18
         else
            weights["canada"] = 9
         end

         # The holiday set is also special. It only gets added if we are twenty days
         # away from Christmas. The weight increases the closer to Christmas we are.
         # (This gives us effectively a ~20% chance on Christmas day.)
         days_left = days_until_christmas(today)
         if (days_left <= 20) then
            weights["holiday"] = (20 - days_left)*2
         end

         @weights = weights
      end

      def select_deck
         return Pickup.new(@weights).pick
      end
   end
end
