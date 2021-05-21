class App < ApplicationRecord
  validates :name, presence: true
  validates :healthcheck_url, presence: true
end
