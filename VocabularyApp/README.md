# Vocabulary Learning App

An iOS vocabulary learning application built with SwiftUI and Core Data that helps users learn words from their own text sources through Anki-style testing.

## Project Structure

The project follows MVVM (Model-View-ViewModel) architecture:

```
VocabularyApp/
├── VocabularyApp/
│   ├── VocabularyAppApp.swift          # Main app entry point
│   ├── ContentView.swift               # Main tab view
│   ├── Persistence.swift               # Core Data stack
│   ├── Models/                         # Data models
│   │   ├── WordTest.swift
│   │   ├── TextSource.swift
│   │   ├── UserProgress.swift
│   │   └── DifficultyLevel.swift
│   ├── ViewModels/                     # Business logic
│   │   ├── MainViewModel.swift
│   │   ├── TextSourceViewModel.swift
│   │   ├── WordTestViewModel.swift
│   │   └── ProgressViewModel.swift
│   ├── Views/                          # SwiftUI views
│   │   ├── Home/
│   │   │   └── HomeView.swift
│   │   ├── Study/
│   │   │   └── StudyView.swift
│   │   └── Progress/
│   │       └── ProgressView.swift
│   ├── Services/                       # Service protocols
│   │   ├── APIServiceProtocol.swift
│   │   ├── StorageServiceProtocol.swift
│   │   └── ProgressTrackingServiceProtocol.swift
│   ├── Assets.xcassets/                # App assets
│   ├── VocabularyApp.xcdatamodeld/     # Core Data model
│   └── Preview Content/
└── VocabularyApp.xcodeproj/            # Xcode project file
```

## Features

- **Text Source Management**: Upload and manage text sources for vocabulary extraction
- **Difficulty-based Learning**: Words organized by beginner, intermediate, and advanced levels
- **Anki-style Testing**: One-word-at-a-time learning with memorization tracking
- **Progress Tracking**: Comprehensive statistics and progress monitoring
- **Offline Support**: Local storage with Core Data for offline functionality
- **Clean UI**: Minimalist SwiftUI interface focused on learning

## Technical Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.0+
- SwiftUI
- Core Data

## Project Configuration

- **Bundle Identifier**: com.vocabularyapp.VocabularyApp
- **Deployment Target**: iOS 17.0
- **Architecture**: MVVM with SwiftUI
- **Data Persistence**: Core Data
- **UI Framework**: SwiftUI

## Getting Started

1. Open `VocabularyApp.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project

## Core Data Model

The app uses Core Data with three main entities:

- **TextSourceEntity**: Stores uploaded text sources
- **WordTestEntity**: Stores individual words with context and difficulty
- **UserProgressEntity**: Tracks user learning progress

## Next Steps

This is the foundational project structure. The following features will be implemented in subsequent tasks:

1. Core Data persistence layer
2. API service for backend communication
3. Offline storage service
4. Progress tracking service
5. Complete UI implementation
6. Testing suite

## Architecture Decisions

- **MVVM Pattern**: Separates business logic from UI for better testability
- **Protocol-based Services**: Enables dependency injection and testing
- **Core Data**: Provides robust offline storage and data relationships
- **SwiftUI**: Modern declarative UI framework for iOS