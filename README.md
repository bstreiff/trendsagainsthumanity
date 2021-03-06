Trends Against Humanity
=======================

An experiment in blending Cards Against Humanity ("a free party game for
horrible people") with Twitter ("a free microblogging service for horrible
people").

Basically, I take a CAH black card, and use one or more Twitter Trending
Topics to act as the white cards. The results can be, well, interesting.

It is running on Twitter as @trendagainst:

   https://twitter.com/trendagainst

I might make a 'real' website at some point, but for now this will have to do.

Running it
----------

I originally wrote this against Ruby 1.8.7 (because that was what was on Ubuntu 12.04).
I've since patched it up to work with 1.9.3 (because that's what's on Ubuntu 14.04).

However, because the Ruby community seems to have no problems with changing integral
functionality such as 'require' outright, functions being removed (Date.jd_to_wday
disappeared at some point), and changes in third-party modules (the Twitter gem
apparently does not believe in a stable API), I find the state of the Ruby community
to be terrible for making any sort of guarantees about long-term viability of any
software written in it.

It you want to try running it yourself, you'll need to register an application with
Twitter in order to get a consumer key and such. When you have those things, create
a configuration and name it login.cfg:

    <config>
    <consumer_key>(your consumer key)</consumer_key>
    <consumer_secret>(your consumer secret)</consumer_secret>
    <oauth_token>(the posting user's oauth token)</oauth_token>
    <oauth_token_secret>(the posting user's token secret)</oauth_token_secret>
    </config>

Disclaimers
-----------

Any posts made by the @trendagainst bot should not be construed to represent my
opinions, nor should they be construed to represent the opinions of Cards Against
Humanity LLC, Twitter, or any other person or entities living or otherwise.

Basically, please don't sue me.

Legal
-----

See the LICENSE file for more details.
