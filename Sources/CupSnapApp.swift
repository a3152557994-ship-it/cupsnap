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

    @State private var activeTab: MainTab
    @State private var showAddSheet: Bool
    @State private var addTargetDate = Date()
    @State private var demoSampleReceiptIdx: Int?

    init(store: DrinkStore, l10n: L10n) {
        self.store = store
        self.l10n = l10n
        let args = ProcessInfo.processInfo.arguments
        let demoScreen: String? = {
            if let idx = args.firstIndex(of: "-ui_demo_screen"), idx + 1 < args.count {
                return args[idx + 1]
            }
            return nil
        }()
        switch demoScreen {
        case "poster":
            _activeTab = State(initialValue: .poster)
            _showAddSheet = State(initialValue: false)
            _demoSampleReceiptIdx = State(initialValue: nil)
        case "stats":
            _activeTab = State(initialValue: .stats)
            _showAddSheet = State(initialValue: false)
            _demoSampleReceiptIdx = State(initialValue: nil)
        case "add":
            _activeTab = State(initialValue: .wall)
            _showAddSheet = State(initialValue: true)
            _demoSampleReceiptIdx = State(initialValue: 0)
        default:
            _activeTab = State(initialValue: .wall)
            _showAddSheet = State(initialValue: false)
            _demoSampleReceiptIdx = State(initialValue: nil)
        }
    }

    var body: some View {
        Group {
            if ProcessInfo.processInfo.arguments.contains("add") && ProcessInfo.processInfo.arguments.contains("-ui_demo_screen") {
                AddDrinkSheet(
                    store: store,
                    l10n: l10n,
                    initialDate: addTargetDate,
                    editingEntry: nil,
                    prefillSampleReceiptIndex: 0
                )
            } else {
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
            }
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
    }
}
