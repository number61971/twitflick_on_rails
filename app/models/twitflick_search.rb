class TwitflickSearch < ActiveRecord::Base
    belongs_to :twitter_searches
    belongs_to :flickr_searches

    TWITTER_DEFAULT_SEARCH_TERM = "getty"
    def initialize(search_term=TWITTER_DEFAULT_SEARCH_TERM)
        @search_term = search_term
    end

    def run_the_search
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
            :twitter_search_term => @search_term,
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
            "q=#{CGI.escape(@search_term)}" +
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

end
