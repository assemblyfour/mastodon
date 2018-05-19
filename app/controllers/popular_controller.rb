class PopularController < ApplicationController
  layout 'public'


  REBLOG_WEIGHTING = 1
  FAVOURITE_WEIGHTING = 1
  CONVERSATION_WEIGHTING = 2
  def index
    @popular = Rails.cache.fetch("popular/#{page}", expires_in: 5.minutes, race_condition_ttl: 10.seconds) do
      Status.local
            .includes(:account, :preview_cards, :mentions, :conversation)
            .with_public_visibility
            .where('reblogs_count + favourites_count > ?', threshold)
            .where('created_at BETWEEN ? AND ?', page.days.ago, (page - 1).days.ago)
            .reorder('reblogs_count + favourites_count DESC')
            .limit(100)
    end
    @page = page
  end

  protected

  def threshold
    (params[:threshold].presence || 20).to_i
  end

  def page
    (params[:page].presence || 1).to_i
  end

end
