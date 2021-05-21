# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
App.create!(name: "Example local web server", healthcheck_url: "http://localhost:8080/health.json")
App.create!(name: "BEIS RODA staging", healthcheck_url: "https://staging.report-official-development-assistance.service.gov.uk/health_check")
