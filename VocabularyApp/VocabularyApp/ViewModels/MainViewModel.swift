import Foundation
import SwiftUI

enum AppTab: Int, CaseIterable {
    case home = 0
    case study = 1
    case progress = 2
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .study: return "Study"
        case .progress: return "Progress"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .study: return "book"
        case .progress: return "chart.bar"
        }
    }
}

enum AppState {
    case loading
    case ready
    case error(String)
}

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTab: AppTab = .home
    @Published var appState: AppState = .loading
    @Published var isNetworkAvailable: Bool = true
    @Published var showingAlert: Bool = false
    @Published var alertMessage: String = ""
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    
    // Session management
    @Published var isSessionActive: Bool = false
    @Published var currentSessionSourceId: UUID?
    
    // MARK: - Dependencies
    private let storageService: StorageServiceProtocol
    private let apiService: APIServiceProtocol
    private let progressTrackingService: ProgressTrackingServiceProtocol
    
    // MARK: - Initialization
    init(
        storageService: StorageServiceProtocol,
        apiService: APIServiceProtocol,
        progressTrackingService: ProgressTrackingServiceProtocol
    ) {
        self.storageService = storageService
        self.apiService = apiService
        self.progressTrackingService = progressTrackingService
        
        Task {
            await initializeApp()
        }
    }
    
    // MARK: - App Lifecycle
    func initializeApp() async {
        appState = .loading
        
        do {
            // Perform any necessary initialization
            await checkNetworkConnectivity()
            appState = .ready
        } catch {
            appState = .error("Failed to initialize app: \(error.localizedDescription)")
        }
    }
    
    func handleAppDidBecomeActive() {
        Task {
            await checkNetworkConnectivity()
        }
    }
    
    func handleAppWillResignActive() {
        // Save any pending state
        Task {
            await saveCurrentSession()
        }
    }
    
    // MARK: - Navigation Management
    func selectTab(_ tab: AppTab) {
        selectedTab = tab
        // Clear navigation path when switching tabs
        navigationPath = NavigationPath()
    }
    
    func navigateToStudy(sourceId: UUID? = nil) {
        if let sourceId = sourceId {
            currentSessionSourceId = sourceId
        }
        selectedTab = .study
    }
    
    func navigateToProgress() {
        selectedTab = .progress
    }
    
    func resetNavigation() {
        navigationPath = NavigationPath()
    }
    
    // MARK: - Session Management
    func startSession(sourceId: UUID) {
        isSessionActive = true
        currentSessionSourceId = sourceId
    }
    
    func endSession() {
        isSessionActive = false
        currentSessionSourceId = nil
    }
    
    private func saveCurrentSession() async {
        // Save any current session state if needed
        if isSessionActive {
            // Implementation would depend on session persistence requirements
        }
    }
    
    func resumeSession() async -> Bool {
        // Check if there's a session to resume
        // This would typically check for saved session state
        return false
    }
    
    // MARK: - Error Handling
    func showError(_ message: String) {
        alertMessage = message
        showingAlert = true
        appState = .error(message)
    }
    
    func clearError() {
        showingAlert = false
        alertMessage = ""
        if case .error = appState {
            appState = .ready
        }
    }
    
    func handleError(_ error: Error) {
        let message = error.localizedDescription
        showError(message)
    }
    
    // MARK: - Network Management
    private func checkNetworkConnectivity() async {
        // Simple network check - in a real app you'd use Network framework
        do {
            // Try a simple API call to check connectivity
            _ = try await apiService.fetchWordTests(for: UUID(), difficulty: nil)
            isNetworkAvailable = true
        } catch {
            isNetworkAvailable = false
        }
    }
    
    func retryNetworkOperation() async {
        await checkNetworkConnectivity()
    }
    
    // MARK: - Computed Properties
    var isLoading: Bool {
        if case .loading = appState {
            return true
        }
        return false
    }
    
    var hasError: Bool {
        if case .error = appState {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = appState {
            return message
        }
        return nil
    }
}