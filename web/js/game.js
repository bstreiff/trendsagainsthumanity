var deckinfo = [
   ["base_us", decks["base_us"].cards.length],
   ["base_uk", decks["base_uk"].cards.length],
   ["1stexp", decks["1stexp"].cards.length],
   ["2ndexp", decks["2ndexp"].cards.length],
   ["3rdexp", decks["3rdexp"].cards.length],
   ["canada", decks["canada"].cards.length],
   ["holiday", decks["holiday"].cards.length]
];

var blank_pattern = "<blank/>";

Array.prototype.clone = function() { return this.slice(0); }
String.prototype.clone = function() { return this.slice(0); }
Array.prototype.sample = function(count)
{
   if (typeof count == 'undefined')
   {
      return this[Math.floor(Math.random()*this.length)];
   }
   else
   {
      count = +count;
      if (count > this.length)
      {
      	count = this.length;
      }

      result = this.clone();
      for (i = 0; i < count; i++)
      {
         r = i + Math.floor(Math.random() * (this.length - i));
         tmp = result[i];
         result[i] = result[r];
         result[r] = tmp;
      }
      return result.slice(0, count);
   }
}
Array.prototype.englishify = function() 
{
   if (this.length == 0)
      return ""
   else if (this.length == 1)
      return this[0].toString();
   else if (this.length == 2)
      return this[0].toString() + " and " + this[1].toString();
   else /* >= 3 */
      return this.slice(0, this.length-1).join(", ") + ", and " + this[this.length-1].toString();
}

function select_deck()
{
   var totalWeight = 0;
   var cumulativeWeight = 0;
   for (var i = 0; i < deckinfo.length; i++)
   {
      totalWeight += deckinfo[i][1];
   }
   var random = Math.floor(Math.random() * totalWeight);
   for (var i = 0; i < deckinfo.length; i++)
   {
      cumulativeWeight += deckinfo[i][1];
      if (random < cumulativeWeight)
      {
         return deckinfo[i][0];
      }
   }
}

function get_black_deck(name)
{
   return decks[name];
}

function get_white_deck(woeid)
{
   if (trends.hasOwnProperty(woeid))
      return trends[woeid];
   else
      return trends["1"];
}

function render_phrase_as_string(black_card, white_cards)
{
   var text = black_card.text.clone()
   var white_card_stack = white_cards.clone();

   while (text.indexOf(blank_pattern) != -1)
   {
      card = white_card_stack.shift();
      replacement = "&lsaquo;<a href=\"" + card.url + "\">" + card.name + "</a>&rsaquo;";

      text = text.replace(blank_pattern, replacement);
   }

   if (white_card_stack.length > 0)
   {
      text = text + " " + white_card_stack.map(function(x){return "<a href=\""+x.url+"\">"+x.name+"</a>";}).englishify() + "."
   }

   return text;
}

function replace_blanks(orig_text)
{
   var text = orig_text.clone()
   while (text.indexOf(blank_pattern) != -1)
   {
      text = text.replace(blank_pattern, "____________");
   }
   return text;
}

function get_blank_count(black_card)
{
   var pos = 0;
   var count = 0;
   while ((pos = black_card.text.indexOf(blank_pattern, pos)) != -1)
   {
      count++;
      pos = pos + 1;
   }

   if (count == 0)
      return 1;
   else
      return count;
}

function fixup_decks()
{
   for (deck_name in decks)
   {
      len = decks[deck_name].cards.length;
      for (i = 0; i < len; i++)
      {
         card = decks[deck_name].cards[i];

         if (typeof card.pick == 'undefined')
         {
            card.pick = get_blank_count(card)
         }

         if (typeof card.draw == 'undefined')
         {
            if (card.pick >= 3)
               card.draw = card.pick - 1;
            else
               card.draw = 0;
         }

         if (typeof card.woeid == 'undefined')
         {
            card.woeid = decks[deck_name].woeid
         }
      }
   }
}

function generate()
{
   var deck_name = select_deck();
   var black_deck = get_black_deck(deck_name);
   var black_card = black_deck.cards.sample();

   var woeid = black_deck.woeid;
   if (typeof black_card.woeid !== 'undefined')
   {
      woeid = black_card.woeid;
   }

   var white_deck = get_white_deck(woeid);
   var white_cards = white_deck.sample(black_card.pick);

   return {black:black_card, black_icon:black_deck.icon, whites:white_cards}
}

function generate_phrase()
{
   var selection = generate();
   return render_phrase_as_string(selection.black, selection.whites)
}

function big_digit(i)
{
   var c = 0;
   if (i == 0)
      c = 9471;
   else if (i <= 10)
      c = 10101 + i;
   else
      c = 9440 + i;

   return "&#" + c.toString() + ";"
}

function add_card(options)
{
   var t = "<div class=\"card ";

   if (options.black == true)
      t += "blackcard";
   else
      t += "whitecard";

   t += "\"";

   if (options.style)
   {
      t += " style=\"" + options.style + "\"";
   }

   t += ">";

   t += "<div class=\"text\">" + replace_blanks(options.text) + "</div>";
   t += "<div class=\"logo\"><img src=\"img/" + options.badge + "\" />" + options.logo_text + "</div>";

   draw = 0;
   pick = 0;
   if (typeof options.draw !== 'undefined')
      draw = +(options.draw);
   if (typeof options.pick !== 'undefined')
      pick = +(options.pick);

   if (draw > 1 || pick > 1)
   {
      t += "<div class=\"pick\">";
      if (draw > 1)
         t += "Draw <span class=\"digit\">" + big_digit(draw) + "</span><br />";
      if (pick > 1)
         t += "Pick <span class=\"digit\">" + big_digit(pick) + "</span>";      
      t += "</div>";
   }

   t += "</div>";

   $(t).hide().appendTo("#playfield").fadeIn({ duration: 500 });
}

function play()
{
   $("#playfield").empty();

   var round = generate();

   add_card({black: true, text:round.black.text, badge:round.black_icon, logo_text:"Cards Against Humanity", draw:round.black.draw, pick:round.black.pick});

   for (var i = 0; i < round.whites.length; i++)
   {
      text = "<a href=\"" + round.whites[i].url + "\">" + round.whites[i].name + "</a>";
      add_card({text:text, badge:"trend.svg", logo_text:"Twitter Trends"});
   }

   var caption = "<p>" + render_phrase_as_string(round.black, round.whites) + " (<a href=\"javascript:play()\">Another round?</a>)</p>";
   $(caption).appendTo("#playfield");
}
