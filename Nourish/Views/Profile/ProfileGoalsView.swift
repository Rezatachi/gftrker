import SwiftData
import SwiftUI

struct ProfileGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @Query private var settingsRows: [AppSettings]
    @Query private var meals: [Meal]
    @Query private var mealTemplates: [MealTemplate]
    @Query private var waterEntries: [WaterEntry]
    @Query private var foodCorrections: [FoodCorrection]
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
#if DEBUG
                        parsingCard
#else
                        remoteLookupCard
#endif
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
            .onAppear(perform: applyBundledProviderSettings)
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
        NavigationLink {
            PrivacyPolicyView()
        } label: {
            PastelCard(tint: .white) {
                HStack(spacing: 14) {
                    Image(systemName: "lock.heart.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(NourishColors.magentaBloom)
                        .frame(width: 56, height: 56)
                        .background(NourishColors.blushSoft.opacity(0.70), in: Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Privacy and data")
                            .font(NourishTypography.section)
                            .foregroundStyle(NourishColors.ink)
                        Text("Logs and photos stay on device. Review remote food lookup and deletion details.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                    }

                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(NourishColors.muted)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var remoteLookupCard: some View {
        PastelCard(tint: NourishColors.mintSoft.opacity(0.72)) {
            VStack(alignment: .leading, spacing: 16) {
                SectionTitle(
                    icon: "globe",
                    title: "Packaged food lookup",
                    subtitle: "Use Open Food Facts when the on-device matcher is unsure."
                )

                ParserToggleRow(
                    title: "Open Food Facts",
                    subtitle: settings.effectiveOpenFoodFactsSearchEnabled
                        ? "Food search phrases may be sent for nutrition lookup."
                        : "Only the on-device catalog will be used.",
                    icon: "globe.americas.fill",
                    isOn: settings.effectiveOpenFoodFactsSearchEnabled,
                    accent: NourishColors.blueBell
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.openFoodFactsSearchEnabled = !settings.effectiveOpenFoodFactsSearchEnabled
                    }
                }
            }
        }
    }

#if DEBUG
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
                    title: "Local AI drafts",
                    subtitle: settings.effectiveLocalLLMEnabled ? "Uses Ollama when simple local matching is unsure." : "Off by default. Turn on when Ollama is running.",
                    icon: "desktopcomputer",
                    isOn: settings.effectiveLocalLLMEnabled,
                    accent: NourishColors.charcoalBlue
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.localLLMEnabled = !settings.effectiveLocalLLMEnabled
                    }
                }

                if settings.effectiveLocalLLMEnabled {
                    ParserTextField(
                        title: "Ollama URL",
                        placeholder: "http://localhost:11434",
                        icon: "network",
                        text: Binding(
                            get: { settings.ollamaBaseURL ?? "" },
                            set: { settings.ollamaBaseURL = $0 }
                        ),
                        focusedField: $focusedField,
                        field: .ollamaBaseURL
                    )

                    ParserTextField(
                        title: "Model",
                        placeholder: "llama3.2:3b",
                        icon: "cpu.fill",
                        text: Binding(
                            get: { settings.ollamaModel ?? "" },
                            set: { settings.ollamaModel = $0 }
                        ),
                        focusedField: $focusedField,
                        field: .ollamaModel
                    )

                    Text("Simulator can use localhost. A physical iPhone needs your Mac LAN URL, like http://192.168.x.x:11434.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ParserToggleRow(
                    title: "Nutritionix natural logging",
                    subtitle: settings.effectiveNutritionixSearchEnabled ? "Parses multi-food chat with serving estimates." : "Off by default. Adds stronger natural-language nutrition lookup.",
                    icon: "text.magnifyingglass",
                    isOn: settings.effectiveNutritionixSearchEnabled,
                    accent: NourishColors.charcoalBlue
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.nutritionixSearchEnabled = !settings.effectiveNutritionixSearchEnabled
                    }
                }

                if settings.effectiveNutritionixSearchEnabled {
                    ParserTextField(
                        title: "Nutritionix app id",
                        placeholder: "App ID",
                        icon: "app.badge.fill",
                        text: Binding(
                            get: { settings.effectiveNutritionixAppID },
                            set: { settings.nutritionixAppID = $0 }
                        ),
                        focusedField: $focusedField,
                        field: .nutritionixAppID
                    )

                    ParserTextField(
                        title: "Nutritionix API key",
                        placeholder: "API key",
                        icon: "key.fill",
                        text: Binding(
                            get: { settings.effectiveNutritionixAPIKey },
                            set: { settings.nutritionixAPIKey = $0 }
                        ),
                        focusedField: $focusedField,
                        field: .nutritionixAPIKey
                    )
                }

                ParserToggleRow(
                    title: "USDA catalog search",
                    subtitle: settings.effectiveUSDASearchEnabled ? "Searches FoodData Central when local matching is unsure." : "Off by default. Adds remote food lookup for dishes like Pad Thai.",
                    icon: "magnifyingglass.circle.fill",
                    isOn: settings.effectiveUSDASearchEnabled,
                    accent: NourishColors.blueBell
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.usdaSearchEnabled = !settings.effectiveUSDASearchEnabled
                    }
                }

                if settings.effectiveUSDASearchEnabled {
                    ParserTextField(
                        title: "USDA API key",
                        placeholder: "FoodData Central API key",
                        icon: "key.fill",
                        text: Binding(
                            get: { settings.effectiveUSDAAPIKey },
                            set: { settings.usdaAPIKey = $0 }
                        ),
                        focusedField: $focusedField,
                        field: .usdaAPIKey
                    )

                    Text("USDA search is remote. It only stores the confirmed result in your local log.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ParserToggleRow(
                    title: "Open Food Facts",
                    subtitle: settings.effectiveOpenFoodFactsSearchEnabled ? "Searches global packaged foods when other matchers are unsure." : "Useful for international packaged foods.",
                    icon: "globe",
                    isOn: settings.effectiveOpenFoodFactsSearchEnabled,
                    accent: NourishColors.blueBell
                ) {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        settings.openFoodFactsSearchEnabled = !settings.effectiveOpenFoodFactsSearchEnabled
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
#endif

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
        foodCorrections.forEach { modelContext.delete($0) }

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
            primarySettings.localLLMEnabled = false
            primarySettings.ollamaBaseURL = AppConfiguration.defaultOllamaBaseURL.nilIfEmpty
            primarySettings.ollamaModel = AppConfiguration.defaultOllamaModel.nilIfEmpty
            primarySettings.usdaSearchEnabled = AppConfiguration.hasUSDAAPIKey
            primarySettings.usdaAPIKey = AppConfiguration.usdaAPIKey.nilIfEmpty
            primarySettings.nutritionixSearchEnabled = AppConfiguration.hasNutritionixCredentials
            primarySettings.nutritionixAppID = AppConfiguration.nutritionixAppID.nilIfEmpty
            primarySettings.nutritionixAPIKey = AppConfiguration.nutritionixAPIKey.nilIfEmpty
            primarySettings.openFoodFactsSearchEnabled = true
            settingsRows.dropFirst().forEach { modelContext.delete($0) }
        } else {
            modelContext.insert(AppSettings.withBundledProviderDefaults())
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
        guard settingsRows.isEmpty else {
            applyBundledProviderSettings()
            return
        }
        modelContext.insert(AppSettings.withBundledProviderDefaults())
    }

    private func applyBundledProviderSettings() {
        guard let settings = settingsRows.first else { return }

        if settings.usdaAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            settings.usdaAPIKey = AppConfiguration.usdaAPIKey.nilIfEmpty
        }

        if settings.nutritionixAppID?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            settings.nutritionixAppID = AppConfiguration.nutritionixAppID.nilIfEmpty
        }

        if settings.nutritionixAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            settings.nutritionixAPIKey = AppConfiguration.nutritionixAPIKey.nilIfEmpty
        }

        if settings.openFoodFactsSearchEnabled == nil {
            settings.openFoodFactsSearchEnabled = true
        }

        if settings.usdaSearchEnabled == nil, AppConfiguration.hasUSDAAPIKey {
            settings.usdaSearchEnabled = true
        }

        if settings.nutritionixSearchEnabled == nil, AppConfiguration.hasNutritionixCredentials {
            settings.nutritionixSearchEnabled = true
        }
    }
}

private enum PersonalizationField: Hashable {
    case partnerName
    case bottleName
    case ollamaBaseURL
    case ollamaModel
    case usdaAPIKey
    case nutritionixAppID
    case nutritionixAPIKey
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

private struct ParserTextField: View {
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(NourishColors.charcoalBlue)
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                TextField(placeholder, text: $text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(NourishColors.ink)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused(focusedField, equals: field)
            }
            .padding(12)
            .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
