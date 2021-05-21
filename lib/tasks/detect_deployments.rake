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
          puts "  #{app.last_detected_git_sha ? "New" : "Initial"} version #{current_sha} detected at #{format_time(now)}. "
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
