import SwiftUI

/// First-launch setup, shown once. Started from Figma 01 "Welcome – setup" and split into
/// screens: an intro that explains Stroll with the watch and earbuds, then one screen for each
/// iOS permission (SetupFlow decides which and in what order). The Explore map opens after the
/// last one, whatever the answers. The per-permission screens aren't in Figma yet.
struct WelcomeView: View {
    @EnvironmentObject private var setup: SetupFlow

    var body: some View {
        ZStack {
            Color.strollNight.ignoresSafeArea()
            switch setup.step {
            case .intro:
                IntroScreen()
                    .transition(.push(from: .trailing))
            case .permission(let permission):
                PermissionScreen(permission: permission)
                    .id(permission)
                    .transition(.push(from: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: setup.step)
        .preferredColorScheme(.dark)   // white status bar over the night background
    }
}

// MARK: - Intro

private struct IntroScreen: View {
    @EnvironmentObject private var setup: SetupFlow

    var body: some View {
        SetupPage {
            Text("Stroll")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.strollAmber)
                .accessibilityAddTraits(.isHeader)
            Text("Discover points of interest you've been walking past.")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 22)
                .fixedSize(horizontal: false, vertical: true)
            Text("Stroll works through your Apple Watch and earbuds, so your phone can stay in your pocket.")
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.top, 22)
                .fixedSize(horizontal: false, vertical: true)
            Text("How a stroll works")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.top, 30)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 20) {
                step("figure.walk", "Start exploring", "Tap Start Exploring on the map, put your phone away and wander anywhere.")
                step("applewatch", "Feel a tap", "Your Apple Watch taps your wrist when you're near a point of interest.")
                step("headphones", "Listen and look", "Your earbuds tell you what to look for, so you can spot it yourself.")
            }
            .padding(.top, 16)
        } footer: {
            SetupButton(title: "Continue") { setup.continueFromIntro() }
        }
    }

    private func step(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            SetupIcon(symbol: symbol, size: 36)
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
    }
}

// MARK: - One permission

private struct PermissionScreen: View {
    @EnvironmentObject private var setup: SetupFlow
    let permission: SetupPermission
    /// Off until the screen has slid in. Every permission screen has its buttons in the same place,
    /// so without this a quick second tap would land on the next screen's Allow.
    @State private var ready = false

    var body: some View {
        SetupPage {
            SetupIcon(symbol: text.symbol, size: 72)
                .padding(.bottom, 28)
            Text(text.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(text.why)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.top, 16)
                .fixedSize(horizontal: false, vertical: true)
            Text(text.note)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 14)
                .fixedSize(horizontal: false, vertical: true)
        } footer: {
            SetupButton(title: text.allow, busy: setup.isAsking) {
                Task { await setup.allow() }
            }
            Button("Not now") { setup.notNow() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minHeight: 44)
                .disabled(setup.isAsking)
        }
        .allowsHitTesting(ready)
        .task {
            try? await Task.sleep(for: .milliseconds(600))
            ready = true
        }
    }

    private var text: (symbol: String, title: String, why: String, note: String, allow: String) {
        switch permission {
        case .location:
            ("location.fill",
             "Find what's around you",
             "Stroll uses your location to show points of interest on the map, and to notice when you reach one.",
             "You can change this anytime in Settings.",
             "Allow location")
        case .health:
            ("heart.fill",
             "Keep Stroll running on your watch",
             "Stroll starts a walking session on your Apple Watch, so it can keep tapping your wrist while your arm is down.",
             "Nothing is saved to Health.",
             "Allow walking sessions")
        case .notifications:
            ("bell.fill",
             "Hear about it with your phone locked",
             "Stroll sends a notification when you're near a point of interest and your phone is in your pocket.",
             "You can change this anytime in Settings.",
             "Allow notifications")
        }
    }
}

// MARK: - Shared pieces

/// Progress dots, scrolling content and a pinned footer, the same on every setup screen.
private struct SetupPage<Content: View, Footer: View>: View {
    @EnvironmentObject private var setup: SetupFlow
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        VStack(spacing: 0) {
            progress
                .padding(.top, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) { content }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 6) { footer }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }

    private var progress: some View {
        let steps = setup.steps
        let current = steps.firstIndex(of: setup.step) ?? 0
        return HStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Color.strollAmber : Color.white.opacity(0.25))
                    .frame(width: i == current ? 22 : 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(steps.count)")
    }
}

private struct SetupIcon: View {
    let symbol: String
    let size: CGFloat

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.47, weight: .medium))
            .foregroundStyle(Color.strollAmber)
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.14), in: Circle())
            .accessibilityHidden(true)
    }
}

private struct SetupButton: View {
    let title: String
    var busy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if busy {
                    ProgressView().tint(Color.strollAmberInk)
                } else {
                    Text(title)
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(Color.strollAmberInk)
            .background(Color.strollAmber, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .accessibilityLabel(title)
    }
}

#Preview {
    WelcomeView().environmentObject(
        SetupFlow(asker: SystemPermissions(), defaults: UserDefaults(suiteName: "preview")!))
}
