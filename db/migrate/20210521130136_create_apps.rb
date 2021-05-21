class CreateApps < ActiveRecord::Migration[6.1]
  def change
    create_table :apps do |t|
      t.string :name
      t.string :healthcheck_url
      t.string :last_detected_git_sha
      t.datetime :first_detected_at

      t.timestamps
    end
  end
end
