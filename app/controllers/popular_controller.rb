class PopularController < ApplicationController
  layout 'public'


  REBLOG_WEIGHTING = 1
  FAVOURITE_WEIGHTING = 1
  CONVERSATION_WEIGHTING = 2
  def index
    @popular = Status
                .local
                .includes(:account, :preview_cards, :mentions, :conversation)
                .with_public_visibility
                .where('reblogs_count + favourites_count > ?', threshold)
                .where('created_at BETWEEN ? AND ?', page.days.ago, (page - 1).days.ago)
                .reorder('reblogs_count + favourites_count DESC')
                .limit(25)
                .sort_by { |s|
                  s.reblogs_count * REBLOG_WEIGHTING +
                  s.favourites_count * FAVOURITE_WEIGHTING +
                  s.conversation.statuses.count * CONVERSATION_WEIGHTING
                }
                .reverse
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
