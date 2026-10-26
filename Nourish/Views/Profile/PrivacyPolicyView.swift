import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                policySection(
                    title: "Your data",
                    text: "Meals, nutrition estimates, water entries, goals, settings, and meal photos are stored on this device. Nourish does not require an account and does not upload your food history or photos to iCloud."
                )

                policySection(
                    title: "Food lookup",
                    text: "Nourish uses its on-device food catalog first. When Open Food Facts lookup is enabled and a local match is uncertain, the food search phrase is sent to Open Food Facts to retrieve packaged-food nutrition data. Nourish does not send your name, photos, meal history, or advertising identifier with that request."
                )

                policySection(
                    title: "Photos and camera",
                    text: "Photo access is used only when you choose or capture a meal photo. Meal photos remain in Nourish storage on this device and can be removed by deleting the meal or resetting local data."
                )

                policySection(
                    title: "Notifications",
                    text: "Hydration reminders are scheduled locally by iOS. Nourish does not use remote push notifications."
                )

                policySection(
                    title: "Tracking and advertising",
                    text: "Nourish does not display ads, create advertising profiles, sell personal data, or track activity across other companies' apps and websites."
                )

                policySection(
                    title: "Delete your data",
                    text: "Use Profile > Reset this device to delete meals, water logs, meal photos, favorites, and settings stored by Nourish. Deleting the app also removes its local app data."
                )

                policySection(
                    title: "Health disclaimer",
                    text: "Nutrition values are estimates for personal tracking and are not medical advice. Consult a qualified healthcare professional for medical or dietary decisions."
                )

                Text("Last updated June 25, 2026")
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(appTheme.background.ignoresSafeArea())
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func policySection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(NourishTypography.section)
                .foregroundStyle(NourishColors.ink)
            Text(text)
                .font(NourishTypography.body)
                .foregroundStyle(NourishColors.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
