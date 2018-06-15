# frozen_string_literal: true

class ListingSearchService < BaseService
  attr_accessor :query

  RESULTS = 50
  def self.listings
    ::Status.tagged_with(Tag.find_by(name: 'swlisting'))
                       .local
                       .without_replies
                       .without_reblogs
                       .excluding_silenced_accounts
                       .where('statuses.created_at > ?', 30.days.ago)
                       .where(visibility: [:public, :unlisted])
                       .order('statuses.created_at DESC')
  end

  def call(query)
    @query = query

    default_results.tap do |results|
      if query.blank?
        results[:listings] = all_listings
        Stats.increment('listing.browse')
      else
        results[:listings] = perform_listing_search!
        Stats.increment('listing.search')
      end
    end
  end

  private

  def all_listings
    filter_results(self.class.listings.limit(RESULTS))
  end

  def perform_listing_search!
     results = ListingsIndex.query(multi_match: { type: 'most_fields', query: query, operator: 'and', fields: %w(text text.stemmed location location.stemmed) })
                            .limit(RESULTS * 2)
                            .order(created_at: {order: :desc})
                            .objects
    filter_results(results)
  end

  def filter_results(results)
    results.compact
           .group_by { |s| s.account }
           .reject { |a| a.silenced? }
           .map { |account, statuses|
             if statuses.any?(&:explicit_listing?)
               statuses.select(&:explicit_listing?).sort_by(&:created_at).last
             else
               statuses.sort_by(&:created_at).last
             end
           }
           .flatten
           .sort_by(&:created_at).reverse[0...RESULTS]
  end

  def default_results
    { accounts: [], listings: [] }
  end

end
