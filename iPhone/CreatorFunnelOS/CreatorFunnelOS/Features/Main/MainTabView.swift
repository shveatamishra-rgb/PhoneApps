import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("creatorFunnelOS.selectedTab") private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tag(0)
            .tabItem {
                Label("Home", systemImage: "house")
            }

            NavigationStack {
                ContentPlannerView()
            }
            .tag(1)
            .tabItem {
                Label("Planner", systemImage: "calendar")
            }

            NavigationStack {
                FunnelsListView()
            }
            .tag(2)
            .tabItem {
                Label("Funnels", systemImage: "point.3.connected.trianglepath.dotted")
            }

            NavigationStack {
                ContactsListView()
            }
            .tag(3)
            .tabItem {
                Label("Leads", systemImage: "person.2")
            }

            NavigationStack {
                SettingsView()
            }
            .tag(4)
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .sheet(isPresented: $appState.isPaywallPresented) {
            SubscriptionView()
        }
        .task {
            if appState.workspace.metrics.isEmpty {
                await appState.refreshWorkspace()
            }
        }
    }
}
