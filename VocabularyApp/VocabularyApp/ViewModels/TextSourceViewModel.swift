import Foundation
import SwiftUI

@MainActor
class TextSourceViewModel: ObservableObject {
    @Published var textSources: [TextSource] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let storageService: StorageServiceProtocol?
    private let apiService: APIServiceProtocol?
    
    init(storageService: StorageServiceProtocol? = nil, apiService: APIServiceProtocol? = nil) {
        self.storageService = storageService
        self.apiService = apiService
    }
    
    func loadTextSources() async {
        // Placeholder for loading text sources
        isLoading = true
        defer { isLoading = false }
        
        // Implementation will be added in later tasks
    }
    
    func uploadTextSource(title: String, content: String) async {
        // Placeholder for text source upload
        isLoading = true
        defer { isLoading = false }
        
        // Implementation will be added in later tasks
    }
}