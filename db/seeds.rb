# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

User.find_or_create_by!(email: "demo@example.com")
User.find_or_create_by!(email: "ash.ketchum@pokemon.com")
User.find_or_create_by!(email: "misty.waterflower@cerulean.gym")
User.find_or_create_by!(email: "brock.harrison@pewter.gym")
User.find_or_create_by!(email: "gary.oak@pallet.town")
User.find_or_create_by!(email: "jessie.team@rocket.org")
User.find_or_create_by!(email: "james.team@rocket.org")
User.find_or_create_by!(email: "nurse.joy@pokecenter.com")
User.find_or_create_by!(email: "officer.jenny@police.kanto")
User.find_or_create_by!(email: "professor.oak@research.lab")
User.find_or_create_by!(email: "may.hoenn@coordinator.net")
User.find_or_create_by!(email: "dawn.sinnoh@contests.com")
