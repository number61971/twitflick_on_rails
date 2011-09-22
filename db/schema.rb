# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110920210845) do

  create_table "flickr_searches", :force => true do |t|
    t.text     "search_term"
    t.text     "response_json"
    t.text     "img_url"
    t.text     "page_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twitflick_searches", :force => true do |t|
    t.integer  "twitter_search_id"
    t.integer  "flickr_search_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "twitter_searches", :force => true do |t|
    t.text     "search_term"
    t.text     "response_json"
    t.text     "tweet_text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
