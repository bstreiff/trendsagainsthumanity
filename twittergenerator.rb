# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"

require "backports/1.9.1/array/sample"
require "cardtypes"
require "configreader"
require "deckreader"
require "deckselector"
require "twitter"

module TrendsAgainstHumanity

   # "Where on Earth ID"s for querying trends.
   WOEID_WORLD = 1
   WOEID_UNITED_STATES = 23424977
   WOEID_CANADA = 23424775
   WOEID_UNITED_KINGDOM = 23424975

   USED_RECENTLY_FILE = 'usedrecently.cfg'

   class TwitterGenerator
      def initialize(dry_run = true)
         @dry_run = dry_run

         @white_deck = Hash.new
         @black_deck = Hash.new
      end

      # Pretty print a list.
      def english_print(ary)
         if (ary.count == 0)
            return ""
         elsif (ary.count == 1)
            return "#{ary[0]}"
         elsif (ary.count == 2)
            return "#{ary[0]} and #{ary[1]}"
         else # >= 3
            # a, b, c, and d
            return ary.slice(0, ary.count-1).join(", ") + ", and " + ary[-1].to_s;
         end
      end

      # Convert a string like '\u201c' into its character.
      # This contortion is because I'm still on Ruby 1.8.
      def codepoint(str)
         return str.gsub(/\\u[\da-f]{4}/i) { |m| [m[-4..-1].to_i(16)].pack('U') }
      end

      # Gets the 'white card' deck of trends.
      #
      # This memoizes, because it's possible (although unlikely) that we might need
      # to generate multiple phrases. When we do that, we don't want to re-request
      # the trend list from Twitter if we don't have to.
      def get_white_deck(woeid = WOEID_WORLD)
         if (!@white_deck.has_key?(woeid)) then
            deck = []
            if (!@dry_run) then
               trends = Twitter.trends(woeid)

               trends.each do |t|
                  deck << WhiteCard.new(t.name)
               end
            else
               # Populate with dummy data.
               if (woeid == WOEID_UNITED_STATES) then
                  deck << WhiteCard.new("Bald Eagles")
                  deck << WhiteCard.new("SUVs")
                  deck << WhiteCard.new("Gigantic Trucks")
                  deck << WhiteCard.new("Guns")
                  deck << WhiteCard.new("Cars")
                  deck << WhiteCard.new("Explosions")
                  deck << WhiteCard.new("Liberty")
                  deck << WhiteCard.new("Barack Obama")
                  deck << WhiteCard.new("Marines")
                  deck << WhiteCard.new("Apple Pie")
               elsif (woeid == WOEID_CANADA)
                  deck << WhiteCard.new("Justin Bieber")
                  deck << WhiteCard.new("Stephen Harper")
                  deck << WhiteCard.new("Mounties")
                  deck << WhiteCard.new("The Molson Muscle")
                  deck << WhiteCard.new("Quebec Sepratists")
                  deck << WhiteCard.new("Hockey")
                  deck << WhiteCard.new("The Leafs")
                  deck << WhiteCard.new("Tim Horton")
                  deck << WhiteCard.new("Canucks")
                  deck << WhiteCard.new("Rob Ford")
               elsif (woeid == WOEID_UNITED_KINGDOM)
                  deck << WhiteCard.new("Lorries")
                  deck << WhiteCard.new("Lifts")
                  deck << WhiteCard.new("Loos")
                  deck << WhiteCard.new("Favourites")
                  deck << WhiteCard.new("Victoria Beckham")
                  deck << WhiteCard.new("Queen Elizabeth II")
                  deck << WhiteCard.new("Scotland")
                  deck << WhiteCard.new("The Welsh")
                  deck << WhiteCard.new("Dickens")
                  deck << WhiteCard.new("Arthur Conan Doyle")
               else
                  deck << WhiteCard.new("Music")
                  deck << WhiteCard.new("People")
                  deck << WhiteCard.new("Stuff")
                  deck << WhiteCard.new("Things")
                  deck << WhiteCard.new("Objects")
                  deck << WhiteCard.new("Generics")
                  deck << WhiteCard.new("Shows")
                  deck << WhiteCard.new("Gadgets")
                  deck << WhiteCard.new("Widgets")
                  deck << WhiteCard.new("Matter")
               end
            end

            @white_deck[woeid] = deck
         end

         return @white_deck[woeid]
      end

      def get_black_deck(name = "base")
         if (!@black_deck.has_key?(name)) then
            @black_deck[name] = DeckReader.new("decks/#{name}.xml").deck         
         end

         return @black_deck[name]
      end

      # apply the text inline. there are two different ways to do this:
      # - If the text has <blank/>s in it, we replace the blanks with the words.
      # - If the text does not have any <blank/>s, we do it up as a list and attach it to the end.
      def render_for_twitter(black_card, white_cards)
         text = black_card.text.dup
         white_card_words = white_cards.map { |x| x.text }

         pattern = /<blank\/>/

         # insert the words inline
         while (!text.index(pattern).nil?)
            text.sub!(/<blank\/>/, "&lsaquo;#{white_card_words.shift}&rsaquo;")
         end

         # Stick anything left over at the end.
         if (white_card_words.count > 0)
            text = text + " " +  english_print(white_card_words) + "."
         end

         # One card uses <em> that we can't represent on Twitter.
         text.gsub!(/<em>/, "")
         text.gsub!(/<\/em>/, "")

         # Some cards have forced linebreaks.
         text.gsub!(/<br\/>/, "\n")

         # Fix up HTML entities.
         text.gsub!(/&ldquo;/,  codepoint('\u201c'))
         text.gsub!(/&rdquo;/,  codepoint('\u201d'))
         text.gsub!(/&reg;/,    codepoint('\u00ae'))
         text.gsub!(/&lsaquo;/, codepoint('\u2039'))
         text.gsub!(/&rsaquo;/, codepoint('\u203a'))
         text.gsub!(/&iacute;/, codepoint('\u00ed'))
         text.gsub!(/&amp;/, '&')

         return text
      end

      def generate_phrase(usedrecently)
         # keep picking cards until we find one we haven't used recently.
         black_deck = nil
         black_card = nil
         attempts = 0

         loop do
            deck_name = DeckSelector.new.select_deck
            black_deck = get_black_deck(deck_name)
            black_card = black_deck.sample

            # if we haven't used it before, go ahead.
            break if usedrecently.index(black_card.text) == nil

            # if we've tried ten times and each time was something we've used before...
            # well, that's unfortunate, we'll just use it anyway.
            attempts = attempts + 1
            break if (attempts > 10)
         end

         # save this so we don't use it again for a while
         open(USED_RECENTLY_FILE, 'a') do |f|
            f.puts black_card.text
         end

         # get the white deck (trends) appropriate for the card we picked.
         white_deck = get_white_deck(black_card.woeid)

         # pick the right number of white cards to go with it
         white_cards = white_deck.sample(black_card.pick)

         return render_for_twitter(black_card, white_cards)
      end

      def generate
         cfg = ConfigReader.new

         usedrecently = []
         if File.exists?(USED_RECENTLY_FILE) then
            File.readlines(USED_RECENTLY_FILE).each do |line|
               usedrecently << line.strip
            end
         end

         Twitter.configure do |config|
            config.consumer_key = cfg.consumer_key
            config.consumer_secret = cfg.consumer_secret
            config.oauth_token = cfg.oauth_token
            config.oauth_token_secret = cfg.oauth_token_secret
         end

         # Generate phrases until we get one under 140 characters.
         phrase = ""
         loop do
            phrase = generate_phrase(usedrecently)

            # Get the length, in characters. String.length isn't correct for Unicode
            # strings in Ruby 1.8.
            # (http://stackoverflow.com/questions/3604916/length-of-a-unicode-string)
            phrase_length = phrase.scan(/./mu).size

            break if phrase_length <= 140
         end

         # Try to post it!
         if (!@dry_run)
            Twitter.update(phrase)
         else
            # If we're not posting to twitter, then output to stdout.
            puts phrase
         end
      end
   end
end
