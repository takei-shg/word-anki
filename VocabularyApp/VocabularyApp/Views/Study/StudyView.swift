import SwiftUI

struct StudyView: View {
    @StateObject private var viewModel = WordTestViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Study")
                    .font(.largeTitle)
                    .padding()
                
                Text("Word test functionality will be implemented here")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Study")
        }
    }
}

#Preview {
    StudyView()
}