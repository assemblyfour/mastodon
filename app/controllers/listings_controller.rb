class ListingsController < ApplicationController
  before_action :set_body_classes

  layout 'public'

  def index
    @results = ListingSearchService.new.call(params[:query])
    @listings = Status.includes(:media_attachments, :mentions, :stream_entry).where(Status.arel_table[:id].in(@results[:listings].map(&:id)))
    @placeholder = <<~TEXT
      [introduce yourself!]

      Tags: [for example: #GFE #PSE #Massage #Companion]
      Location: [City, State, Country]
      Contact: [mobile, email, link]

      #swlisting
    TEXT
  end

  private

  def set_body_classes
    @body_classes = 'about-body'
  end

end

