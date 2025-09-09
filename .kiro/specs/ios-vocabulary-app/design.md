# Design Document

## Overview

The iOS Vocabulary Learning App is a native iOS application built using SwiftUI that provides an Anki-style vocabulary learning experience. The app focuses on simplicity and effectiveness, presenting words one at a time with their contextual sentences and meanings. It integrates with a backend API to receive processed vocabulary data and manages local storage for offline functionality.

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern with SwiftUI, organized into the following layers:

### Presentation Layer (Views)
- SwiftUI views for user interface
- View models for business logic and state management
- Navigation coordination

### Business Logic Layer (Services)
- API service for backend communication
- Local storage service for offline functionality
- Progress tracking service
- Text processing coordination

### Data Layer (Models & Persistence)
- Core Data for local persistence
- Codable models for API communication
- Repository pattern for data access abstraction

## Components and Interfaces

### Core Models

```swift
struct WordTest: Codable, Identifiable {
    let id: UUID
    let word: String
    let sentence: String
    let meaning: String
    let difficultyLevel: DifficultyLevel
    let sourceId: UUID
}

struct TextSource: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let uploadDate: Date
    let wordCount: Int
    let processedDate: Date?
}

struct UserProgress: Codable {
    let wordId: UUID
    let isMemorized: Bool
    let reviewCount: Int
    let lastReviewed: Date
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
}
```

### View Models

#### MainViewModel
- Manages app-wide state and navigation
- Coordinates between different features
- Handles authentication and user session

#### TextSourceViewModel
- Manages text source upload and selection
- Communicates with backend for text processing
- Handles source management (add, delete, list)

#### WordTestViewModel
- Manages word test sessions
- Tracks current word, progress, and user responses
- Handles difficulty level filtering
- Manages offline/online state synchronization

#### ProgressViewModel
- Tracks and displays user learning statistics
- Manages progress persistence
- Provides analytics and insights

### Services

#### APIService
```swift
protocol APIServiceProtocol {
    func uploadTextSource(_ source: TextSource) async throws -> TextSource
    func fetchWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async throws -> [WordTest]
    func syncProgress(_ progress: [UserProgress]) async throws
}
```

#### StorageService
```swift
protocol StorageServiceProtocol {
    func saveWordTests(_ tests: [WordTest]) async throws
    func fetchWordTests(for sourceId: UUID, difficulty: DifficultyLevel?) async throws -> [WordTest]
    func saveProgress(_ progress: UserProgress) async throws
    func fetchProgress(for wordId: UUID) async throws -> UserProgress?
}
```

#### ProgressTrackingService
```swift
protocol ProgressTrackingServiceProtocol {
    func recordResponse(wordId: UUID, isMemorized: Bool) async
    func getSessionProgress() async -> SessionProgress
    func getOverallProgress() async -> OverallProgress
}
```

## Data Models

### Core Data Entities

#### WordTestEntity
- id: UUID (Primary Key)
- word: String
- sentence: String
- meaning: String
- difficultyLevel: String
- sourceId: UUID
- createdDate: Date
- isDownloaded: Bool

#### TextSourceEntity
- id: UUID (Primary Key)
- title: String
- content: String
- uploadDate: Date
- wordCount: Int32
- processedDate: Date?
- isProcessed: Bool

#### UserProgressEntity
- id: UUID (Primary Key)
- wordId: UUID
- isMemorized: Bool
- reviewCount: Int32
- lastReviewed: Date
- isSynced: Bool

### API Models

#### UploadTextRequest
```swift
struct UploadTextRequest: Codable {
    let title: String
    let content: String
    let userId: String
}
```

#### WordTestResponse
```swift
struct WordTestResponse: Codable {
    let words: [WordTest]
    let totalCount: Int
    let difficultyDistribution: [String: Int]
}
```

## User Interface Design

### Navigation Structure
```
TabView
├── Home
│   ├── Text Sources List
│   └── Upload New Source
├── Study
│   ├── Difficulty Selection
│   ├── Word Test Session
│   └── Session Complete
└── Progress
    ├── Overall Statistics
    ├── Source-specific Progress
    └── Achievement Badges
```

### Key Screens

#### Home Screen
- List of uploaded text sources
- Upload button for new content
- Quick stats (total words, sources)
- Continue studying button

#### Study Screen
- Difficulty level selector
- Word presentation view (word + sentence)
- Meaning reveal interaction
- Memorized/Not Memorized buttons
- Progress indicator

#### Word Test Session Flow
1. Display word and contextual sentence
2. User taps "Show Meaning" button
3. Meaning appears with animation
4. User selects "Memorized" or "Not Memorized"
5. Transition to next word with progress update

## Error Handling

### Network Errors
- Offline mode graceful degradation
- Retry mechanisms for failed uploads
- Queue system for pending operations
- User-friendly error messages

### Data Validation
- Input validation for text uploads
- Core Data constraint handling
- API response validation
- Graceful handling of corrupted data

### User Experience Errors
- Empty state handling (no sources, no words)
- Loading state management
- Progress loss prevention
- Backup and recovery mechanisms

## Testing Strategy

### Unit Testing
- ViewModel business logic testing
- Service layer testing with mocked dependencies
- Model validation and transformation testing
- Progress calculation accuracy testing

### Integration Testing
- API service integration with backend
- Core Data operations testing
- Offline/online synchronization testing
- End-to-end user flow testing

### UI Testing
- Critical user journey automation
- Accessibility testing
- Performance testing for large word sets
- Device-specific testing (iPhone/iPad)

### Test Data Management
- Mock API responses for development
- Sample text sources for testing
- Progress simulation for various scenarios
- Performance testing with large datasets

## Performance Considerations

### Memory Management
- Lazy loading of word tests
- Efficient Core Data fetch requests
- Image and resource optimization
- Background task management

### Battery Optimization
- Minimal background processing
- Efficient network usage
- Optimized animations and transitions
- Smart sync scheduling

### Storage Optimization
- Compressed text storage
- Efficient Core Data model design
- Cleanup of old progress data
- Smart caching strategies

## Security and Privacy

### Data Protection
- Local data encryption for sensitive content
- Secure API communication (HTTPS)
- User data anonymization options
- GDPR compliance considerations

### Authentication
- Secure user session management
- Token-based API authentication
- Biometric authentication option
- Account recovery mechanisms