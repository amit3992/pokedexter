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

The PokeApp provides a RESTful API for accessing your caught Pokémon collection. All API endpoints require JWT authentication.

### Authentication

#### Obtaining a JWT Token

To access the API, you first need to obtain a JWT token by logging in with your email:

**Request:**
```bash
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

The token expires after 24 hours. If you receive a "Token has expired" error, you'll need to obtain a new token.

#### Refreshing Your Token

You can refresh an existing token before it expires:

**Request:**
```bash
curl -X POST http://localhost:3000/api/refresh \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

### Making Authenticated API Calls

Include the JWT token in the `Authorization` header of your requests using the `Bearer` scheme:

```bash
curl -X GET http://localhost:3000/api/users/caught_pokemons \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Available Endpoints

#### Get Caught Pokémon

- **Endpoint:** `GET /api/caught_pokemons`
- **Authentication:** Required
- **Description:** Returns a JSON list of the current user's caught Pokémon

**Example:**
```bash
curl -X GET http://localhost:3000/api/caught_pokemons \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "pikachu",
    "base_experience": 112,
    "sprite_url": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png",
    "created_at": "2025-01-10T12:34:56.789Z"
  }
]
```

#### Get User's Caught Pokémon

- **Endpoint:** `GET /api/users/caught_pokemons`
- **Authentication:** Required
- **Description:** Returns a JSON list of the authenticated user's caught Pokémon

**Example:**
```bash
curl -X GET http://localhost:3000/api/users/caught_pokemons \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Release a Pokémon

- **Endpoint:** `DELETE /api/users/caught_pokemons/:id`
- **Authentication:** Required
- **Description:** Releases (deletes) a caught Pokémon from your collection

**Example:**
```bash
curl -X DELETE http://localhost:3000/api/users/caught_pokemons/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "message": "Pokemon released successfully"
}
```

### Error Responses

The API returns appropriate HTTP status codes and error messages:

- **401 Unauthorized:** Missing, invalid, or expired token
  ```json
  {
    "error": "Token has expired"
  }
  ```

- **404 Not Found:** User or resource not found
  ```json
  {
    "error": "User not found"
  }
  ```

- **422 Unprocessable Entity:** Invalid request parameters
  ```json
  {
    "error": "Email is required"
  }
  ```

## Testing

Run the test suite with:

```bash
make test
# or
bin/rails test
```

## Deployment

### Using Kamal

The application is configured for deployment using Kamal:

```bash
make deploy
# or
bundle exec kamal deploy
```

### Using Railway

This application is configured for easy deployment on [Railway](https://railway.app/):

1. Create a new project on Railway

2. Add a PostgreSQL database service to your project

3. Connect your GitHub repository to Railway

4. Set the following environment variables in your Railway project:
   - `RAILS_MASTER_KEY`: Your Rails master key (from config/master.key)
   - `RAILS_ENV`: production
   - `RAILWAY_PUBLIC_DOMAIN`: Your app's domain (e.g., pokeapp.up.railway.app)

5. Deploy your application

Railway will automatically detect the Procfile and deploy your application with the correct configuration.

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
