import SwiftUI

struct MealCard: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 14) {
            MealThumbnail(fileName: meal.photoFileName)

            VStack(alignment: .leading, spacing: 6) {
                Label(meal.mealType.rawValue, systemImage: meal.mealType.icon)
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.lavenderDeep)
                Text(meal.name)
                    .font(NourishTypography.section)
                    .foregroundStyle(NourishColors.ink)
                Text("\(meal.foodItems.count) items")
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }

            Spacer()

            Text("\(meal.totalCalories)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.ink)
            Text("cal")
                .font(NourishTypography.caption)
                .foregroundStyle(NourishColors.muted)
        }
        .padding(16)
        .background(NourishColors.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct MealThumbnail: View {
    let fileName: String?

    var body: some View {
        Group {
            if let fileName, let image = ImageStore.loadImage(fileName: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [NourishColors.blushSoft, NourishColors.mintSoft], startPoint: .top, endPoint: .bottom)
                    Image(systemName: "fork.knife")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(NourishColors.lavender)
                }
            }
        }
        .frame(width: 62, height: 62)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

