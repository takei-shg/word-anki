# Requirements Document

## Introduction

This document outlines the requirements for an iOS vocabulary learning application that helps users learn words from their own text sources through Anki-style testing. The app works in conjunction with a backend system that processes user-provided scripts, extracts words with context sentences, groups them by difficulty levels, and serves word tests. The iOS app focuses on delivering an intuitive, one-word-at-a-time learning experience where users can test their knowledge and track their progress.

## Requirements

### Requirement 1

**User Story:** As a language learner, I want to upload or input text scripts so that I can learn vocabulary from content that interests me.

#### Acceptance Criteria

1. WHEN the user opens the app THEN the system SHALL display an option to input or upload text content
2. WHEN the user provides a text script THEN the system SHALL send it to the backend for processing
3. WHEN the backend processing is complete THEN the system SHALL notify the user that their word tests are ready
4. IF the text upload fails THEN the system SHALL display an error message and allow retry

### Requirement 2

**User Story:** As a language learner, I want to take word tests one word at a time so that I can focus on individual vocabulary items without distraction.

#### Acceptance Criteria

1. WHEN the user starts a word test THEN the system SHALL display one word at a time with its associated sentence from the source text
2. WHEN the user views a word and sentence THEN the system SHALL hide the word meaning initially
3. WHEN the user taps to indicate they want to see the meaning THEN the system SHALL reveal the word's definition
4. WHEN the user completes viewing a word THEN the system SHALL provide options to mark it as "memorized" or "not memorized"
5. WHEN the user marks their response THEN the system SHALL advance to the next word in the test

### Requirement 3

**User Story:** As a language learner, I want to see words grouped by difficulty levels so that I can choose appropriate challenges for my current skill level.

#### Acceptance Criteria

1. WHEN the user accesses their word tests THEN the system SHALL display words organized by difficulty levels (beginner, intermediate, advanced)
2. WHEN the user selects a difficulty level THEN the system SHALL show only words from that category
3. WHEN the user completes words from one difficulty level THEN the system SHALL suggest moving to the next level
4. IF no words are available for a selected difficulty level THEN the system SHALL inform the user and suggest alternatives

### Requirement 4

**User Story:** As a language learner, I want to track my progress through word tests so that I can see how many words I've studied and my performance.

#### Acceptance Criteria

1. WHEN the user completes a word test session THEN the system SHALL save their responses (memorized/not memorized)
2. WHEN the user views their progress THEN the system SHALL display statistics including total words studied, words marked as memorized, and current session progress
3. WHEN the user returns to the app THEN the system SHALL resume from where they left off in their word tests
4. WHEN the user completes all words in a difficulty level THEN the system SHALL mark that level as completed

### Requirement 5

**User Story:** As a language learner, I want an intuitive and clean interface so that I can focus on learning without distractions.

#### Acceptance Criteria

1. WHEN the user interacts with the app THEN the system SHALL provide a clean, minimalist interface with clear navigation
2. WHEN the user is in a word test THEN the system SHALL display only essential elements (word, sentence, meaning when revealed)
3. WHEN the user needs to navigate THEN the system SHALL provide clear back/forward options and progress indicators
4. WHEN the user taps interactive elements THEN the system SHALL provide immediate visual feedback

### Requirement 6

**User Story:** As a language learner, I want to manage multiple text sources so that I can learn vocabulary from different materials.

#### Acceptance Criteria

1. WHEN the user has multiple text sources THEN the system SHALL allow them to select which source to study from
2. WHEN the user adds a new text source THEN the system SHALL process it separately and maintain distinct word lists
3. WHEN the user views their sources THEN the system SHALL display the title/name of each source and progress statistics
4. WHEN the user deletes a source THEN the system SHALL remove all associated words and progress data after confirmation

### Requirement 7

**User Story:** As a language learner, I want the app to work offline for reviewing words I've already downloaded so that I can study without an internet connection.

#### Acceptance Criteria

1. WHEN the user downloads word tests THEN the system SHALL store them locally for offline access
2. WHEN the user is offline THEN the system SHALL allow access to previously downloaded word tests
3. WHEN the user is offline and tries to upload new content THEN the system SHALL queue the upload for when connectivity returns
4. WHEN connectivity is restored THEN the system SHALL automatically sync any offline progress with the backend