

import SwiftUI
import SwiftData

@main
struct LandMarkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
