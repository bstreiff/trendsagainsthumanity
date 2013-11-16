# Trends Against Humanity
#
# See LICENSE for license details.

require "rexml/document"

# Loads a configuration file. The format is XML:
# <config>
#    <consumer_key>...</consumer_key>
#    <consumer_secret>...</consumer_secret>
#    <oauth_token>...</oauth_token>
#    <oauth_token_secret>...</oauth_token_secret>
# </config>

module TrendsAgainstHumanity
   class ConfigReader
      def initialize(filename = "login.cfg")
         file = File.new(filename)
         doc = REXML::Document.new(file);

         @consumer_key = doc.get_text("config/consumer_key").to_s;
         @consumer_secret = doc.get_text("config/consumer_secret").to_s;
         @oauth_token = doc.get_text("config/oauth_token").to_s;
         @oauth_token_secret = doc.get_text("config/oauth_token_secret").to_s;
      end
         
      attr_reader :consumer_key
      attr_reader :consumer_secret
      attr_reader :oauth_token
      attr_reader :oauth_token_secret
   end
end
