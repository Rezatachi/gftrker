import SwiftData
import SwiftUI

struct MealsListView: View {
    @Environment(\.appTheme) private var appTheme
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]
    @State private var showingAddMeal = false

    private var todayMeals: [Meal] {
        meals.onDay(.now)
    }

    private var totalMealsCalories: Int {
        todayMeals.reduce(0) { $0 + $1.totalCalories }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        todaySummary
                        mealTimeline
                    }
                    .padding(20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Meals")
                    .font(NourishTypography.title)
                    .foregroundStyle(NourishColors.ink)
                Text("A soft log of what fueled the day.")
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.muted)
            }

            Spacer()

            Button {
                showingAddMeal = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [NourishColors.lavender, NourishColors.blush],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: NourishColors.lavender.opacity(0.26), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add meal")
        }
    }

    private var todaySummary: some View {
        PastelCard(tint: .white) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(NourishColors.blushSoft)
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(NourishColors.lavender)
                }
                .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Today so far")
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Text("\(todayMeals.count) \(todayMeals.count == 1 ? "meal" : "meals") logged")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(totalMealsCalories)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                    Text("cal")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }
            }
        }
    }

    private var mealTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent meals")
                .font(NourishTypography.section)
                .foregroundStyle(NourishColors.ink)

            if meals.isEmpty {
                emptyState
            } else {
                ForEach(meals) { meal in
                    NavigationLink {
                        MealDetailView(meal: meal)
                    } label: {
                        PolishedMealRow(meal: meal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        PastelCard(tint: NourishColors.blushSoft) {
            VStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(NourishColors.lavender)
                Text("Start with one gentle log")
                    .font(NourishTypography.cardTitle)
                    .foregroundStyle(NourishColors.ink)
                    .multilineTextAlignment(.center)
                Text("Meals do not need to be perfect. A consistent estimate is enough to build the habit.")
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.muted)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Log first meal", systemImage: "plus") {
                    showingAddMeal = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct PolishedMealRow: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 14) {
            MealThumbnail(fileName: meal.photoFileName)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: meal.mealType.icon)
                    Text(meal.mealType.rawValue)
                }
                .font(NourishTypography.caption)
                .foregroundStyle(NourishColors.lavenderDeep)

                Text(meal.name)
                    .font(NourishTypography.section)
                    .foregroundStyle(NourishColors.ink)
                    .lineLimit(1)

                Text(meal.date.formatted(.dateTime.weekday(.abbreviated).hour().minute()))
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(meal.totalCalories)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(NourishColors.ink)
                Text("\(meal.foodItems.count) items")
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(.white.opacity(0.68), lineWidth: 1)
                )
        )
        .shadow(color: NourishColors.lavender.opacity(0.10), radius: 18, x: 0, y: 10)
    }
}
