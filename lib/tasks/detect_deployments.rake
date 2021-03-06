include ActionView::Helpers::DateHelper

POLL_INTERVAL_SECONDS=5

def fetch_current_sha(app)
  response = Faraday.get(app.healthcheck_url)
  object = JSON.parse(response.body)
  git_sha = object["git_sha"]
  raise "git_sha not found in body" unless git_sha
  return git_sha
end

def format_time(time)
  # TODO make consistent
  time.to_time.iso8601
end

def post_to_slack(message)
  puts "Posting to Slack"
  slack_channel = "test-detect-deployment-hackday"
  username = "DeploymentDetectionBot"
  slack_url = ENV["SLACK_WEBHOOK_URL"]

  raise "You need to set SLACK_WEBHOOK_URL" unless slack_url.present?

  body = {
    channel: slack_channel,
    username: username,
    unfurl_links: false,
    mrkdwn: true,
    text: message
  }

  response = Faraday.post(slack_url, body.to_json)
end

def github_link_mrkdwn(app, current_sha)
  if app.github_slug
    commit_url =  "https://github.com/#{app.github_slug}/commit/#{current_sha}"
    "<#{commit_url}|`#{current_sha}`>"
  else
    "`#{current_sha}`"
  end
end

def fetch_commit_authored_date(app, current_sha)
  commit_url =  "https://api.github.com/repos/#{app.github_slug}/commits/#{current_sha}"
  response = Faraday.get(commit_url)
  object = JSON.parse(response.body)

  return DateTime.parse(object["commit"]["author"]["date"])
end

def commit_authored_description(app, current_sha)
  return "" unless app.github_slug

  authored_date = fetch_commit_authored_date(app, current_sha)

  mrkdwn_date = "<!date^#{authored_date.to_i}^{date_short} at {time}|#{authored_date}>"

  return "(commit authored #{time_ago_in_words(authored_date)} ago, on #{mrkdwn_date})"
end

namespace :detect_deployments do
  task :run => :environment do
    loop do
      App.all.each do |app|
        last_detected_version_description = app.last_detected_git_sha ? "last detected version #{app.last_detected_git_sha}" : "no previously detected version"
        puts "Checking app: #{app.name} (#{last_detected_version_description})"

        current_sha = fetch_current_sha(app)
        is_new_version = (app.last_detected_git_sha != current_sha)

        now = Time.now
        if is_new_version
          message = "#{app.last_detected_git_sha ? "New" : "Initial"} version #{github_link_mrkdwn(app, current_sha)} has been deployed #{commit_authored_description(app, current_sha)}"
          puts message
          post_to_slack("*#{app.name}*: #{message}.")
          app.update!(last_detected_git_sha: current_sha, first_detected_at: now)
        else
          puts "  Current version is still #{current_sha} (first detected at #{format_time(app.first_detected_at)})."
        end
      end
      puts "Checking again in #{POLL_INTERVAL_SECONDS} seconds.\n\n"
      sleep POLL_INTERVAL_SECONDS
    end
  end
end
