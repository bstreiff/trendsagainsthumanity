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
               # Populate with dummy data. This is a snapshot of what the trends
               # were on the morning of 10 Nov 2013, so that repeated test runs
               # don't burn through the API limit.
               if (woeid == WOEID_CANADA) then
                  deck << WhiteCard.new("#EMAzing")
                  deck << WhiteCard.new("#voteaustinmahone")
                  deck << WhiteCard.new("Rememberance Day")
                  deck << WhiteCard.new("#PeoplesChoice")
                  deck << WhiteCard.new("#iPad")
                  deck << WhiteCard.new("#music")
                  deck << WhiteCard.new("Christmas")
                  deck << WhiteCard.new("Justin Bieber")
                  deck << WhiteCard.new("Canucks")
                  deck << WhiteCard.new("Thor")
               else
                  deck << WhiteCard.new("#voteaustinmahone")
                  deck << WhiteCard.new("#EMAzing")
                  deck << WhiteCard.new("Veterans Day")
                  deck << WhiteCard.new("Typhoon Haiyan")
                  deck << WhiteCard.new("#iPad")
                  deck << WhiteCard.new("#music")
                  deck << WhiteCard.new("#tcot")
                  deck << WhiteCard.new("Philippines")
                  deck << WhiteCard.new("Christmas")
                  deck << WhiteCard.new("Marines")
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
         text.gsub!(/&amp;/, '&')

         return text
      end

      def generate_twitter_text(black_deck, white_deck)
         # pick a card, any card
         black_card = black_deck.sample
         # pick the right number of white cards to go with it
         white_cards = white_deck.sample(black_card.pick)

         return render_for_twitter(black_card, white_cards)
      end

      def generate_phrase
         deck_name = DeckSelector.new.select_deck

         # If we picked the 'canada' deck, then use the trends in Canada instead of US.
         woeid = (deck_name == "canada" ? WOEID_CANADA : WOEID_UNITED_STATES)

         black_deck = get_black_deck(deck_name)
         white_deck = get_white_deck(woeid)
         return generate_twitter_text(black_deck, white_deck)
      end

      def generate
         cfg = ConfigReader.new("/home/brandon/.trendsagainsthumanity.cfg")

         Twitter.configure do |config|
            config.consumer_key = cfg.consumer_key
            config.consumer_secret = cfg.consumer_secret
            config.oauth_token = cfg.oauth_token
            config.oauth_token_secret = cfg.oauth_token_secret
         end

         # Generate phrases until we get one under 140 characters.
         phrase = ""
         loop do
            phrase = generate_phrase

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
