# frozen_string_literal: true

class ListingsIndex < Chewy::Index
  settings index: { refresh_interval: '1m' }, analysis: {
    filter: {
      english_stop: {
        type: 'stop',
        stopwords: '_english_',
      },
      english_stemmer: {
        type: 'stemmer',
        language: 'english',
      },
      english_possessive_stemmer: {
        type: 'stemmer',
        language: 'possessive_english',
      },
    },
    analyzer: {
      content: {
        tokenizer: 'uax_url_email',
        filter: %w(
          english_possessive_stemmer
          lowercase
          asciifolding
          cjk_width
          english_stop
          english_stemmer
        ),
      },
    },
  }

  define_type ListingSearchService.listings.where('statuses.updated_at > ?', 30.days.ago) do
    root date_detection: false do
      field :account_id, type: 'long'

      field :text, type: 'text', value: ->(status) { [status.spoiler_text, Formatter.instance.plaintext(status)].join("\n\n") } do
        field :stemmed, type: 'text', analyzer: 'content'
      end

      field :location, type: 'text', value: -> (status) {
        status =~ /Location:\s*(\w\s+)\b/mi && $1
      } do
        field :stemmed, type: 'text', analyzer: 'content'
      end

      field :created_at, type: 'date'
    end
  end
end
