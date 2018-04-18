# frozen_string_literal: true

class ListingSearchService < BaseService
  attr_accessor :query

  RESULTS = 50
  def self.listings
    ::Status.tagged_with(Tag.find_by(name: 'swlisting'))
                       .local
                       .without_replies
                       .without_reblogs
                       .with_public_visibility
                       .excluding_silenced_accounts
                       .where('statuses.created_at > ?', 30.days.ago)
                       .order('statuses.created_at DESC')
  end

  def call(query)
    @query = query

    default_results.tap do |results|
      if query.blank?
        results[:listings] = all_listings
      else
        results[:listings] = perform_listing_search!
      end
    end
  end

  private

  def all_listings
    self.class.listings.limit(RESULTS)
  end

  def perform_listing_search!
     ListingsIndex.query(multi_match: { type: 'most_fields', query: query, operator: 'and', fields: %w(text text.stemmed location location.stemmed) })
                            .limit(RESULTS)
                            .order(created_at: {order: :desc})
                            .objects
                            .compact
  end

  def default_results
    { accounts: [], listings: [] }
  end

end
