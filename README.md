# PokeApp

A Ruby on Rails application that allows users to discover random Pokémon from the PokeAPI, attempt to catch them with a probability-based system, and build a collection of caught Pokémon.

## Features

- View random Pokémon with their details
- Attempt to catch Pokémon with a probability-based success rate (harder to catch Pokémon with higher base experience)
- View your collection of caught Pokémon
- API endpoint to access your caught Pokémon collection

## Tech Stack

- **Ruby on Rails 8.0.2**
- **PostgreSQL** database
- **Tailwind CSS** for styling
- **Stimulus.js** for JavaScript interactions
- **Turbo** for SPA-like page transitions
- **Docker** for containerization
- **Kamal** for deployment

## Requirements

- Ruby 3.3.0 or higher
- PostgreSQL 14 or higher
- Node.js 18 or higher (for JavaScript dependencies)
- Docker (optional, for containerized development)

## Installation

### Local Setup

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/pokeapp.git
   cd pokeapp
   ```

2. Install dependencies
   ```bash
   bundle install
   ```

3. Setup the database
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

4. Start the server
   ```bash
   bin/dev
   ```

5. Visit http://localhost:3000 in your browser

### Using Docker

1. Build the Docker image
   ```bash
   docker build -t pokeapp .
   ```

2. Run the container
   ```bash
   docker run -p 3000:3000 pokeapp
   ```

3. Visit http://localhost:3000 in your browser

## Using the Makefile

This project includes a Makefile to simplify common development tasks:

```bash
# Setup the project
make setup

# Start the development server
make server

# Start the CSS watcher
make css

# Start both server and CSS watcher
make dev

# Run tests
make test

# Run linting
make lint

# See all available commands
make help
```

## Database Structure

- **Users**: Basic user model
- **CaughtPokemons**: Pokémon caught by users, with details like name, base experience, and sprite URL

## API Endpoints

- `GET /api/caught_pokemons`: Returns a JSON list of the current user's caught Pokémon

## Testing

Run the test suite with:

```bash
make test
# or
bin/rails test
```

## Deployment

The application is configured for deployment using Kamal:

```bash
make deploy
# or
bundle exec kamal deploy
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [PokeAPI](https://pokeapi.co/) for providing the Pokémon data
- [Ruby on Rails](https://rubyonrails.org/) framework
- [Tailwind CSS](https://tailwindcss.com/) for styling
- [Stimulus.js](https://stimulus.hotwired.dev/) for JavaScript interactions
