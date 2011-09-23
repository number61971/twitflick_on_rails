require 'json'
require 'cgi'

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

