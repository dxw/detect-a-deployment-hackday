class AddGithubSlugToApps < ActiveRecord::Migration[6.1]
  def change
    add_column :apps, :github_slug, :string
  end
end
