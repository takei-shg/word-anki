import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var mainViewModel = MainViewModel()

    var body: some View {
        TabView(selection: $mainViewModel.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            StudyView()
                .tabItem {
                    Image(systemName: "book")
                    Text("Study")
                }
                .tag(1)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Progress")
                }
                .tag(2)
        }
        .environmentObject(mainViewModel)
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}