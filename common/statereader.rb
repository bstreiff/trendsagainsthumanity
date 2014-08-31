# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require "sqlite3"
require "zlib"
require "twitter"

module TrendsAgainstHumanity
   class StateReader
      def initialize(filename = "state.db")
         @database = SQLite3::Database.new(filename);

         @database.execute_batch <<SQL
            CREATE TABLE IF NOT EXISTS question_use (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name TEXT NOT NULL,
               used_at TIMESTAMP DEFAULT (DATETIME('now'))
            );
            CREATE TABLE IF NOT EXISTS trend_use (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               name TEXT NOT NULL,
               used_at TIMESTAMP DEFAULT (DATETIME('now'))
            );
            CREATE TABLE IF NOT EXISTS top_trends (
               id INTEGER PRIMARY KEY,
               name TEXT NOT NULL,
               woeid INTEGER NOT NULL,
               query TEXT NOT NULL,
               url TEXT NOT NULL,
               seen_at TIMESTAMP DEFAULT (DATETIME('now'))
            );
SQL
      end

      def get_recently_used_trends(options)
         return get_recently_used("trend_use", options);
      end
      
      def get_recently_used_questions(options)
         return get_recently_used("question_use", options);
      end

      def add_recently_used_trend(text)
         add_recently_used("trend_use", text);
      end

      def add_recently_used_question(text)
         add_recently_used("question_use", text);
      end

      def get_top_trends(options)
         limit = "";
         if (options.has_key?(:count))
            limit = "LIMIT #{options[:count].to_i}";
         end
         woeid = 1;
         if (options.has_key?(:woeid))
            woeid = options[:woeid].to_i;
         end

         names = [];
         @database.execute("SELECT name, query, url FROM top_trends WHERE woeid = :woeid ORDER BY seen_at DESC #{limit};", woeid) do |result|
            names << Twitter::Trend.new({:name => result[0], :query => result[1], :url => result[2]});
         end

         return names;
      end

      def add_top_trend(trend, woeid)
         id = Zlib::crc32("#{woeid} #{trend.name}");

         @database.execute(
            "INSERT OR REPLACE INTO top_trends (id, name, woeid, query, url) VALUES (:id, :name, :woeid, :query, :url)",
            "id" => id,
            "name" => trend.name,
            "woeid" => woeid,
            "query" => trend.query,
            "url" => trend.url.to_s);
      end

      attr_reader :database      


      private

      # Helper function for get_recently_used_*
      def get_recently_used(table, options)
         # both the trend_use and question_use tables have the same schema.

         limit = "";
         if (options.has_key?(:count))
            limit = "LIMIT #{options[:count].to_i}"
         end

         names = []
         @database.execute("SELECT name, used_at FROM #{table} ORDER BY used_at DESC #{limit};") do |result|
            names << result[0]
         end

         return names
      end

      # Helper function for add_recently_used_*
      def add_recently_used(table, text)
         @database.execute(
            "INSERT INTO #{table} (name) VALUES (:name);",
            "name" => text);
      end

   end
end
