class ListingsController < ApplicationController
  before_action :set_body_classes

  layout 'public'

  def index
    @results = ListingSearchService.new.call(params[:query])
  end

  private

  def set_body_classes
    @body_classes = 'about-body'
  end

end

