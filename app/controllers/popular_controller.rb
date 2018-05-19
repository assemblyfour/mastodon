class PopularController < ApplicationController
  layout 'public'

  def index
    @period = :day
    set_popular
  end

  def by_week
    @period = :week
    set_popular
    render :index
  end

  def by_month
    @period = :month
    set_popular
    render :index
  end

  protected

  def threshold
    (params[:threshold].presence || 20).to_i
  end

  def page
    (params[:page].presence || 1).to_i
  end

  def set_popular
    @popular = fetch_popular(period: @period)
    @page = page
  end

  REBLOG_WEIGHTING = 1
  FAVOURITE_WEIGHTING = 1
  CONVERSATION_WEIGHTING = 2
  def fetch_popular(period:)
    raise ArgumentError unless [:day, :week, :month].include?(period)
    expires = 1.send(period) * 0.005
    race_condition_ttl = expires * 0.05
    Rails.cache.fetch("popular/#{period}/#{page}", expires_in: expires, race_condition_ttl: race_condition_ttl) do
      Status.local
            .includes(:account, :preview_cards, :mentions, :conversation)
            .with_public_visibility
            .without_replies
            .where('reblogs_count + favourites_count > ?', threshold)
            .where('created_at BETWEEN ? AND ?', page.send(period).ago, (page - 1).send(period).ago)
            .reorder('reblogs_count + favourites_count DESC')
            .sort_by { |s|
              s.reblogs_count * REBLOG_WEIGHTING +
              s.favourites_count * FAVOURITE_WEIGHTING +
              s.conversation.statuses.pluck(:account_id).uniq.count * CONVERSATION_WEIGHTING
            }
            .reject { |s| s.text =~ /\d\d\d.?\d\d\d.?\d\d\d\d/ }
            .reverse[0...25]
    end
  end

end
