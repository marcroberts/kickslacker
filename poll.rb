require 'open-uri'
require 'uri'
require 'json'
require 'time'
require 'yaml'
require 'digest'

require 'rubygems'
require 'bundler'

Bundler.require
Dotenv.load

require 'action_view'
include ActionView::Helpers::NumberHelper

cache = Dalli::Client.new

# Load config from file if it exists, otherwise use environment variables
if File.file?("config.yml")
  config = YAML.load_file "config.yml"
else
  config = {
    'kickstarter_url' => ENV['KICKSTARTER_URL'],
    'name' => ENV['KICKSTARTER_PROJECT_NAME'],
    'goal' => ENV['KICKSTARTER_GOAL'],
    'slack_url' => ENV['SLACK_URL'],
    'slack_channel' => ENV['SLACK_ROOM'],
    'locale' => ENV['LOCALE'] || 'en'
  }
end


config['projects'].each do |project|

  backer_cache_key = "ks:#{Digest::SHA256.hexdigest project['kickstarter_url']}:backer_count"
  pledge_cache_key = "ks:#{Digest::SHA256.hexdigest project['kickstarter_url']}:pledged"

  begin
    stats = JSON.parse(HTTParty.get("#{project['kickstarter_url']}/stats.json?v=1").body)
    backers = stats['project']['backers_count']
    pledged = stats['project']['pledged'].to_f
  rescue => e
    puts "Error parsing stats for #{project['name']}"
    next
  end

  if backers > 0
    old_count = cache.get(backer_cache_key).to_i

    if old_count < backers

      pledged_f = number_to_currency(pledged, locale: project['locale'], precision: 0)
      goal_f = number_to_currency(project['goal'], locale: project['locale'], precision: 0)
      
      new_backers = backers - old_count
      new_pledges = pledged - cache.get(pledge_cache_key).to_f
      new_pledges_f = number_to_currency(new_pledges, locale: project['locale'], precision: 0)

      payload = {
        text: "+#{new_pledges_f} and #{new_backers} New Backer#{new_backers == 1 ? '' : 's'} on <#{project['kickstarter_url']}|#{project['name']}>",
        icon_url: "https://www.kickstarter.com/download/kickstarter-logo-k-color.png",
        channel: project['slack_channel'],
        username: 'Kickstarter',
        attachments: [
          {
            color: pledged > project['goal'] ? '#2BDE73' : '#E3E4E6',
            fallback: "#{backers} backers (#{new_backers} new), #{pledged_f} of #{goal_f}, + #{new_pledges_f}",
            fields: [
              {
                title: 'Backers',
                value: backers,
                short: true
              },
              {
                title: 'Pledged',
                value: "#{pledged_f} of #{goal_f}",
                short: true
              },
              {
                title: 'New Backers',
                value: new_backers,
                short: true
              },
              {
                title: 'New Pledges',
                value: new_pledges_f,
                short: true
              }
            ]
          }
        ]
      }

      Net::HTTP.post_form(URI.parse(project['slack_url']), {payload: JSON.dump(payload)})

      cache.set(backer_cache_key, backers)
      cache.set(pledge_cache_key, pledged)

    end

  end # end if backers > 0

end # end each project
