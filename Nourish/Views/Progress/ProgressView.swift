import Charts
import SwiftData
import SwiftUI

struct ProgressView: View {
    @Environment(\.appTheme) private var appTheme
    @Query(sort: \Meal.date) private var meals: [Meal]
    @Query(sort: \WaterEntry.date) private var waterEntries: [WaterEntry]
    @Query private var settingsRows: [AppSettings]

    private var settings: AppSettings {
        settingsRows.first ?? AppSettings()
    }

    private var averageCalories: Int {
        guard !lastSevenDays.isEmpty else { return 0 }
        return lastSevenDays.reduce(0) { $0 + $1.calories } / lastSevenDays.count
    }

    private var averageProtein: Int {
        guard !lastSevenDays.isEmpty else { return 0 }
        return Int((lastSevenDays.reduce(0) { $0 + $1.protein } / Double(lastSevenDays.count)).rounded())
    }

    private var hydrationDaysHit: Int {
        lastSevenDays.filter { $0.waterOunces >= settings.effectiveDailyWaterGoalOunces }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        weeklySnapshot
                        calorieTrend
                        proteinTrend
                        hydrationTrend
                        insightCard
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Progress")
                .font(NourishTypography.title)
                .foregroundStyle(NourishColors.ink)
            Text("Gentle trends, not judgment.")
                .font(NourishTypography.body)
                .foregroundStyle(NourishColors.muted)
        }
    }

    private var weeklySnapshot: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ProgressMetricCard(
                    icon: "flame.fill",
                    title: "Avg calories",
                    value: "\(averageCalories)",
                    detail: "7-day rhythm",
                    tint: NourishColors.blushSoft,
                    accent: NourishColors.bubblegumPink
                )

                ProgressMetricCard(
                    icon: "drop.fill",
                    title: "Hydration wins",
                    value: "\(hydrationDaysHit)/7",
                    detail: "goal days",
                    tint: NourishColors.mintSoft,
                    accent: NourishColors.blueBell
                )
            }

            proteinSnapshot
        }
    }

    private var proteinSnapshot: some View {
        ProgressMetricCard(
            icon: "bolt.heart.fill",
            title: "Avg protein",
            value: "\(averageProtein)g",
            detail: "7-day rhythm",
            tint: NourishColors.blushSoft.opacity(0.70),
            accent: NourishColors.magentaBloom
        )
    }

    private var calorieTrend: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 16) {
                ChartHeader(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weekly calories",
                    subtitle: "Goal line: \(settings.dailyCalorieGoal) cal"
                )

                Chart(lastSevenDays, id: \.date) { day in
                    AreaMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NourishColors.blueBell.opacity(0.26), NourishColors.blueBell.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(NourishColors.blueBell)

                    PointMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .symbolSize(54)
                    .foregroundStyle(NourishColors.bubblegumPink)

                    RuleMark(y: .value("Goal", settings.dailyCalorieGoal))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .foregroundStyle(NourishColors.charcoalBlue.opacity(0.30))
                }
                .frame(height: 230)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(NourishColors.line.opacity(0.45))
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(NourishColors.muted)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(NourishColors.muted)
                    }
                }
            }
        }
    }

    private var hydrationTrend: some View {
        PastelCard(tint: NourishColors.mintSoft) {
            VStack(alignment: .leading, spacing: 16) {
                ChartHeader(
                    icon: "drop.fill",
                    title: "Hydration consistency",
                    subtitle: "Goal: \(settings.effectiveDailyWaterGoalOunces) oz"
                )

                Chart(lastSevenDays, id: \.date) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Ounces", day.waterOunces)
                    )
                    .foregroundStyle(day.waterOunces >= settings.effectiveDailyWaterGoalOunces ? NourishColors.blueBell : NourishColors.mint)

                    RuleMark(y: .value("Goal", settings.effectiveDailyWaterGoalOunces))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .foregroundStyle(NourishColors.charcoalBlue.opacity(0.30))
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(NourishColors.line.opacity(0.45))
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(NourishColors.muted)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(NourishColors.muted)
                    }
                }
            }
        }
    }

    private var proteinTrend: some View {
        PastelCard(tint: NourishColors.blushSoft.opacity(0.74)) {
            VStack(alignment: .leading, spacing: 16) {
                ChartHeader(
                    icon: "bolt.heart.fill",
                    title: "Weekly protein",
                    subtitle: "Goal line: \(settings.effectiveDailyProteinGoal)g"
                )

                Chart(lastSevenDays, id: \.date) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Protein", day.protein)
                    )
                    .cornerRadius(8)
                    .foregroundStyle(day.protein >= Double(settings.effectiveDailyProteinGoal) ? NourishColors.magentaBloom : NourishColors.bubblegumPink.opacity(0.68))

                    RuleMark(y: .value("Goal", settings.effectiveDailyProteinGoal))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .foregroundStyle(NourishColors.charcoalBlue.opacity(0.30))
                }
                .frame(height: 220)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(NourishColors.line.opacity(0.45))
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(NourishColors.muted)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(NourishColors.muted)
                    }
                }
            }
        }
    }

    private var insightCard: some View {
        PastelCard(tint: NourishColors.blushSoft) {
            HStack(spacing: 14) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(NourishColors.magentaBloom)
                    .frame(width: 58, height: 58)
                    .background(.white.opacity(0.72), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Consistency over perfection")
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Text("Build a calm pattern you can sustain, not a perfect chart every day.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }
            }
        }
    }

    private var lastSevenDays: [DayMetric] {
        (0..<7).reversed().map { offset in
            let date = Calendar.app.date(byAdding: .day, value: -offset, to: Date.now) ?? .now
            let calories = meals.onDay(date).reduce(0) { $0 + $1.totalCalories }
            let protein = meals.onDay(date).reduce(0) { $0 + $1.protein }
            let waterOunces = waterEntries.onDay(date).reduce(0) { $0 + $1.effectiveOunces }
            return DayMetric(date: date, calories: calories, protein: protein, waterOunces: waterOunces)
        }
    }
}

private struct ProgressMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let tint: Color
    let accent: Color

    var body: some View {
        PastelCard(tint: tint) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(accent)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(NourishColors.ink)
                Text(title)
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
                Text(detail)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ChartHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(NourishColors.blueBell)
                .frame(width: 42, height: 42)
                .background(NourishColors.mintSoft.opacity(0.80), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

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

private struct DayMetric {
    let date: Date
    let calories: Int
    let protein: Double
    let waterOunces: Int
}
