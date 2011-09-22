class CreateFlickrSearches < ActiveRecord::Migration
  def change
      create_table :flickr_searches do |t|
          t.text :search_term
          t.text :response_json
          t.text :img_url
          t.text :page_url
          t.timestamps
      end
  end
end
