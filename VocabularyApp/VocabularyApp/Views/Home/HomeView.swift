import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = TextSourceViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Home")
                    .font(.largeTitle)
                    .padding()
                
                Text("Text sources and upload functionality will be implemented here")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    HomeView()
}