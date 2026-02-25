import SwiftUI

struct MainTabView: View {
    let tealColor = Color(hex: "233D4C")
    let peachColor = Color(hex: "FD802E")

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Session Planning
            IntroView()
                .tabItem {
                    Label("Session", systemImage: "timer")
                }
                .tag(0)

            // Tab 2: History
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
        }
        .accentColor(peachColor)
        // Style the tab bar to match the dark teal theme
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "1A2E3A"))

            // Normal item
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.4)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white.withAlphaComponent(0.4)
            ]

            // Selected item
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "FD802E"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "FD802E"))
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
