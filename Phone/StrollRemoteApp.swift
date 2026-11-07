import SwiftUI

@main
struct StrollRemoteApp: App {
    @StateObject private var link = PhoneLink()

    var body: some Scene {
        WindowGroup {
            RemoteView()
                .environmentObject(link)
                .onAppear {
                    link.activate()
                    UIApplication.shared.isIdleTimerDisabled = true // stay awake during the session
                }
        }
    }
}
