import SwiftUI
import PibblesUI

/// Thin host: every screen comes from Packages/PibblesUI, shared with Android.
@main
struct PibblesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
