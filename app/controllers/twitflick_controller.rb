require "cgi"
require "json"
require "net/http"
require "uri"

class TwitflickController < ApplicationController
  def index
      @data = twitflick_search
      respond_to do |format|
          format.html # index.html.erb
          format.json { render :json => @data }
      end
  end
end

#
# PAGE RENDERING HELPERS
# (the point of which is to predigest all the data so no business logic
# resides in the view)
#

TWITTER_DEFAULT_SEARCH_TERM = "getty"

def twitflick_search
    #
    # MAIN PROGRAM LOGIC
    #
    # 1. Search twitter for latest tweet containing the default search term
    #    (e.g., "getty")
    # 2. Extract 4th word in tweet as flickr search term
    #    a. UNLESS 4th word is among:
    #         "the", "a", "an", "that", "I", "you"
    #       in which case the next word should be chosen
    #       UNLESS it's also a forbidden word, etc., etc.
    #   b. If no suitable word available, don't search flickr
    #
    # 3. Return the data in a form suitable for direct output to web page.
    #
    tweet, twitter_search = search_twitter
    term = tweet.extract_flickr_search_term
    if term
        flickr_search_term_display = "Searched flickr with <span id=\"" +
                                     "flickr_search_term\">#{term}</span>:"
        flickr_photo, flickr_search = search_flickr(term)
        if flickr_photo
            flickr_display = "<a href=\"#{flickr_photo.get_page_url}\">" +
                             "<img src=\"#{flickr_photo.img_src_url}\"/></a>"
        else
            flickr_display = "No flickr image found!"
        end
    else
        # represent a nonexistent flickr search result with an "empty" record
        flickr_search = FlickrSearch.create({
                            :search_term => nil,
                            :response_json => nil,
                            :img_url => nil,
                            :page_url => nil
                        })
        flickr_search_term_display = "No suitable search term from the tweet " +
                                     "could be extracted."
        flickr_display = ""
    end

    # associate the twitter and flickr searches together as a single
    # twitflick search event and store in database
    twitflick_search = TwitflickSearch.create({
                           :twitter_search_id => twitter_search.id,
                           :flickr_search_id => flickr_search.id
                       })

    # finalize data for page display
    search_count = TwitflickSearch.count
    data = {
        :stat => "ok",
        :twitter_search_term => TWITTER_DEFAULT_SEARCH_TERM,
        :search_count => search_count,
        :search_count_plural => search_count == 1 ? "" : "s",
        :twitter_user_url => tweet.user_url,
        :twitter_user_profile_image_url => tweet.profile_image_url,
        :twitter_user => tweet.user,
        :tweet => tweet.text,
        :flickr_search_term_display => flickr_search_term_display,
        :flickr_display => flickr_display
    }
end

def search_twitter
    # Query twitter for most recent tweet containing the default search term
    # and return Tweet and TwitterSearch instances
    url = "http://search.twitter.com/search.json?" +
          "q=#{CGI.escape(TWITTER_DEFAULT_SEARCH_TERM)}" +
          "&result_type=#{CGI.escape('recent')}" + 
          "&rpp=#{CGI.escape('1')}"
    response_text = http_get(url)
    tweet = Tweet.new(response_text)
    twitter_search = tweet.save_twitter_search
    [tweet, twitter_search]
end

TwitflickAPIKey = "66ece251b8a5443c56195555d8182514"
def search_flickr(term)
    # Search flickr with the supplied search term and return
    # FlickrPhoto and FlickrSearch instances ...
    # ... unless no photo is found, in which case return nil.
    # (flickr returns no results a surprising number of times! Why?)
    _jsonFlickrApi = /^jsonFlickrApi\(\{(.+)\}\)$/
    flickr_api_url = "http://api.flickr.com/services/rest/?"

    url = flickr_api_url +
          "method=#{CGI.escape('flickr.photos.search')}" +
          "&api_key=#{CGI.escape(TwitflickAPIKey)}" +
          "&text=#{CGI.escape(term)}" +
          "&content_type=#{CGI.escape('1')}" +
          "&per_page=#{CGI.escape('1')}" +
          "&format=#{CGI.escape('json')}"
    response_text = http_get(url)
    response_json = response_text.gsub(_jsonFlickrApi, '{\1}')
    response_data = JSON.parse(response_json)

    # Must also query for full photo info to obtain the photo's flickr page url
    # in order to comply with flickr's community guidelines and terms of use
    # for displaying photos outside of flickr.
    # See: http://www.flickr.com/guidelines.gne, http://www.flickr.com/terms.gne
    if response_data["photos"]["photo"].length > 0
        photo_id = response_data["photos"]["photo"].slice(0)["id"]
        url = flickr_api_url +
              "method=#{CGI.escape('flickr.photos.getInfo')}" +
              "&api_key=#{CGI.escape(TwitflickAPIKey)}" +
              "&photo_id=#{CGI.escape(photo_id)}" +
              "&format=#{CGI.escape('json')}"
        response_text = http_get(url)
        response_json = response_text.gsub(_jsonFlickrApi, '{\1}')
        flickr_photo = FlickrPhoto.new(response_json, term)
        flickr_search = flickr_photo.save_flickr_search
    else
        # if the initial flickr search returned no results, e.g.:
        # {u'photos': {u'total': u'0', u'photo': [], u'perpage': 1, u'page': 1, u'pages': 0}, u'stat': u'ok'}
        # there will be no photo data from which an ID may be extracted.
        flickr_photo = nil
        flickr_search = FlickrSearch.create({
                            :search_term => term,
                            :response_json => response_json,
                            :img_url => nil,
                            :page_url => nil
                        })
    end

    [flickr_photo, flickr_search]
end

def http_get(url)
    # convenience function to handle http requests
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host)
    req = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(req)
    response.body
end

#
# useful objects
#
# QUESTION: Is there a better place to define these?
# No Rails documentation I could find described the appropriate place where
# one would define non-db-related (i.e., utility or general-purpose) objects.
#

class Tweet
    attr_reader :data, :text, :user, :profile_image_url, :user_url

    def initialize(search_response_json)
        @data = JSON.parse(search_response_json)
        @text = @data["results"].slice(0)["text"]
        @user = @data["results"].slice(0)["from_user"]
        @profile_image_url = @data["results"].slice(0)["profile_image_url"]
        @user_url = "http://twitter.com/#!/#{CGI.escape(@user)}"
    end

    Apostrophe = "AAAAPOSTROPHEEEE"
    def tokenize
        # Return all the words in the tweet text, preserving apostrophes so that
        # contractions and possessives don't get interpreted as separate words.
        # (I.e., so "can't" doesn't get interpreted as "can" and "t".)
        # Also strip out urls so that they don't get tokenized into "words".
        _url = /\bhttps?:\/\/[^\s]+/
        _s_contraction = /(\w)'([Ss])\b/
        _nt_contraction = /([Nn])'([Tt])\b/
        _im_contraction = /\b([Ii])'([Mm])\b/
        _apostrophe_decode = Regexp.new(Apostrophe)
        _tokenizer = /\W+/

        text = self.text.gsub(_url, '')
        text = text.gsub(_s_contraction, "\\1#{Apostrophe}\\2")
        text = text.gsub(_nt_contraction, "\\1#{Apostrophe}\\2")
        text = text.gsub(_im_contraction, "\\1#{Apostrophe}\\2")
        words = text.split(_tokenizer).select { |w| w != "" }
        words = words.map { |w| w.gsub(_apostrophe_decode, "'") }
    end

    ForbiddenTerms = ["the", "a", "an", "that", "i", "you"]
    def extract_flickr_search_term
        # Extract the flickr search term from the tweet text.
        # It must be the 4th word in the tweet, and it must not be in the list
        # of forbidden words. If the 4th word is forbidden, grab the first word
        # past the 4th that isn't forbidden.
        # If no word matches these conditions, return nil.
        term = nil
        words = self.tokenize
        words[3, words.length-3].each do |word|
            if not ForbiddenTerms.include?(word.downcase)
                term = word
                break
            end
        end
        term
    end

    def save_twitter_search
        # save the search response to the database
        twitter_search = TwitterSearch.create({
                            :search_term => self.data["query"],
                            :response_json => self.data.to_json,
                            :tweet_text => self.text
                         })
    end
end

class FlickrPhoto
    attr_reader :data, :search_term, :id, :img_src_url

    def initialize(search_response_json, search_term)
        @data = JSON.parse(search_response_json)
        @search_term = search_term
        @id = @data["photo"]["id"]
        farm = @data["photo"]["farm"]
        server = @data["photo"]["server"]
        secret = @data["photo"]["secret"]
        @img_src_url = "http://farm#{farm}.static.flickr.com/#{server}/" +
                       "#{@id}_#{secret}_z.jpg"
    end

    def get_page_url
        url_raw = self.data["photo"]["urls"]["url"].slice(0)["_content"]
        url = url_raw.gsub(/\\/, '')
    end

    def save_flickr_search
        # save the search response to the database
        flickr_search = FlickrSearch.create({
                            :search_term => self.search_term,
                            :response_json => self.data.to_json,
                            :img_url => self.img_src_url,
                            :page_url => self.get_page_url
                        })
    end
end

#
# db table model associations
#
# QUESTION: Surely there is a more appropriate place in which to define these...
# I simply could not find one. No Rails documentation I could find told me
# where these would be located in the typical Rails app. :(
# All documentation I could locate simply asserted the magic association between
# a db table and the ActiveRecord associative class once the migration was
# defined. I feel like I shouldn't be required to define these classes at all!
# What am I missing?
#

class TwitterSearch < ActiveRecord::Base
    set_table_name "twitter_searches"
    set_primary_key "id"
end

class FlickrSearch < ActiveRecord::Base
    set_table_name "flickr_searches"
    set_primary_key "id"
end

class TwitflickSearch < ActiveRecord::Base
    set_table_name "twitflick_searches"
    set_primary_key "id"
end
