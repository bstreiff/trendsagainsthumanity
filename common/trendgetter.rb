# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require "twitter"
require "uri"

module TrendsAgainstHumanity

   class TrendGetter

      # options is hash of:
      #   :dummy => return dummy data
      #   :client => Twitter::Client to use
      #   :ignore => list of trends to ignore
      #   :woeid => WOEID to use
      #
      # Returns an array of Twitter::Trend objects
      def get_trends(options)
         dummy = false;
         client = nil;
         ignore = [];
         woeid = 1;
         
         if (options.has_key?(:dummy)) then
            dummy = !!options[:dummy];
         end

         if (options.has_key?(:client)) then
            client = options[:client];
         end

         if (options.has_key?(:ignore)) then
            ignore = options[:ignore];
         end

         if (options.has_key?(:woeid)) then
            woeid = options[:woeid].to_i;
         end

         if (dummy == true && !client.nil?)
            raise "cannot specify both 'dummy' and a client!"
         elsif (dummy == false && client.nil?)
            raise "must specify one of 'dummy' or a client!"
         end

         if (dummy) then
            # Populate with fake data.
            stereotypes = case woeid
               when WOEID_UNITED_STATES
                  ["Bald Eagles", "SUVs", "Gigantic Trucks", "Guns", "Cars", "Explosions", "Liberty", "Obama", "Marines", "Apple Pie"];
               when WOEID_CANADA
                  ["Justin Bieber", "Stephen Harper", "Mounties", "Molson", "Quebec", "Hockey", "Tim Horton", "Canucks", "Timbits", "Maple Leafs"];
               when WOEID_UNITED_KINGDOM
                  ["Victoria Beckham", "The Welsh", "Fish and Chips", "Beer", "Pubs", "Beefeaters", "Tea", "Cricket", "Bowler Hats", "Queuing"];
               else
                  ["Music", "People", "Stuff", "Things", "Objects", "Generics", "Shows", "Gadgets", "Widgets", "Matter"];
            end

            return stereotypes.map do |s|
               query = nil
               # We need to quote the querystring if there are any spaces.
               if s.index(" ").nil?
                  query = URI.escape(s);
               else
                  query = URI.escape("\"#{s}\"");
               end

               Twitter::Trend.new({
                  :events => nil,
                  :name => s,
                  :promoted_content => nil,
                  :query => query,
                  :url => "http://twitter.com/search/?q=#{query}"
               });
            end
         else
            attempts = 0
            loop do
               break if attempts > 3
               begin
                  return client.trends(woeid)
               rescue Twitter::Error::ServiceUnavailable => error
                  # over capacity maybe, wait one minute and try again.
                  attempts = attempts + 1
                  sleep(1.0)
               end

               break;
            end

            raise "Unable to get trends!"
         end
      end

   end
end
