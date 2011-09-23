class CreateTwitflickSearches < ActiveRecord::Migration
  def change
    create_table :twitflick_searches do |t|
      t.integer :twitter_search_id
      t.integer :flickr_search_id

      t.timestamps
    end
  end
end
