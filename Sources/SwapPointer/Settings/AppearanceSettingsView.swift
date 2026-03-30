import SwiftUI

struct AppearanceSettingsView: View {
    @State private var showDormantCursors = UserDefaults.swapPointer.showDormantCursors
    @State private var dormantCursorOpacity = UserDefaults.swapPointer.dormantCursorOpacity
    @State private var showWarpAnimation = UserDefaults.swapPointer.showWarpAnimation

    var body: some View {
        Form {
            Section("Dormant Cursors") {
                Toggle("Show dormant cursor markers", isOn: $showDormantCursors)
                    .onChange(of: showDormantCursors) { _, newValue in
                        UserDefaults.swapPointer.showDormantCursors = newValue
                    }

                if showDormantCursors {
                    VStack(alignment: .leading) {
                        Text("Marker opacity: \(Int(dormantCursorOpacity * 100))%")
                        Slider(value: $dormantCursorOpacity, in: 0.1...1.0, step: 0.05) {
                            Text("Opacity")
                        }
                        .onChange(of: dormantCursorOpacity) { _, newValue in
                            UserDefaults.swapPointer.dormantCursorOpacity = newValue
                        }
                    }
                }
            }

            Section("Switch Animation") {
                Toggle("Show animation when cursor warps", isOn: $showWarpAnimation)
                    .onChange(of: showWarpAnimation) { _, newValue in
                        UserDefaults.swapPointer.showWarpAnimation = newValue
                    }
            }
        }
        .formStyle(.grouped)
    }
}
