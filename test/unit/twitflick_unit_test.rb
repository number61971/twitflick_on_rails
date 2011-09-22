require "json"
require 'test_helper'

class TweetTest < ActionView::TestCase
    # testing the functionality of the Tweet object

    def setup
        sample_twitter_json = '{"completed_in":0.136, "max_id":112333943902175232, "max_id_str":"112333943902175232", "next_page":"?page=2&max_id=112333943902175232&q=getty&rpp=1", "page":1, "query":"getty", "refresh_url":"?since_id=112333943902175232&q=getty", "results":[{"created_at":"Sat, 10 Sep 2011 01:17:53 +0000", "from_user":"Flylife_Mangu", "from_user_id":288892814, "from_user_id_str":"288892814", "geo":null, "id":112333943902175232, "id_str":"112333943902175232", "iso_language_code":"en", "metadata":{"result_type":"recent"}, "profile_image_url":"http://a0.twimg.com/profile_images/1530354129/manguu_normal.jpg", "source":"&lt;a href=&quot;http://levelupstudio.com&quot; rel=&quot;nofollow&quot;&gt;Plume\u00A0\u00A0&lt;/a&gt;", "text":"Somone cop cuz I know.sebbys Getty.isn\'t ganna be all that nut its something", "to_user_id":null, "to_user_id_str":null}], "results_per_page":1, "since_id":0, "since_id_str":"0"}'
        @tweet = Tweet.new(sample_twitter_json)
    end

    def test_text
        text = "Somone cop cuz I know.sebbys Getty.isn't ganna be all that nut its something"
        assert_equal(@tweet.text, text)
    end

    def test_user
        user = "Flylife_Mangu"
        assert_equal(@tweet.user, user)
    end

    def test_profile_image_url
        url = "http://a0.twimg.com/profile_images/1530354129/manguu_normal.jpg"
        assert_equal(@tweet.profile_image_url, url)
    end

    def test_user_url
        url = "http://twitter.com/#!/Flylife_Mangu"
        assert_equal(@tweet.user_url, url)
    end

    def test_tokenize
        # Ensure that all words are extracted from a tweet.
        words = ["Somone", "cop", "cuz", "I", "know", "sebbys", "Getty",
                 "isn't", "ganna", "be", "all", "that", "nut", "its",
                 "something"]
        assert_equal(@tweet.tokenize, words)

        #
        # ad hoc tests
        #

        # no empty words
        data = {
            "results" => [
                {"text" => "@Rafiki58 the song been playing randomly in my " +
                           "mind. Got play other songs to Getty it off my " +
                           "mind.",
                 "from_user" => "Rafiki58",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        words = ["Rafiki58", "the", "song", "been", "playing", "randomly", "in",
                 "my", "mind", "Got", "play", "other", "songs", "to", "Getty",
                 "it", "off", "my", "mind"]
        assert_equal(tweet.tokenize, words)

        # preserve 's contractions and possessives
        data = {
            "results" => [
                {"text" => "Watching Sarah Silverman hold Selma Blair's baby " +
                           "in the Getty portrait studio.",
                 "from_user" => "Rafiki58",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        words = ["Watching", "Sarah", "Silverman", "hold", "Selma", "Blair's",
                 "baby", "in", "the", "Getty", "portrait", "studio"]
        assert_equal(tweet.tokenize, words)

        # "I'm" preserved
        data = {
            "results" => [
                {"text" => "@Mr_desire saturday,I'm having a getty,slideeee",
                 "from_user" => "jeaaanty",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        words = ["Mr_desire", "saturday", "I'm", "having", "a", "getty",
                 "slideeee"]
        assert_equal(tweet.tokenize, words)

        # no URLs
        data = {
            "results" => [
                {"text" => "http://t.co/uH6QEvG Warren Gatland takes in his " +
                           "Wales team's 17-16 defeat by South Africa in " +
                           "Wellington. Photograph: Stu Forster/Getty Im",
                 "from_user" => "Rafiki58",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        words = ["Warren", "Gatland", "takes", "in", "his", "Wales", "team's",
                 "17", "16", "defeat", "by", "South", "Africa", "in",
                 "Wellington", "Photograph", "Stu", "Forster", "Getty", "Im"]
        assert_equal(tweet.tokenize, words)
    end

    def test_extract_flickr_search_term
        term = "know"
        assert_equal(@tweet.extract_flickr_search_term, term)

        #
        # ad hoc tests
        #

        # no empty words so expected term gets pulled out
        data = {
            "results" => [
                {"text" => "@Rafiki58 the song been playing randomly in my " +
                           "mind. Got play other songs to Getty it off my " +
                           "mind.",
                 "from_user" => "Rafiki58",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        term = "been"
        assert_equal(tweet.extract_flickr_search_term, term)

        # no URLs so expected term gets pulled out
        data = {
            "results" => [
                {"text" => "http://t.co/uH6QEvG Warren Gatland takes in his " +
                           "Wales team's 17-16 defeat by South Africa in " +
                           "Wellington. Photograph: Stu Forster/Getty Im",
                 "from_user" => "Rafiki58",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        term = "in"
        assert_equal(tweet.extract_flickr_search_term, term)

        data = {
            "results" => [
                {"text" => "can use the fourth word here",
                 "from_user" => "unittest",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        term = "fourth"
        assert_equal(tweet.extract_flickr_search_term, term)

        data = {
            "results" => [
                {"text" => "too few words",
                 "from_user" => "unittest",
                 "profile_image_url" => "http://somewhwere.com"}
                ],
            }
        tweet = Tweet.new(data.to_json)
        term = nil
        assert_equal(tweet.extract_flickr_search_term, term)

        data = {
            "results" => [
                {"text" => "can't use any that you an the a i That YOU " +
                           "An THE A I",
                 "from_user" => "unittest",
                 "profile_image_url" => "http://somewhere.com"}
                ]
            }
        tweet = Tweet.new(data.to_json)
        term = nil
        assert_equal(tweet.extract_flickr_search_term, term)
    end

end


class FlickrPhotoTest < ActionView::TestCase
    # testing the functionality of the FlickrPhoto object

    def setup
        sample_search_term = "summer"
        sample_flickr_json = '{"photo":{"id":"6132014232", "secret":"18a28c1c65", "server":"6181", "farm":7, "dateuploaded":"1315623756", "isfavorite":0, "license":"0", "safety_level":"0", "rotation":0, "owner":{"nsid":"24085411@N08", "username":"elidanang", "realname":"ELI DANANG", "location":"DANANG, VIETNAM", "iconserver":"0", "iconfarm":0}, "title":{"_content":"eli_summer_farewell_party_sept_2011_112"}, "description":{"_content":""}, "visibility":{"ispublic":1, "isfriend":0, "isfamily":0}, "dates":{"posted":"1315623756", "taken":"2011-09-09 18:32:40", "takengranularity":"0", "lastupdate":"1315623801"}, "views":"1", "editability":{"cancomment":0, "canaddmeta":0}, "publiceditability":{"cancomment":1, "canaddmeta":0}, "usage":{"candownload":1, "canblog":0, "canprint":0, "canshare":1}, "comments":{"_content":"0"}, "notes":{"note":[]}, "people":{"haspeople":0}, "tags":{"tag":[{"id":"23992598-6132014232-3763", "author":"24085411@N08", "raw":"ELI", "_content":"eli", "machine_tag":0}, {"id":"23992598-6132014232-245", "author":"24085411@N08", "raw":"Summer", "_content":"summer", "machine_tag":0}, {"id":"23992598-6132014232-14330", "author":"24085411@N08", "raw":"Farewell", "_content":"farewell", "machine_tag":0}, {"id":"23992598-6132014232-239", "author":"24085411@N08", "raw":"Party", "_content":"party", "machine_tag":0}, {"id":"23992598-6132014232-676190", "author":"24085411@N08", "raw":"2011", "_content":"2011", "machine_tag":0}]}, "urls":{"url":[{"type":"photopage", "_content":"http:\/\/www.flickr.com\/photos\/elidanang\/6132014232\/"}]}, "media":"photo"}, "stat":"ok"}'
        @flickr_photo = FlickrPhoto.new(sample_flickr_json, sample_search_term)
    end

    def test_id
        id = "6132014232"
        assert_equal(@flickr_photo.id, id)
    end

    def test_img_src_url
        # Test that a valid imr src url is constructed from raw flickr data.
        url = "http://farm7.static.flickr.com/6181/6132014232_18a28c1c65_z.jpg"
        assert_equal(@flickr_photo.img_src_url, url)
    end

    def test_get_page_url
        # Test that the flickr page url for a photo is ready for use
        # on a web page.
        url = "http://www.flickr.com/photos/elidanang/6132014232/"
        assert_equal(@flickr_photo.get_page_url, url)
    end

end
