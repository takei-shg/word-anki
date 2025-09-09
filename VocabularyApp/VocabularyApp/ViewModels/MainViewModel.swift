import Foundation
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Navigation state
    @Published var navigationPath = NavigationPath()
    
    init() {
        // Initialize main view model
    }
    
    func showError(_ message: String) {
        errorMessage = message
    }
    
    func clearError() {
        errorMessage = nil
    }
}