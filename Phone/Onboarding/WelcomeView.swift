import SwiftUI

/// Figma 01 "Welcome – setup": shown once, on first launch. "Get started" asks for the
/// permissions one after another (SetupFlow), then the Explore map opens whatever the answers.
/// The Notifications row isn't in Figma yet (agreed with Mara; to be added there).
struct WelcomeView: View {
    @EnvironmentObject private var setup: SetupFlow
    @State private var asker = SystemPermissions()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Stroll")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.strollAmber)
                        .accessibilityAddTraits(.isHeader)
                    Text("Discover points of interest you've been walking past.")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.top, 22)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Stroll works through your Apple Watch and earbuds. To do that, it needs a few things:")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.top, 22)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 20) {
                        row("applewatch", "Apple Watch", "Taps your wrist near a point of interest.", for: nil)
                        row("headphones", "Earbuds", "Tells you what to look for.", for: nil)
                        row("location", "Location", "Finds points of interest around you.", for: .location)
                        row("heart", "Health", "Keeps Stroll running while your wrist is down.", for: .health)
                        row("bell", "Notifications", "Lets you know when one is near while your phone is locked.", for: .notifications)
                    }
                    .padding(.top, 22)
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            footer
        }
        .background(Color.strollNight.ignoresSafeArea())
        .preferredColorScheme(.dark)   // white status bar over the night background
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                Task { await setup.getStarted(using: asker) }
            } label: {
                Group {
                    if setup.isRunning {
                        ProgressView().tint(Color.strollAmberInk)
                    } else {
                        Text("Get started")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundStyle(Color.strollAmberInk)
                .background(Color.strollAmber, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(setup.isRunning)
            .accessibilityLabel("Get started")
            Text("You can change these anytime in Settings.")
                .font(.caption)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    /// One line of the list. While "Get started" is asking for this permission, its icon lights up
    /// amber, so it's clear which line the system prompt is about.
    private func row(_ symbol: String, _ title: String, _ detail: String, for permission: SetupPermission?) -> some View {
        let isAsking = permission != nil && setup.asking == permission
        return HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isAsking ? Color.strollAmberInk : Color.strollAmber)
                .frame(width: 36, height: 36)
                .background(isAsking ? Color.strollAmber : Color.white.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .animation(.easeInOut(duration: 0.2), value: isAsking)
    }
}

#Preview {
    WelcomeView().environmentObject(SetupFlow(defaults: UserDefaults(suiteName: "preview")!))
}
