import SwiftUI
import ArmaziCore

@main
struct ArmaziApp: App {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: viewModel)
        }
        .defaultSize(width: 900, height: 650)
    }
}
