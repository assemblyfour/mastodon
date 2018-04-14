# frozen_string_literal: true

class SearchService < BaseService
  attr_accessor :query, :account, :limit, :resolve

  def call(query, limit, resolve = false, account = nil)
    @query   = query
    @account = account
    @limit   = limit
    @resolve = resolve

    default_results.tap do |results|
      if url_query?
        results.merge!(url_resource_results) unless url_resource.nil?
      elsif query.present?
        results[:accounts] = perform_accounts_search! if account_searchable?
        results[:statuses] = perform_statuses_search! if full_text_searchable?
        results[:hashtags] = perform_hashtags_search! if hashtag_searchable?
      end
    end
  end

  private

  def perform_accounts_search!
    AccountSearchService.new.call(query, limit, account, resolve: resolve)
  end

  def perform_statuses_search!
    statuses = StatusesIndex.filter(term: { searchable_by: account.id })
                            .query(multi_match: { type: 'most_fields', query: query, operator: 'and', fields: %w(text text.stemmed) })
                            .order(created_at: {order: :desc})
                            .limit(limit)
                            .objects
                            .compact

    # TODO: merge this with above query
    public_statuses = StatusesIndex.filter(term: { visibility: 'public' })
                            .query(multi_match: { type: 'most_fields', query: query, operator: 'and', fields: %w(text text.stemmed) })
                            .order(created_at: {order: :desc})
                            .limit(limit)
                            .objects
                            .compact

    statuses = (statuses + public_statuses).compact.uniq
    statuses.reject { |status| StatusFilter.new(status, account).filtered? }[0...limit]
  end

  def perform_hashtags_search!
    Tag.search_for(query.gsub(/\A#/, ''), limit)
  end

  def default_results
    { accounts: [], hashtags: [], statuses: [] }
  end

  def url_query?
    query =~ /\Ahttps?:\/\//
  end

  def url_resource_results
    { url_resource_symbol => [url_resource] }
  end

  def url_resource
    @_url_resource ||= ResolveURLService.new.call(query)
  end

  def url_resource_symbol
    url_resource.class.name.downcase.pluralize.to_sym
  end

  def full_text_searchable?
    Chewy.enabled? && query.length >= 2
  end

  def account_searchable?
    !(query.include?('@') && query.include?(' '))
  end

  def hashtag_searchable?
    !query.include?('@')
  end
end
