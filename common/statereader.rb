# Trends Against Humanity
#
# See LICENSE for license details.

require "rubygems"
require "sqlite3"

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
