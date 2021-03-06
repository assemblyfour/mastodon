require 'digest/sha1'
class ListingsController < ApplicationController
  before_action :set_body_classes

  layout 'public'

  def index
    @swlisting_tag = Tag.find_by(name: 'swlisting')
    results = ListingSearchService.new.call(params[:query])
    @listings = Status.includes(:media_attachments, :mentions, :stream_entry, :account).where(Status.arel_table[:id].in(results[:listings].map(&:id)))
  end

  def new

  end

  def create
    @text = <<~TEXT
      #{params[:description]}

      Location: #{params[:location]}
      Contact: #{params[:contact]}

      #swlisting
    TEXT

    redirect_to %Q|https://switter.at/share?text=#{CGI.escape(@text)}|
  end

  private

  def set_body_classes
    @body_classes = 'about-body'
  end

end

