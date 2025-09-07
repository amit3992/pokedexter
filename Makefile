# PokeApp Makefile
# A collection of useful commands for development, testing, and deployment

.PHONY: help setup install update clean server console routes test lint docker-build docker-run deploy db-create db-migrate db-seed db-reset

# Default target
help:
	@echo "PokeApp Makefile Commands:"
	@echo "=========================="
	@echo "setup        - Initial setup for development"
	@echo "install      - Install dependencies"
	@echo "update       - Update dependencies"
	@echo "clean        - Remove temporary files"
	@echo "server       - Start the development server"
	@echo "css          - Start Tailwind CSS watcher"
	@echo "dev          - Start both Rails server and CSS watcher"
	@echo "console      - Start Rails console"
	@echo "routes       - Display all routes"
	@echo "test         - Run all tests"
	@echo "lint         - Run code linting"
	@echo "docker-build - Build Docker image"
	@echo "docker-run   - Run app in Docker container"
	@echo "deploy       - Deploy using Kamal"
	@echo "db-create    - Create database"
	@echo "db-migrate   - Run database migrations"
	@echo "db-seed      - Seed the database"
	@echo "db-reset     - Reset the database (drop, create, migrate, seed)"

# Setup
setup: install db-create db-migrate db-seed

# Dependencies
install:
	@echo "Installing dependencies..."
	bundle install

update:
	@echo "Updating dependencies..."
	bundle update

# Cleaning
clean:
	@echo "Cleaning temporary files..."
	rm -rf tmp/cache
	rm -rf log/*.log

# Server commands
server:
	@echo "Starting Rails server..."
	bin/rails server

css:
	@echo "Starting Tailwind CSS watcher..."
	bin/rails tailwindcss:watch

dev:
	@echo "Starting development environment..."
	bin/dev

console:
	@echo "Starting Rails console..."
	bin/rails console

routes:
	@echo "Displaying routes..."
	bin/rails routes

# Testing and linting
test:
	@echo "Running tests..."
	bin/rails test

lint:
	@echo "Running linting..."
	bin/brakeman
	bundle exec rubocop

# Docker commands
docker-build:
	@echo "Building Docker image..."
	docker build -t pokeapp .

docker-run:
	@echo "Running Docker container..."
	docker run -p 3000:3000 pokeapp

# Deployment
deploy:
	@echo "Deploying with Kamal..."
	bundle exec kamal deploy

# Database commands
db-create:
	@echo "Creating database..."
	bin/rails db:create

db-migrate:
	@echo "Running migrations..."
	bin/rails db:migrate

db-seed:
	@echo "Seeding database..."
	bin/rails db:seed

db-reset:
	@echo "Resetting database..."
	bin/rails db:drop db:create db:migrate db:seed
