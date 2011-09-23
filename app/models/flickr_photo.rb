require 'json'

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

