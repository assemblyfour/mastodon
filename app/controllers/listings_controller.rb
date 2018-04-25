class ListingsController < ApplicationController
  before_action :set_body_classes

  layout 'public'

  def index
    @results = ListingSearchService.new.call(params[:query])
    @listings = Status.includes(:media_attachments, :mentions, :stream_entry).where(Status.arel_table[:id].in(@results[:listings].map(&:id)))
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

    redirect_to %Q|https://switter.at/share?text=#{URI.encode(@text)}|
  end

  private

  def set_body_classes
    @body_classes = 'about-body'
  end

end

