# Implementation Plan

- [x] 1. Set up iOS project structure and core dependencies
  - Create new iOS project with SwiftUI and Core Data
  - Configure project settings, bundle identifier, and deployment target
  - Add necessary dependencies and frameworks
  - Set up folder structure following MVVM architecture
  - _Requirements: All requirements need proper project foundation_

- [x] 2. Implement core data models and protocols
  - Create Codable models for WordTest, TextSource, UserProgress, and DifficultyLevel
  - Define protocol interfaces for APIService, StorageService, and ProgressTrackingService
  - Implement Core Data entities and relationships
  - Create model validation and transformation utilities
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 6.1_

- [x] 3. Build Core Data persistence layer
  - Implement Core Data stack with persistent container setup
  - Create repository classes for WordTest, TextSource, and UserProgress entities
  - Implement CRUD operations with proper error handling
  - Add data migration support for future schema changes
  - Write unit tests for Core Data operations
  - _Requirements: 4.1, 4.3, 7.1, 7.2_

- [ ] 4. Set up json-server for mock API development
  - Install json-server and create db.json with sample data structure
  - Configure mock data for text sources, word tests, and user progress
  - Add sample vocabulary data with different difficulty levels and contextual sentences
  - Set up custom routes for RESTful API endpoints matching the app's needs
  - Configure CORS and run server on localhost for iOS simulator testing
  - _Requirements: 1.2, 1.3, 2.1, 3.1_

- [ ] 5. Create API service for backend communication
  - Implement APIService class with URLSession for network requests
  - Create methods for uploading text sources and fetching word tests
  - Add progress synchronization endpoints
  - Implement proper error handling and retry mechanisms
  - Configure API service to work with mock local server during development
  - Write unit tests with mocked network responses
  - _Requirements: 1.2, 1.3, 3.1, 7.4_

- [ ] 6. Implement offline storage service
  - Create StorageService class implementing local data management
  - Add methods for saving and retrieving word tests locally
  - Implement progress tracking with local persistence
  - Create sync queue for offline operations
  - Write unit tests for offline functionality
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 7. Build progress tracking service
  - Implement ProgressTrackingService for recording user responses
  - Create session progress calculation logic
  - Add overall progress statistics computation
  - Implement progress persistence and retrieval
  - Write unit tests for progress calculations
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 8. Create main view models for business logic
- [ ] 8.1 Implement MainViewModel for app-wide state management
  - Create MainViewModel class with ObservableObject protocol
  - Add navigation state management and coordination logic
  - Implement app lifecycle handling and session management
  - Write unit tests for main view model logic
  - _Requirements: 5.1, 5.3_

- [ ] 8.2 Implement TextSourceViewModel for source management
  - Create TextSourceViewModel with text upload functionality
  - Add source selection and management capabilities
  - Implement backend communication for text processing
  - Add error handling for upload failures
  - Write unit tests for source management logic
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 6.1, 6.2, 6.3, 6.4_

- [ ] 8.3 Implement WordTestViewModel for study sessions
  - Create WordTestViewModel for managing word test sessions
  - Add current word state management and progression logic
  - Implement difficulty level filtering and word selection
  - Add user response handling (memorized/not memorized)
  - Write unit tests for word test session logic
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4_

- [ ] 8.4 Implement ProgressViewModel for statistics display
  - Create ProgressViewModel for tracking and displaying statistics
  - Add session progress and overall progress computation
  - Implement progress data formatting for UI display
  - Write unit tests for progress view model logic
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [ ] 9. Build main navigation and tab structure
  - Create main TabView with Home, Study, and Progress tabs
  - Implement navigation coordinator for deep linking
  - Add tab bar styling and accessibility labels
  - Create navigation state management between tabs
  - _Requirements: 5.1, 5.3_

- [ ] 10. Implement home screen and text source management
- [ ] 10.1 Create home screen with source list
  - Build HomeView displaying list of uploaded text sources
  - Add source selection functionality with navigation
  - Implement quick statistics display (total words, sources)
  - Add pull-to-refresh for source list updates
  - _Requirements: 6.1, 6.3_

- [ ] 10.2 Implement text upload interface
  - Create text input view for manual text entry
  - Add file upload functionality for document import
  - Implement upload progress indication and error handling
  - Add form validation and user feedback
  - _Requirements: 1.1, 1.2, 1.4_

- [ ] 10.3 Add source management features
  - Implement source deletion with confirmation dialog
  - Add source details view with statistics
  - Create source renaming functionality
  - Add empty state handling for no sources
  - _Requirements: 6.4, 5.1_

- [ ] 11. Build study interface and word test flow
- [ ] 11.1 Create difficulty selection screen
  - Build difficulty level selection interface
  - Add word count display for each difficulty level
  - Implement level completion indicators
  - Add navigation to word test session
  - _Requirements: 3.1, 3.2, 3.4_

- [ ] 11.2 Implement word test session interface
  - Create word display view with sentence context
  - Add meaning reveal functionality with tap interaction
  - Implement memorized/not memorized response buttons
  - Add smooth transitions between words
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 11.3 Add session progress and completion
  - Implement progress indicator during word tests
  - Create session completion screen with statistics
  - Add continue/restart session functionality
  - Implement session state persistence for resuming
  - _Requirements: 4.3, 5.3_

- [ ] 12. Create progress tracking and statistics interface
  - Build progress overview screen with key statistics
  - Add source-specific progress breakdown
  - Implement visual progress indicators and charts
  - Create achievement and milestone displays
  - _Requirements: 4.2, 4.4_

- [ ] 13. Implement offline functionality and synchronization
- [ ] 13.1 Add offline mode detection and handling
  - Implement network connectivity monitoring
  - Add offline mode indicators in UI
  - Create offline operation queuing system
  - Handle graceful degradation of online features
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 13.2 Build synchronization system
  - Implement automatic sync when connectivity returns
  - Add manual sync trigger for user control
  - Create conflict resolution for progress data
  - Add sync status indicators and error handling
  - _Requirements: 7.4_

- [ ] 14. Add error handling and user feedback systems
  - Implement comprehensive error handling throughout the app
  - Create user-friendly error messages and recovery options
  - Add loading states and progress indicators
  - Implement retry mechanisms for failed operations
  - _Requirements: 1.4, 5.1, 5.4_

- [ ] 15. Implement accessibility and user experience enhancements
  - Add VoiceOver support and accessibility labels
  - Implement dynamic type support for text scaling
  - Add haptic feedback for user interactions
  - Create smooth animations and transitions
  - _Requirements: 5.1, 5.2, 5.4_

- [ ] 16. Write comprehensive unit tests
  - Create unit tests for all view models and business logic
  - Add tests for Core Data operations and data persistence
  - Implement API service tests with mocked responses
  - Create progress calculation and tracking tests
  - _Requirements: All requirements need proper testing coverage_

- [ ] 17. Build integration tests for critical user flows
  - Create end-to-end tests for text upload and processing flow
  - Add integration tests for word test session completion
  - Implement offline/online synchronization testing
  - Create performance tests for large word sets
  - _Requirements: 1.1-1.4, 2.1-2.5, 7.1-7.4_

- [ ] 18. Implement app polish and final optimizations
  - Add app icons, launch screen, and branding elements
  - Optimize performance for smooth animations and transitions
  - Implement memory management and battery optimization
  - Add final UI polish and consistent styling
  - _Requirements: 5.1, 5.2, 5.4_