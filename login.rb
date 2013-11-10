#!/usr/bin/ruby
#
# Trends Against Humanity
#
# See LICENSE for license details.


# Log into Twitter so I can get an OAuth token for the bot user.
# The twitter gem doesn't exactly make it straightforward to do.
#
# Hacked-up from https://gist.github.com/iterationlabs/969776

require "ConfigReader"
require "rubygems"
require "twitter"
require "oauth"

# Read config for consumer_key and consumer_secret.
cfg = TrendsAgainstHumanity::ConfigReader.new

Twitter.configure do |config|
   config.consumer_key = cfg.consumer_key
   config.consumer_secret = cfg.consumer_secret
end

oauth_consumer = OAuth::Consumer.new(
   cfg.consumer_key, cfg.consumer_secret,
   :site => "http://api.twitter.com",
   :request_endpoint => "http://api.twitter.com",
   :sign_in => true)

request_token = oauth_consumer.get_request_token
rtoken  = request_token.token
rsecret = request_token.secret
 
puts "Now visit the following URL:"
puts request_token.authorize_url
 
print "What was the PIN twitter provided you with? "
pin = gets.chomp
 
begin
   OAuth::RequestToken.new(oauth_consumer, rtoken, rsecret)
   access_token = request_token.get_access_token(:oauth_verifier => pin)
 
   puts "oauth_token: " + access_token.token
   puts "oauth_token_secret: " + access_token.secret
 
   Twitter.configure do |config|
      config.consumer_key = cfg.consumer_key
      config.consumer_secret = cfg.consumer_secret
      config.oauth_token = access_token.token
      config.oauth_token_secret = access_token.secret
   end
 
   Twitter::Client.new.verify_credentials
rescue Twitter::Unauthorized
   puts "> FAIL!"
end
