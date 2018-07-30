# frozen_string_literal: true
require 'sidekiq-scheduler'

class Scheduler::StatsScheduler
  include Sidekiq::Worker

  def perform
    # active users by day / week
    # confirmed user count
    # unconfirmed user count
    # total status count
    # total actual status count
    # mentions count
    # mutes count
    # notifications count
    # media attachments count
    # follows count
    # favourites count
    # conversations count
    # blocks count

    statsd = Datadog::Statsd.new(ENV['STATSD_HOST'] || 'localhost', (ENV['STATSD_PORT'] || 8125).to_i)
    statsd.namespace = 'switter'
    statsd.batch do |b|
      b.gauge('blocks', Block.count)
      b.gauge('conversations', Conversation.count)
      b.gauge('follows', Follow.count)
      b.gauge('media', MediaAttachment.count)
      b.gauge('mentions', Mention.count)
      b.gauge('mutes', Mute.count)
      b.gauge('notifications', Notification.count)
      b.gauge('statuses.reblogs', Status.local.where('reblog_of_id IS NOT NULL').count)
      b.gauge('statuses.replies', Status.local.where(reply: true).count)
      b.gauge('statuses.toots', Status.local.without_replies.without_reblogs.count)
      b.gauge('statuses.total', Account.local.sum(:statuses_count))
      b.gauge('users.count', User.confirmed.count, tags: ["state:confirmed"])
      b.gauge('users.count', User.where(confirmed_at: nil).count, tags: ["state:unconfirmed"])

      ActiveRecord::Base.connection.select_all("SELECT count(distinct(account_id)) FILTER (WHERE updated_at > now() - interval '24 hours') as day, count(distinct(account_id)) FILTER (WHERE updated_at > now() - interval '7 days') as week, count(distinct(account_id)) FILTER (WHERE updated_at > now() - interval '30 days') as month FROM statuses WHERE local = true").to_hash.first.each do |k, v|
        b.gauge("users.interacted.#{k}", v)
      end

      ActiveRecord::Base.connection.select_all("SELECT count(distinct(account_id)) FILTER (WHERE updated_at > now() - interval '24 hours') as day, count(distinct(account_id)) FILTER (WHERE updated_at > now() - interval '7 days') as week, count(distinct(account_id)) FILTER (WHERE updated_at > now() - interval '30 days') as month FROM statuses WHERE local = true AND reply = false AND reblog_of_id IS NULL ").to_hash.first.each do |k, v|
        b.gauge("users.tooted.#{k}", v)
      end

      {
        day: 1.day.ago,
        week: 1.week.ago,
        month: 1.month.ago
      }.each do |period, time|
        b.gauge("users.active.#{period}", User.where('current_sign_in_at > ?', time).count)
        b.gauge("listings.#{period}", ListingSearchService.listings.where('statuses.updated_at > ?', time).count)
        b.gauge("listings.accounts.#{period}", ListingSearchService.listings.reorder(nil).where('statuses.updated_at > ?', time).distinct.count(:account_id))
      end
    end
  end

end
