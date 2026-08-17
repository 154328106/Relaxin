import SwiftUI

/// A Dopamine-style hero screen: logo mark, status text, a single large
/// primary action button, and a minimal row of secondary text actions.
/// Used for the idle "home" screen in both the pre-jailbreak (`HomeView`)
/// and post-jailbreak (`PostJailbreakHomeView`) flows; everything reachable
/// from the original terminal-driven home menu remains reachable here.
struct DopamineHeroContent: View {
    struct SecondaryAction: Identifiable {
        let id: String
        let title: String
        let action: () -> Void

        init(_ title: String, id: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.id = id ?? title
            self.action = action
        }
    }

    let statusTitle: String
    let statusSubtitle: String?
    let primaryButtonTitle: String
    let isPrimaryButtonEnabled: Bool
    let isPrimaryButtonProminent: Bool
    let secondaryActions: [SecondaryAction]
    let onPrimaryAction: () -> Void
    var onSettings: (() -> Void)?

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    SwiftUI.Color(red: 0.12, green: 0.23, blue: 0.53),
                    SwiftUI.Color(red: 0.10, green: 0.18, blue: 0.40),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if let onSettings {
                    HStack {
                        Spacer()
                        Button(action: onSettings) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(.white.opacity(0.12)))
                        }
                        .accessibilityLabel(Text("Advanced Options"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer(minLength: 24)

                VStack(spacing: 16) {
                    Image("BootLogoMark")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .environment(\.colorScheme, .dark)

                    VStack(spacing: 6) {
                        Text(statusTitle)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        if let statusSubtitle {
                            Text(statusSubtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                Spacer(minLength: 24)

                VStack(spacing: 18) {
                    Button(action: onPrimaryAction) {
                        Text(primaryButtonTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        isPrimaryButtonProminent
                                            ? Theme.accent
                                            : SwiftUI.Color.white.opacity(0.15)
                                    )
                            )
                    }
                    .disabled(!isPrimaryButtonEnabled)
                    .opacity(isPrimaryButtonEnabled ? 1 : 0.5)

                    if !secondaryActions.isEmpty {
                        HStack(spacing: 28) {
                            ForEach(secondaryActions) { action in
                                Button(action: action.action) {
                                    Text(action.title)
                                }
                            }
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    DopamineHeroContent(
        statusTitle: "Not Jailbroken",
        statusSubtitle: "iPhone \u{2022} iOS 17.3.1",
        primaryButtonTitle: "Jailbreak",
        isPrimaryButtonEnabled: true,
        isPrimaryButtonProminent: true,
        secondaryActions: [
            .init("Maintenance") {},
            .init("Credits") {},
        ],
        onPrimaryAction: {},
        onSettings: {}
    )
}
