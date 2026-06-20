import SwiftData
import SwiftUI

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var appTheme
    @Bindable var meal: Meal
    @State private var draft = FoodDraft()
    @State private var showingDeleteConfirmation = false
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    macroSnapshot
                    foodList
                    addFoodCard
                }
                .padding(20)
                .padding(.bottom, 26)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(NourishColors.lavenderDeep)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .confirmationDialog("Delete this meal?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete meal", role: .destructive) {
                ImageStore.deleteImage(fileName: meal.photoFileName)
                modelContext.delete(meal)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the meal, food items, and local meal photo.")
        }
    }

    private var hero: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 16) {
                ZStack(alignment: .bottomLeading) {
                    MealHeroImage(fileName: meal.photoFileName)
                        .frame(height: 218)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                    HStack(spacing: 8) {
                        Image(systemName: meal.mealType.icon)
                        Text(meal.mealType.rawValue)
                    }
                    .font(NourishTypography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.black.opacity(0.22), in: Capsule())
                    .padding(14)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal name")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                    TextField("Meal name", text: $meal.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .padding(14)
                        .background(NourishColors.blushSoft.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .focused($focusedField, equals: .mealName)
                }

                mealTypePicker
            }
        }
    }

    private var mealTypePicker: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("Meal moment")
                .font(NourishTypography.caption)
                .foregroundStyle(NourishColors.muted)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(MealType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                            meal.mealType = type
                        }
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                            .font(NourishTypography.caption)
                            .foregroundStyle(meal.mealType == type ? .white : NourishColors.lavenderDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(meal.mealType == type ? NourishColors.lavender : NourishColors.blushSoft.opacity(0.72))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(.white.opacity(0.72), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var macroSnapshot: some View {
        PastelCard(tint: NourishColors.mintSoft) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meal energy")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                        Text("\(meal.totalCalories) cal")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(NourishColors.ink)
                    }
                    Spacer()
                    Text("\(meal.foodItems.count) \(meal.foodItems.count == 1 ? "item" : "items")")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.lavenderDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.72), in: Capsule())
                }

                HStack(spacing: 10) {
                    MacroPill(title: "Protein", value: "\(Int(meal.protein.rounded()))g", color: NourishColors.lavender)
                    MacroPill(title: "Carbs", value: "\(Int(meal.carbs.rounded()))g", color: NourishColors.blush)
                    MacroPill(title: "Fat", value: "\(Int(meal.fat.rounded()))g", color: NourishColors.mint)
                }
            }
        }
    }

    private var foodList: some View {
        PastelCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Food items")
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Spacer()
                    Text("Tap fields to edit")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }

                if meal.foodItems.isEmpty {
                    EmptyFoodState()
                } else {
                    ForEach(meal.foodItems) { item in
                        FoodItemEditCard(
                            item: item,
                            focusedField: $focusedField,
                            onDelete: { delete(item) }
                        )
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var addFoodCard: some View {
        PastelCard(tint: NourishColors.blushSoft) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add another bite")
                            .font(NourishTypography.section)
                            .foregroundStyle(NourishColors.ink)
                        Text("Keep it approximate and consistent.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(NourishColors.lavender)
                }

                DraftFoodFields(draft: $draft, focusedField: $focusedField)

                PrimaryButton(
                    title: draftIsValid ? "Add \(draftLineCalories) calories" : "Add food item",
                    systemImage: "plus"
                ) {
                    addDraftFood()
                }
                .disabled(!draftIsValid)
                .opacity(draftIsValid ? 1 : 0.58)
            }
        }
    }

    private var draftIsValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.calories > 0
    }

    private var draftLineCalories: Int {
        Int((Double(draft.calories) * draft.quantity).rounded())
    }

    private func addDraftFood() {
        guard draftIsValid else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            let item = FoodItem(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                servingSize: draft.servingSize,
                quantity: draft.quantity,
                estimatedCalories: draft.calories,
                protein: draft.protein,
                carbs: draft.carbs,
                fat: draft.fat,
                meal: meal
            )
            meal.foodItems.append(item)
            draft = FoodDraft()
            focusedField = nil
        }
    }

    private func delete(_ item: FoodItem) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            modelContext.delete(item)
        }
    }

}

private enum Field: Hashable {
    case mealName
    case draftName
    case draftServing
    case draftQuantity
    case draftCalories
    case draftProtein
    case draftCarbs
    case draftFat
    case itemName(UUID)
    case itemServing(UUID)
    case itemQuantity(UUID)
    case itemCalories(UUID)
    case itemProtein(UUID)
    case itemCarbs(UUID)
    case itemFat(UUID)
}

private struct MealHeroImage: View {
    let fileName: String?

    var body: some View {
        Group {
            if let fileName, let image = ImageStore.loadImage(fileName: fileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [NourishColors.blushSoft, NourishColors.mintSoft, .white.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 54, weight: .bold))
                            .foregroundStyle(NourishColors.lavender)
                        Text("No photo yet")
                            .font(NourishTypography.body)
                            .foregroundStyle(NourishColors.muted)
                    }
                }
            }
        }
    }
}

private struct MacroPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.ink)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(color.opacity(0.42))
                .frame(width: 10, height: 10)
                .padding(10)
        }
    }
}

private struct EmptyFoodState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(NourishColors.blush)
            Text("Nothing here yet")
                .font(NourishTypography.section)
                .foregroundStyle(NourishColors.ink)
            Text("Add the first item below. A rough estimate is enough to keep the habit gentle.")
                .font(NourishTypography.caption)
                .foregroundStyle(NourishColors.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(NourishColors.blushSoft.opacity(0.62), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct FoodItemEditCard: View {
    @Bindable var item: FoodItem
    var focusedField: FocusState<Field?>.Binding
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Food name", text: $item.name)
                        .font(NourishTypography.body)
                        .foregroundStyle(NourishColors.ink)
                        .focused(focusedField, equals: .itemName(item.id))
                    Text("\(item.totalCalories) cal")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.lavenderDeep)
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                }
            }

            HStack(spacing: 10) {
                textField("Serving", text: $item.servingSize, field: .itemServing(item.id))
                doubleField("Qty", value: $item.quantity, field: .itemQuantity(item.id), width: 76)
                intField("Cal", value: $item.estimatedCalories, field: .itemCalories(item.id), width: 82)
            }

            HStack(spacing: 10) {
                doubleField("Protein", value: $item.protein, field: .itemProtein(item.id))
                doubleField("Carbs", value: $item.carbs, field: .itemCarbs(item.id))
                doubleField("Fat", value: $item.fat, field: .itemFat(item.id))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(NourishColors.blushSoft.opacity(0.70))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.white.opacity(0.70), lineWidth: 1)
                )
        )
    }

    private func textField(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
            TextField(title, text: text)
                .font(NourishTypography.caption)
                .padding(10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .focused(focusedField, equals: field)
        }
    }

    private func doubleField(_ title: String, value: Binding<Double>, field: Field, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
            TextField(title, value: value, format: .number)
                .font(NourishTypography.caption)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .focused(focusedField, equals: field)
        }
        .frame(width: width)
    }

    private func intField(_ title: String, value: Binding<Int>, field: Field, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
            TextField(title, value: value, format: .number)
                .font(NourishTypography.caption)
                .keyboardType(.numberPad)
                .padding(10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .focused(focusedField, equals: field)
        }
        .frame(width: width)
    }
}

private struct DraftFoodFields: View {
    @Binding var draft: FoodDraft
    var focusedField: FocusState<Field?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Food name", text: $draft.name)
                .font(NourishTypography.body)
                .padding(14)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .focused(focusedField, equals: .draftName)

            HStack(spacing: 10) {
                textField("Serving", text: $draft.servingSize, field: .draftServing)
                doubleField("Qty", value: $draft.quantity, field: .draftQuantity, width: 76)
                intField("Cal", value: $draft.calories, field: .draftCalories, width: 82)
            }

            HStack(spacing: 10) {
                doubleField("Protein", value: $draft.protein, field: .draftProtein)
                doubleField("Carbs", value: $draft.carbs, field: .draftCarbs)
                doubleField("Fat", value: $draft.fat, field: .draftFat)
            }
        }
    }

    private func textField(_ title: String, text: Binding<String>, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
            TextField(title, text: text)
                .font(NourishTypography.caption)
                .padding(10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .focused(focusedField, equals: field)
        }
    }

    private func doubleField(_ title: String, value: Binding<Double>, field: Field, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
            TextField(title, value: value, format: .number)
                .font(NourishTypography.caption)
                .keyboardType(.decimalPad)
                .padding(10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .focused(focusedField, equals: field)
        }
        .frame(width: width)
    }

    private func intField(_ title: String, value: Binding<Int>, field: Field, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
            TextField(title, value: value, format: .number)
                .font(NourishTypography.caption)
                .keyboardType(.numberPad)
                .padding(10)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .focused(focusedField, equals: field)
        }
        .frame(width: width)
    }
}
