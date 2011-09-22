require "json"
require 'test_helper'

class TwitflickControllerTest < ActionController::TestCase
    test "should get index" do
        get :index
        assert_response :success
        assert_not_nil assigns(:data)
        assert_instance_of(ActiveSupport::HashWithIndifferentAccess,
                           assigns(:data))
        assert assigns(:data)["stat"] == "ok"
    end

    test "twitflick/index route gets the index" do
        get "index"
        assert_response :success
        assert_not_nil assigns(:data)
        assert_instance_of(ActiveSupport::HashWithIndifferentAccess,
                           assigns(:data))
        assert assigns(:data)["stat"] == "ok"
    end

    test "twitflick/index.html route gets the index" do
        get("index", {:format => "html"})
        assert_response :success
        assert_not_nil assigns(:data)
        assert_instance_of(ActiveSupport::HashWithIndifferentAccess,
                           assigns(:data))
        assert assigns(:data)["stat"] == "ok"
        assert_equal(@response.content_type, "text/html")
    end

    test "twitflick/index.json route returns json data" do
        get("index", {:format => "json"})
        assert_response :success
        assert_not_nil assigns(:data)
        assert_instance_of(ActiveSupport::HashWithIndifferentAccess,
                           assigns(:data))
        assert assigns(:data)["stat"] == "ok"
        assert_equal(@response.content_type, "application/json")
    end

    test "querying twitter returns the expected response" do
        tweet, twitter_search = search_twitter

        # test tweet object
        assert tweet.data.include?("error") == false
        assert tweet.data.include?("completed_in")
        assert_equal(tweet.data["results_per_page"], 1)
        assert tweet.data["results"].length > 0

        # test twitter_search database object
        assert (twitter_search.id != nil and twitter_search.id > 0)

        # ensure that tweet and twitter_search represent the same data
        assert_equal(tweet.data, JSON.parse(twitter_search.response_json))
    end

    test "querying flickr returns the expected response" do
        # this is very much a behavioral test because flickr returns
        # unpredictable output
        term = "getty"
        flickr_photo, flickr_search = search_flickr(term)

        # test flickr_photo object ... which may be nil!
        assert (flickr_photo == nil or flickr_photo.data["stat"] == "ok")

        if flickr_photo
            assert (flickr_photo.data.include?("photo") or
                    flickr_photo.data.include?("photos"))

            # test flickr_search_database_object
            assert flickr_search.id > 0

            # ensure that flickr_photo and flickr_search represent the same data
            if (flickr_photo and flickr_photo.data.include?("photo"))
                assert_equal(flickr_photo.data,
                             JSON.parse(flickr_search.response_json))
            end
        end

    end

end
