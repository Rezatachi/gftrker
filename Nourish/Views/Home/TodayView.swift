import SwiftData
import SwiftUI

struct RootTabView: View {
    @Query private var settingsRows: [AppSettings]
    @State private var selectedTab = 0

    private var appTheme: AppTheme {
        (settingsRows.first?.themeVariant ?? .sageGreen).palette
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            MealsListView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }
                .tag(1)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }
                .tag(2)

            ProfileGoalsView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .tint(appTheme.accent)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .environment(\.appTheme, appTheme)
    }
}

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]
    @Query(sort: \WaterEntry.date, order: .reverse) private var waterEntries: [WaterEntry]
    @Query private var settingsRows: [AppSettings]
    @State private var lovePhrase = LovePhrase.random()
    @State private var lastAddedWaterEntry: WaterEntry?
    @State private var showingWaterUndo = false
    @State private var waterUndoToken = UUID()
    @State private var showingFoodChat = false

    private var settings: AppSettings {
        settingsRows.first ?? AppSettings()
    }

    private var todaysMeals: [Meal] {
        meals.onDay(.now)
    }

    private var todaysWater: [WaterEntry] {
        waterEntries.onDay(.now)
    }

    private var consumedCalories: Int {
        todaysMeals.reduce(0) { $0 + $1.totalCalories }
    }

    private var consumedProtein: Int {
        Int(todaysMeals.reduce(0) { $0 + $1.protein }.rounded())
    }

    private var consumedCarbs: Int {
        Int(todaysMeals.reduce(0) { $0 + $1.carbs }.rounded())
    }

    private var consumedFat: Int {
        Int(todaysMeals.reduce(0) { $0 + $1.fat }.rounded())
    }

    private var waterOunces: Int {
        todaysWater.reduce(0) { $0 + $1.effectiveOunces }
    }

    private var todayCopy: TodayCopy {
        PersonalizedCopyService.todayCopy(
            settings: settings,
            consumedCalories: consumedCalories,
            calorieGoal: settings.dailyCalorieGoal,
            consumedProtein: consumedProtein,
            proteinGoal: settings.effectiveDailyProteinGoal,
            waterOunces: waterOunces,
            waterGoalOunces: settings.effectiveDailyWaterGoalOunces,
            mealCount: todaysMeals.count
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        chatLogCard
                        calorieCard
                        recentMeals
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .onAppear(perform: ensureSettings)
            .fullScreenCover(isPresented: $showingFoodChat) {
                FoodChatLogView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(todayCopy.headline.isEmpty ? lovePhrase.text : todayCopy.headline)
                .font(NourishTypography.title)
                .foregroundStyle(NourishColors.ink)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
            VStack(alignment: .leading, spacing: 2) {
                Text(Date.now.friendlyDay)
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.muted)
                Text(todayCopy.subtitle)
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
        }
    }

    private var calorieCard: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(todayCopy.calorieTitle)
                        .font(NourishTypography.cardTitle)
                        .foregroundStyle(NourishColors.ink)
                    Text(todayCopy.calorieDetail)
                        .font(NourishTypography.body)
                        .foregroundStyle(NourishColors.muted)
                }

                VStack(spacing: 14) {
                    HStack(alignment: .center, spacing: 18) {
                        MetricProgressRing(
                            title: "Calories",
                            value: "\(consumedCalories)",
                            goal: "of \(settings.dailyCalorieGoal)",
                            progress: Double(consumedCalories) / Double(max(settings.dailyCalorieGoal, 1)),
                            color: appTheme.accent,
                            size: 132,
                            lineWidth: 15
                        )

                        MetricProgressRing(
                            title: "Protein",
                            value: "\(consumedProtein)g",
                            goal: "of \(settings.effectiveDailyProteinGoal)g",
                            progress: Double(consumedProtein) / Double(max(settings.effectiveDailyProteinGoal, 1)),
                            color: NourishColors.blueBell,
                            size: 118,
                            lineWidth: 13
                        )
                    }
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 10) {
                        StatPill(title: "Meals", value: "\(todaysMeals.count)")
                        StatPill(title: "Left", value: "\(max(settings.dailyCalorieGoal - consumedCalories, 0)) cal")
                        StatPill(title: "Protein left", value: "\(max(settings.effectiveDailyProteinGoal - consumedProtein, 0))g")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    if consumedCarbs > 0 || consumedFat > 0 {
                        HStack(spacing: 10) {
                            StatPill(title: "Carbs", value: "\(consumedCarbs)g")
                            StatPill(title: "Fat", value: "\(consumedFat)g")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }

    private var hydrationCard: some View {
        PastelCard(tint: NourishColors.mintSoft) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(todayCopy.hydrationTitle, systemImage: "drop.fill")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Spacer()
                    Text("\(waterOunces) / \(settings.effectiveDailyWaterGoalOunces) oz")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .layoutPriority(1)
                }
                WaterDropletsView(ounces: waterOunces, goalOunces: settings.effectiveDailyWaterGoalOunces)
                HStack(spacing: 10) {
                    Button(action: addWater) {
                        Label("+12 oz", systemImage: "plus")
                            .font(NourishTypography.body)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(appTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if showingWaterUndo {
                        Button(action: undoWater) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .font(NourishTypography.body)
                                .foregroundStyle(NourishColors.lavenderDeep)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var chatLogCard: some View {
        Button {
            showingFoodChat = true
        } label: {
            PastelCard(tint: .white) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    appTheme.softSurface.opacity(0.44),
                                    .white.opacity(0.32),
                                    appTheme.secondaryAccent.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(.white.opacity(0.70), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 14) {
                        ChatPreviewBubble(
                            text: "I had a cup of yogurt, 3 mochi, and 2 protein bars",
                            alignment: .trailing,
                            tint: appTheme.accent.opacity(0.32),
                            foreground: .white
                        )

                        ChatPreviewBubble(
                            text: "Found 3 foods. Adjust grams, then add to today.",
                            alignment: .leading,
                            tint: .white.opacity(0.36),
                            foreground: NourishColors.ink
                        )

                        HStack(spacing: 10) {
                            Text("Tell me what you ate...")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(NourishColors.muted.opacity(0.58))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)

                            Spacer()

                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(appTheme.accent.opacity(0.42))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .padding(18)
                }
                .frame(minHeight: 252)
            }
        }
        .buttonStyle(.plain)
    }

    private var recentMeals: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals")
                .font(NourishTypography.section)
                .foregroundStyle(NourishColors.ink)

            if todaysMeals.isEmpty {
                PastelCard(tint: NourishColors.blushSoft) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(todayCopy.emptyMealTitle)
                            .font(NourishTypography.section)
                        Text(todayCopy.emptyMealDetail)
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                    }
                }
            } else {
                ForEach(todaysMeals) { meal in
                    NavigationLink {
                        MealDetailView(meal: meal)
                    } label: {
                        MealCard(meal: meal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var insightGrid: some View {
        HStack(spacing: 12) {
            InsightCard(icon: "bolt.heart.fill", title: todayCopy.firstInsightTitle, value: todayCopy.firstInsightValue)
            InsightCard(icon: "sparkles", title: todayCopy.secondInsightTitle, value: todayCopy.secondInsightValue)
        }
    }

    private func ensureSettings() {
        guard settingsRows.isEmpty else { return }
        modelContext.insert(AppSettings())
    }

    private func addWater() {
        let entry = WaterEntry(glasses: 0, ounces: 12)
        withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
            modelContext.insert(entry)
            lastAddedWaterEntry = entry
            showingWaterUndo = true
            waterUndoToken = UUID()
        }
        let token = waterUndoToken

        Task {
            try? await Task.sleep(for: .seconds(4))
            await MainActor.run {
                guard waterUndoToken == token else { return }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showingWaterUndo = false
                }
            }
        }
    }

    private func undoWater() {
        guard let entry = lastAddedWaterEntry else { return }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            modelContext.delete(entry)
            lastAddedWaterEntry = nil
            showingWaterUndo = false
            waterUndoToken = UUID()
        }
    }
}

private struct MetricProgressRing: View {
    let title: String
    let value: String
    let goal: String
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        VStack(spacing: 9) {
            ZStack {
                ProgressRing(
                    progress: progress,
                    lineWidth: lineWidth,
                    color: color
                )

                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: size > 120 ? 25 : 21, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                    Text(goal)
                        .font(.system(size: size > 120 ? 11 : 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(NourishColors.muted)
                        .minimumScaleFactor(0.72)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
            }
            .frame(width: size, height: size)

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value) \(goal)")
    }
}

private struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded))
            Text(title).font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(NourishColors.ink)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(NourishColors.blushSoft, in: Capsule())
    }
}

private struct ChatPreviewBubble: View {
    let text: String
    let alignment: HorizontalAlignment
    let tint: Color
    let foreground: Color

    var body: some View {
        HStack {
            if alignment == .trailing {
                Spacer(minLength: 46)
            }

            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(foreground.opacity(0.58))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(tint)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(.white.opacity(0.28), lineWidth: 1)
                        )
                )
                .shadow(color: NourishColors.charcoalBlue.opacity(0.035), radius: 10, x: 0, y: 7)

            if alignment == .leading {
                Spacer(minLength: 46)
            }
        }
    }
}

private struct InsightCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(NourishColors.lavender)
                Text(title)
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.ink)
                Text(value)
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LovePhrase {
    let text: String

    static func random() -> LovePhrase {
        phrases.randomElement() ?? LovePhrase(text: "I love you!")
    }

    private static let phrases: [LovePhrase] = [
        LovePhrase(text: "I love you!"),
        LovePhrase(text: "Te amo!"),
        LovePhrase(text: "Je t'aime!"),
        LovePhrase(text: "Ti amo!"),
        LovePhrase(text: "Ich liebe dich!"),
        LovePhrase(text: "Eu te amo!"),
        LovePhrase(text: "Aishiteru!"),
        LovePhrase(text: "Saranghae!"),
        LovePhrase(text: "Nakupenda!"),
        LovePhrase(text: "Mahal kita!"),
        LovePhrase(text: "Ya tebya lyublyu!"),
        LovePhrase(text: "Wo ai ni!")
    ]
}
