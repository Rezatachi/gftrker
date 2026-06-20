import SwiftData
import SwiftUI

struct ProfileGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @Query private var settingsRows: [AppSettings]
    @Query private var meals: [Meal]
    @Query private var mealTemplates: [MealTemplate]
    @Query private var waterEntries: [WaterEntry]
    @State private var showingResetConfirmation = false
    @FocusState private var focusedField: PersonalizationField?

    private var settings: AppSettings {
        settingsRows.first ?? AppSettings()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        profileHero
                        personalizationCard
                        goalsCard
                        remindersCard
                        parsingCard
                        privacyCard
                        resetCard
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                    .padding(.leading, .zero)
                    .padding(.trailing, .zero)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear(perform: ensureSettings)
            .confirmationDialog("Reset local data?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    resetLocalData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes meals, favorite meal templates, food items, water logs, saved meal photos, and restores default goals.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile")
                .font(NourishTypography.title)
                .foregroundStyle(NourishColors.ink)
            Text("Tune the app to your rhythm.")
                .font(NourishTypography.body)
                .foregroundStyle(NourishColors.muted)
        }
    }

    private var profileHero: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [NourishColors.bubblegumPink, NourishColors.blueBell],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 86, height: 86)
                .shadow(color: NourishColors.blueBell.opacity(0.22), radius: 18, x: 0, y: 12)

                VStack(alignment: .center, spacing: 7) {
                    Text("Athletic consistency")
                        .font(NourishTypography.cardTitle)
                        .foregroundStyle(NourishColors.ink)
                        .multilineTextAlignment(.center)
                    Text("Simple goals, soft nudges, and everything local.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var goalsCard: some View {
        PastelCard(tint: NourishColors.blushSoft) {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(icon: "target", title: "Daily goals", subtitle: "Set targets that support your routine.")

                GoalAdjuster(
                    title: "Calories",
                    value: settings.dailyCalorieGoal,
                    unit: "cal",
                    icon: "flame.fill",
                    range: 1200...4000,
                    step: 50,
                    accent: NourishColors.bubblegumPink,
                    note: "Adjusts the calorie target only. Existing meal logs stay unchanged.",
                    onChange: { settings.dailyCalorieGoal = $0 }
                )

                GoalAdjuster(
                    title: "Water",
                    value: settings.effectiveDailyWaterGoalOunces,
                    unit: "oz",
                    icon: "drop.fill",
                    range: 40...160,
                    step: 5,
                    accent: NourishColors.blueBell,
                    note: "Adjusts the ounce target only. Today's logged water stays unchanged.",
                    onChange: { settings.dailyWaterGoal = $0 }
                )

                GoalAdjuster(
                    title: "Protein",
                    value: settings.effectiveDailyProteinGoal,
                    unit: "g",
                    icon: "bolt.heart.fill",
                    range: 60...220,
                    step: 5,
                    accent: NourishColors.charcoalBlue,
                    note: "Adjusts the protein target only. Existing food logs stay unchanged.",
                    onChange: { settings.dailyProteinGoal = $0 }
                )
            }
        }
    }

    private var personalizationCard: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    icon: "sparkles",
                    title: "Personal touches",
                    subtitle: "Make this space feel like yours."
                )

                PersonalTextField(
                    title: "Your name",
                    placeholder: "Your name",
                    icon: "heart.fill",
                    text: Binding(
                        get: { settings.partnerName ?? "" },
                        set: { settings.partnerName = $0 }
                    ),
                    focusedField: $focusedField,
                    field: .partnerName
                )

                PersonalTextField(
                    title: "Favorite bottle",
                    placeholder: "Owala",
                    icon: "waterbottle.fill",
                    text: Binding(
                        get: { settings.favoriteBottleName ?? "" },
                        set: { settings.favoriteBottleName = $0 }
                    ),
                    focusedField: $focusedField,
                    field: .bottleName
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Theme variant")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)

                    ForEach(ThemeVariant.allCases) { variant in
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                settings.themeVariant = variant
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: variant.icon)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(settings.themeVariant == variant ? .white : variant.palette.accent)
                                    .frame(width: 38, height: 38)
                                    .background(settings.themeVariant == variant ? variant.palette.accent : .white.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(variant.rawValue)
                                        .font(NourishTypography.body)
                                        .foregroundStyle(NourishColors.ink)
                                    HStack(spacing: 5) {
                                        Circle().fill(variant.palette.accent).frame(width: 10, height: 10)
                                        Circle().fill(variant.palette.secondaryAccent).frame(width: 10, height: 10)
                                        Circle().fill(variant.palette.deepAccent).frame(width: 10, height: 10)
                                    }
                                }

                                Spacer()

                                if settings.themeVariant == variant {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(variant.palette.accent)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(settings.themeVariant == variant ? variant.palette.softSurface : NourishColors.blushSoft.opacity(0.45))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

            }
        }
    }

    private var remindersCard: some View {
        PastelCard(tint: NourishColors.mintSoft) {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(icon: "bell.badge.fill", title: "Water reminders", subtitle: "Hourly local nudges during the day.")

                Button {
                    let enabled = !settings.waterRemindersEnabled
                    settings.waterRemindersEnabled = enabled
                    if enabled {
                        Task { await NotificationService.scheduleWaterReminders(startHour: settings.reminderStartHour, endHour: settings.reminderEndHour) }
                    } else {
                        NotificationService.cancelWaterReminders()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(settings.waterRemindersEnabled ? "Reminders on" : "Reminders off")
                                .font(NourishTypography.section)
                                .foregroundStyle(NourishColors.ink)
                            Text(settings.waterRemindersEnabled ? "Hourly hydration checks are scheduled." : "Tap to enable hourly reminders.")
                                .font(NourishTypography.caption)
                                .foregroundStyle(NourishColors.muted)
                        }

                        Spacer()

                        ZStack {
                            Capsule()
                                .fill(settings.waterRemindersEnabled ? NourishColors.blueBell : .white.opacity(0.72))
                                .frame(width: 58, height: 34)
                            Circle()
                                .fill(settings.waterRemindersEnabled ? .white : NourishColors.muted.opacity(0.45))
                                .frame(width: 26, height: 26)
                                .offset(x: settings.waterRemindersEnabled ? 11 : -11)
                        }
                    }
                    .padding(14)
                    .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
                .buttonStyle(.plain)

                GoalAdjuster(
                    title: "Start",
                    value: settings.reminderStartHour,
                    unit: ":00",
                    icon: "sunrise.fill",
                    range: 6...14,
                    step: 1,
                    accent: NourishColors.bubblegumPink,
                    note: "Sets the first hourly reminder.",
                    onChange: {
                        settings.reminderStartHour = $0
                        rescheduleWaterRemindersIfNeeded()
                    }
                )

                GoalAdjuster(
                    title: "End",
                    value: settings.reminderEndHour,
                    unit: ":00",
                    icon: "moon.stars.fill",
                    range: 15...22,
                    step: 1,
                    accent: NourishColors.charcoalBlue,
                    note: "Sets the final hourly reminder.",
                    onChange: {
                        settings.reminderEndHour = $0
                        rescheduleWaterRemindersIfNeeded()
                    }
                )
            }
        }
    }

    private var privacyCard: some View {
        PastelCard(tint: .white) {
            HStack(spacing: 14) {
                Image(systemName: "lock.heart.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(NourishColors.magentaBloom)
                    .frame(width: 56, height: 56)
                    .background(NourishColors.blushSoft.opacity(0.70), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Private by default")
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Text("Meals, photos, water, and goals are stored locally for this MVP.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }
            }
        }
    }

    private var parsingCard: some View {
        PastelCard(tint: NourishColors.blushSoft.opacity(0.72)) {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    icon: "wand.and.sparkles",
                    title: "Food parsing",
                    subtitle: "Keep food logging fast, private, and local-first."
                )

                ParserToggleRow(
                    title: "Prefer local parsing",
                    subtitle: settings.effectivePreferLocalParsing ? "Uses the on-device food database first." : "Skips the local-first route when possible.",
                    icon: "iphone.gen3",
                    isOn: settings.effectivePreferLocalParsing,
                    accent: NourishColors.blueBell
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.preferLocalParsing = !settings.effectivePreferLocalParsing
                    }
                }

                ParserToggleRow(
                    title: "AI fallback",
                    subtitle: settings.effectiveAIFallbackEnabled ? "Allowed only when local parsing is unsure." : "Off by default. No API call is needed for common foods.",
                    icon: "sparkles",
                    isOn: settings.effectiveAIFallbackEnabled,
                    accent: NourishColors.magentaBloom
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.aiFallbackEnabled = !settings.effectiveAIFallbackEnabled
                    }
                }
            }
        }
    }

    private var resetCard: some View {
        PastelCard(tint: NourishColors.charcoalBlue.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    Image(systemName: "arrow.counterclockwise.heart.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(NourishColors.magentaBloom)
                        .frame(width: 54, height: 54)
                        .background(.white.opacity(0.72), in: Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Reset local data")
                            .font(NourishTypography.section)
                            .foregroundStyle(NourishColors.ink)
                        Text("Clear test meals, water logs, photos, and return goals to defaults.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                    }
                }

                Button {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset this device", systemImage: "trash")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(NourishColors.magentaBloom, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func resetLocalData() {
        meals.forEach { modelContext.delete($0) }
        mealTemplates.forEach { modelContext.delete($0) }
        waterEntries.forEach { modelContext.delete($0) }

        if let primarySettings = settingsRows.first {
            primarySettings.dailyCalorieGoal = 2100
            primarySettings.dailyWaterGoal = 80
            primarySettings.dailyProteinGoal = 130
            primarySettings.partnerName = nil
            primarySettings.favoriteBottleName = "Owala"
            primarySettings.themeVariant = .sageGreen
            primarySettings.waterRemindersEnabled = false
            primarySettings.reminderStartHour = 9
            primarySettings.reminderEndHour = 20
            primarySettings.aiFallbackEnabled = false
            primarySettings.preferLocalParsing = true
            settingsRows.dropFirst().forEach { modelContext.delete($0) }
        } else {
            modelContext.insert(AppSettings())
        }

        NotificationService.cancelWaterReminders()
        ImageStore.deleteAllImages()
        try? modelContext.save()
    }

    private func rescheduleWaterRemindersIfNeeded() {
        guard settings.waterRemindersEnabled else { return }
        Task {
            await NotificationService.scheduleWaterReminders(
                startHour: settings.reminderStartHour,
                endHour: settings.reminderEndHour
            )
        }
    }

    private func ensureSettings() {
        guard settingsRows.isEmpty else { return }
        modelContext.insert(AppSettings())
    }
}

private enum PersonalizationField: Hashable {
    case partnerName
    case bottleName
}

private struct PersonalTextField: View {
    let title: String
    let placeholder: String
    let icon: String
    @Binding var text: String
    var focusedField: FocusState<PersonalizationField?>.Binding
    let field: PersonalizationField

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(NourishTypography.caption)
                .foregroundStyle(NourishColors.muted)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(NourishColors.blueBell)
                    .frame(width: 38, height: 38)
                    .background(NourishColors.mintSoft.opacity(0.78), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                TextField(placeholder, text: $text)
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.ink)
                    .focused(focusedField, equals: field)
                    .textInputAutocapitalization(.words)
            }
            .padding(12)
            .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

private struct SectionTitle: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NourishColors.blueBell)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(NourishTypography.cardTitle)
                    .foregroundStyle(NourishColors.ink)
                Text(subtitle)
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
        }
    }
}

private struct ParserToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isOn: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isOn ? .white : accent)
                    .frame(width: 42, height: 42)
                    .background(isOn ? accent : .white.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Text(subtitle)
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                ZStack {
                    Capsule()
                        .fill(isOn ? accent : .white.opacity(0.72))
                        .frame(width: 58, height: 34)
                    Circle()
                        .fill(isOn ? .white : NourishColors.muted.opacity(0.45))
                        .frame(width: 26, height: 26)
                        .offset(x: isOn ? 11 : -11)
                }
            }
            .padding(14)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct GoalAdjuster: View {
    let title: String
    let value: Int
    let unit: String
    let icon: String
    let range: ClosedRange<Int>
    let step: Int
    let accent: Color
    let note: String
    let onChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(NourishTypography.body)
                        .foregroundStyle(NourishColors.ink)
                    Text("\(value) \(unit)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                }

                Spacer()

                HStack(spacing: 8) {
                    adjustButton(icon: "minus", isDisabled: value <= range.lowerBound) {
                        onChange(max(range.lowerBound, value - step))
                    }
                    adjustButton(icon: "plus", isDisabled: value >= range.upperBound) {
                        onChange(min(range.upperBound, value + step))
                    }
                }
            }

            Text(note)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
        }
        .padding(14)
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func adjustButton(icon: String, isDisabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isDisabled ? NourishColors.muted.opacity(0.45) : .white)
                .frame(width: 34, height: 34)
                .background(isDisabled ? .white.opacity(0.42) : accent, in: Circle())
        }
        .disabled(isDisabled)
        .buttonStyle(.plain)
    }
}
