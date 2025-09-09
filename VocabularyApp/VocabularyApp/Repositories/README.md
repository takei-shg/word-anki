# Core Data Repositories

This directory contains the repository layer for the VocabularyApp, providing a clean abstraction over Core Data operations.

## Architecture

The repository pattern is implemented with the following components:

### RepositoryProtocol
- Base protocol defining common CRUD operations
- Provides access to persistence controller and contexts
- Generic protocol supporting different entity and model types

### Repository Implementations

#### TextSourceRepository
- Manages `TextSourceEntity` and `TextSource` model operations
- Supports filtering by processed status
- Provides batch operations for text source management
- Handles marking sources as processed with word counts

#### WordTestRepository  
- Manages `WordTestEntity` and `WordTest` model operations
- Supports filtering by difficulty level and source
- Provides batch creation and deletion operations
- Maintains relationships with text sources
- Supports counting words by difficulty level

#### UserProgressRepository
- Manages `UserProgressEntity` and `UserProgress` model operations
- Tracks user learning progress and review counts
- Supports filtering by memorization status and sync status
- Provides statistics calculation
- Handles progress recording with automatic review count increment

## Key Features

### Async/Await Support
All repository operations use modern Swift concurrency with async/await patterns for better performance and error handling.

### Background Context Operations
Heavy operations are performed on background contexts to avoid blocking the UI thread.

### Error Handling
Comprehensive error handling with custom `PersistenceError` types for different failure scenarios.

### Batch Operations
Optimized batch operations for creating and deleting multiple entities efficiently.

### Relationship Management
Automatic handling of Core Data relationships between entities.

### Migration Support
Built-in support for Core Data schema migrations and version checking.

## Usage Examples

### Creating a Text Source
```swift
let repository = TextSourceRepository()
let textSource = TextSource(title: "My Text", content: "Sample content")
let created = try await repository.create(textSource)
```

### Fetching Word Tests by Difficulty
```swift
let repository = WordTestRepository()
let beginnerWords = try await repository.fetchByDifficulty(.beginner)
```

### Recording User Progress
```swift
let repository = UserProgressRepository()
let progress = try await repository.recordProgress(wordId, isMemorized: true)
```

### Getting Progress Statistics
```swift
let repository = UserProgressRepository()
let stats = try await repository.getStatistics()
print("Memorized: \(stats.memorizedPercentage)%")
```

## Testing

Comprehensive unit tests are provided in `VocabularyAppTests/RepositoryTests.swift` covering:

- CRUD operations for all repositories
- Filtering and querying functionality
- Batch operations
- Error handling scenarios
- Integration testing across repositories
- Concurrent access patterns

## Thread Safety

All repository operations are thread-safe through the use of:
- Background contexts for heavy operations
- Proper context isolation
- Async/await patterns preventing race conditions
- Core Data's built-in thread safety mechanisms