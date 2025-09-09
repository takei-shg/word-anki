# Vocabulary App Mock API

This is a mock API server for the iOS Vocabulary Learning App development using json-server.

## Setup

1. Install dependencies:
```bash
npm install
```

## Running the Server

### Development Mode (with delay simulation)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will run on `http://localhost:3000` and will be accessible from iOS Simulator.

## API Endpoints

### Text Sources
- `GET /api/text-sources` - Get all text sources
- `POST /api/text-sources` - Upload a new text source
- `GET /api/text-sources/:id` - Get a specific text source
- `DELETE /api/text-sources/:id` - Delete a text source

### Word Tests
- `GET /api/word-tests` - Get all word tests
- `GET /api/text-sources/:id/word-tests` - Get word tests for a specific source
- `GET /api/text-sources/:id/word-tests/:difficulty` - Get word tests by source and difficulty
- `GET /api/word-tests/by-difficulty/:difficulty` - Get word tests by difficulty level

### User Progress
- `GET /api/user-progress` - Get all user progress
- `POST /api/user-progress` - Create new progress entry
- `PUT /api/user-progress/:id` - Update progress entry
- `POST /api/sync/progress` - Sync multiple progress entries

## Difficulty Levels
- `beginner`
- `intermediate` 
- `advanced`

## Sample Data

The server includes sample data with:
- 3 text sources (The Great Gatsby, Climate Change article, Business article)
- 12 word tests with various difficulty levels
- 5 user progress entries

## CORS Configuration

The server is configured to allow cross-origin requests from any origin, making it suitable for iOS Simulator testing.

## Features

- Automatic UUID generation for new entries
- Simulated processing delays for realistic testing
- Request logging
- CORS support for iOS development
- Custom routes matching the app's API design