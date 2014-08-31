# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"

#require "backports/1.9.1/array/sample"
require_relative "cardtypes"
require_relative "configreader"
require_relative "deckreader"
require_relative "deckselector"
require_relative "statereader"
require_relative "woeid"
require_relative "trendgetter"
require "twitter"

module TrendsAgainstHumanity
   class TwitterGenerator
      def initialize(dry_run = true)
         @dry_run = dry_run

         @white_deck = Hash.new
         @black_deck = Hash.new

         cfg = ConfigReader.new

         @state = StateReader.new

         if @dry_run then
            @client = nil
         else
            @client = Twitter::Client.new({
               :consumer_key => cfg.consumer_key,
               :consumer_secret => cfg.consumer_secret,
               :access_token => cfg.oauth_token,
               :access_token_secret => cfg.oauth_token_secret})
         end

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
      def get_white_deck(woeid = WOEID_WORLD, ignore_list = [])
         if (!@white_deck.has_key?(woeid)) then
            options = Hash.new
            options[:dummy]  = @dry_run
            options[:client] = @client
            options[:woeid]  = woeid
            options[:ignore] = ignore_list

            trends = TrendGetter.new.get_trends(options);
            deck = trends.map do |t| WhiteCard.new(t.name) end

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

      def generate_phrase
         # keep picking cards until we find one we haven't used recently.
         black_deck = nil
         black_card = nil
         attempts = 0

         recent_questions = @state.get_recently_used_questions({:count => 40})

         loop do
            deck_name = DeckSelector.new.select_deck
            black_deck = get_black_deck(deck_name)
            black_card = black_deck.sample

            # if we haven't used it before, go ahead.
            break if recent_questions.index(black_card.text) == nil

            # if we've tried ten times and each time was something we've used before...
            # well, that's unfortunate, we'll just use it anyway.
            attempts = attempts + 1
            break if (attempts > 10)
         end

         # save this so we don't use it again for a while
         @state.add_recently_used_question(black_card.text)

         # get the white deck (trends) appropriate for the card we picked.
         recent_trends = @state.get_recently_used_trends({:count => 40})
         white_deck = get_white_deck(black_card.woeid, recent_trends)

         # pick the right number of white cards to go with it
         white_cards = nil
         attempts = 0
         loop do
            white_cards = white_deck.sample(black_card.pick)

            break if (recent_trends.count == 0) || (recent_trends & white_cards.map { |x| x.text } == [])

            attempts = attempts + 1
            break if (attempts > 10)
         end

         # save the trends so we don't use them again for a while
         white_cards.each do |c|
            @state.add_recently_used_trend(c.text);
         end

         return render_for_twitter(black_card, white_cards)
      end

      def generate
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
            attempts = 0
            loop do
               break if attempts > 3

               begin
                  @client.update(phrase)
               rescue Twitter::Error::ServiceUnavailable => error
                  # over capacity, probably! Wait one minute and try again.
                  attempts = attempts + 1
                  sleep(1.0)
               end

               break
            end
         else
            # If we're not posting to twitter, then output to stdout.
            puts phrase
         end
      end
   end
end
