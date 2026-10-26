import SwiftUI

struct CameraLogView: View {
    @Environment(\.appTheme) private var appTheme
    @State private var showingAddMeal = false

    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    heroCard
                    guidanceCard
                    trustCard
                }
                .padding(20)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView()
        }
    }

    private var heroCard: some View {
        PastelCard(tint: .white) {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [NourishColors.lavender.opacity(0.20), NourishColors.blush.opacity(0.38)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 142, height: 142)
                    Circle()
                        .fill(NourishColors.lavender)
                        .frame(width: 96, height: 96)
                        .shadow(color: NourishColors.lavender.opacity(0.28), radius: 22, x: 0, y: 14)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Attach, describe, confirm")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .multilineTextAlignment(.center)
                    Text("Attach a meal photo, enter the foods you recognize, and confirm before saving.")
                        .font(NourishTypography.body)
                        .foregroundStyle(NourishColors.muted)
                        .multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Start photo log", systemImage: "camera.fill") {
                    showingAddMeal = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var guidanceCard: some View {
        PastelCard(tint: NourishColors.blushSoft) {
            VStack(alignment: .leading, spacing: 14) {
                Text("How it works")
                    .font(NourishTypography.cardTitle)
                    .foregroundStyle(NourishColors.ink)

                CameraStep(icon: "camera.macro", title: "Add a photo", description: "Choose from photos or use the camera.")
                CameraStep(icon: "square.and.pencil", title: "Describe the meal", description: "Add foods, servings, and nutrition values.")
                CameraStep(icon: "checkmark.seal.fill", title: "Confirm calories", description: "Nothing is saved until you confirm.")
            }
        }
    }

    private var trustCard: some View {
        PastelCard(tint: NourishColors.mintSoft) {
            HStack(spacing: 14) {
                Image(systemName: "lock.heart.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(NourishColors.lavender)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.72), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Private by default")
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Text("Photos and logs stay on device. No account is required.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }
            }
        }
    }
}

private struct CameraStep: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(NourishColors.lavender)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.ink)
                Text(description)
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
        }
    }
}

#Preview {
    CameraLogView()
}
