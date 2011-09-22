class CreateTwitterSearches < ActiveRecord::Migration
  def change
      create_table :twitter_searches do |t|
          t.text :search_term
          t.text :response_json
          t.text :tweet_text
          t.timestamps
      end
  end
end
