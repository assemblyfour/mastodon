class PopularController < ApplicationController
  layout 'public'


  def index
    @popular = Status.local.with_public_visibility.where('reblogs_count + favourites_count > ?', threshold).where('created_at BETWEEN ? AND ?', page.days.ago, (page - 1).days.ago).limit(50).reorder('reblogs_count + favourites_count DESC')
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
