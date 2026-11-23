import SwiftUI
import PibblesUI

/// Thin host: every screen comes from Packages/PibblesUI, shared with Android.
@main
struct PibblesApp: App {
    init() {
        // Poppins and Inter from the package (docs/brand 1.5)
        PibblesStyle.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
