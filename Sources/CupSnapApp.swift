import SwiftUI

@main
struct CupSnapApp: App {
    @StateObject private var store = DrinkStore.shared
    @StateObject private var l10n = L10n.shared

    var body: some Scene {
        WindowGroup {
            MainTabContainerView(store: store, l10n: l10n)
                .preferredColorScheme(.light)
        }
    }
}

enum MainTab: Int {
    case wall = 0
    case poster = 1
    case stats = 2
}

struct MainTabContainerView: View {
    @ObservedObject var store: DrinkStore
    @ObservedObject var l10n: L10n

    @State private var activeTab: MainTab = .wall
    @State private var showAddSheet = false
    @State private var addTargetDate = Date()
    @State private var demoSampleReceiptIdx: Int? = nil

    var body: some View {
        TabView(selection: $activeTab) {
            CalendarWallView(
                store: store,
                l10n: l10n,
                onTapAdd: { d in
                    addTargetDate = d
                    demoSampleReceiptIdx = nil
                    showAddSheet = true
                },
                onTapPoster: {
                    activeTab = .poster
                }
            )
            .tabItem {
                Label(l10n.t("贴纸墙", "Wall"), systemImage: "calendar")
            }
            .tag(MainTab.wall)

            PosterStudioView(store: store, l10n: l10n)
                .tabItem {
                    Label(l10n.t("晒图海报", "Poster"), systemImage: "sparkles.rectangle.stack")
                }
                .tag(MainTab.poster)

            InsightsView(store: store, l10n: l10n)
                .tabItem {
                    Label(l10n.t("账单备份", "Stats"), systemImage: "chart.bar.xaxis")
                }
                .tag(MainTab.stats)
        }
        .tint(CupTheme.caramel)
        .sheet(isPresented: $showAddSheet) {
            AddDrinkSheet(
                store: store,
                l10n: l10n,
                initialDate: addTargetDate,
                editingEntry: nil,
                prefillSampleReceiptIndex: demoSampleReceiptIdx
            )
        }
        .onOpenURL { url in
            if url.scheme == "cupsnap" {
                if url.host == "add" {
                    addTargetDate = Date()
                    showAddSheet = true
                } else if url.host == "poster" {
                    activeTab = .poster
                }
            }
        }
        .onAppear {
            applyLaunchScreenOverrides()
        }
    }

    private func applyLaunchScreenOverrides() {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-ui_demo_screen"), idx + 1 < args.count else { return }
        let screen = args[idx + 1]
        switch screen {
        case "wall":
            activeTab = .wall
        case "add":
            activeTab = .wall
            demoSampleReceiptIdx = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showAddSheet = true
            }
        case "poster":
            activeTab = .poster
        case "stats":
            activeTab = .stats
        default:
            break
        }
    }
}
