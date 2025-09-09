import SwiftUI

struct ProgressView: View {
    @StateObject private var viewModel = ProgressViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Progress")
                    .font(.largeTitle)
                    .padding()
                
                Text("Progress tracking and statistics will be implemented here")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressView()
}