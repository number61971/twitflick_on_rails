class TwitflickController < ApplicationController
  def index
      tfs = TwitflickSearch.new
      @data = tfs.run_the_search
      respond_to do |format|
          format.html # index.html.erb
          format.json { render :json => @data }
      end
  end

  def update
      @search = TwitflickSearch.new(params[:search_term])
      respond_to do |format|
          format.html { redirect_to root_path }
          format.json { render :json => @data }
      end
  end
end
