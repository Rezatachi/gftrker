import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @Query(sort: \Meal.date, order: .reverse) private var recentMeals: [Meal]
    @Query(sort: \MealTemplate.updatedAt, order: .reverse) private var mealTemplates: [MealTemplate]
    @State private var name = ""
    @State private var mealType = MealType.breakfast
    @State private var foodDrafts = [FoodDraft()]
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false
    @State private var detectedFoods: [FoodDetectionResult] = []
    @State private var isDetecting = false
    @State private var showingManageFavorites = false
    @State private var templateSaveConfirmation: String?
    @FocusState private var focusedField: Field?
#if DEBUG
    private let recognitionService: FoodRecognitionService = MockFoodRecognitionService()
#endif

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        summaryCard
                        photoPicker
                        mealFields
                        mealTemplatesPicker
                        proteinShortcuts
                        recentFoodsPicker
                        suggestions
                        foodItemsEditor
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: saveMeal)
                        .fontWeight(.bold)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task { await loadPhoto(newValue) }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(image: $selectedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingManageFavorites) {
                ManageFavoriteMealsView()
            }
        }
    }

    private var summaryCard: some View {
        PastelCard(tint: .white) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Meal total")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                    Text("\(draftCalories) cal")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                    Text("\(validDrafts.count) confirmed \(validDrafts.count == 1 ? "item" : "items")")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Label(mealType.rawValue, systemImage: mealType.icon)
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.lavenderDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(NourishColors.blushSoft, in: Capsule())
                    Text(canSave ? "Ready to save" : "Add food + calories")
                        .font(NourishTypography.caption)
                        .foregroundStyle(canSave ? NourishColors.lavenderDeep : NourishColors.muted)
                }
            }
        }
    }

    private var photoPicker: some View {
        PastelCard(tint: NourishColors.blushSoft) {
            VStack(alignment: .leading, spacing: 14) {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 190)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                } else {
                    Image(systemName: "camera.macro")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(NourishColors.lavender)
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                }

                HStack(spacing: 10) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        actionPill(title: selectedImage == nil ? "Choose" : "Change", icon: "photo")
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        Button {
                            showingCamera = true
                        } label: {
                            actionPill(title: "Camera", icon: "camera.fill")
                        }
                    }

                    if selectedImage != nil {
#if DEBUG
                        Button {
                            Task { await detectFoods() }
                        } label: {
                            actionPill(title: isDetecting ? "Reading..." : "Suggest", icon: "sparkles")
                        }
                        .disabled(isDetecting)
#endif
                    }
                }

                Text("The photo stays on this device and is saved only when you save the meal.")
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var mealFields: some View {
        PastelCard {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal name")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                    TextField("e.g. Post-workout lunch", text: $name)
                        .font(NourishTypography.body)
                        .padding(14)
                        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            mealType = type
                        }
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                            .font(NourishTypography.caption)
                            .foregroundStyle(mealType == type ? .white : NourishColors.lavenderDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(mealType == type ? NourishColors.lavender : NourishColors.blushSoft.opacity(0.75))
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

    private var mealTemplatesPicker: some View {
        Group {
            if !sortedMealTemplates.isEmpty {
                PastelCard(tint: appTheme.secondaryAccent.opacity(0.55)) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Favorite meals")
                                    .font(NourishTypography.section)
                                    .foregroundStyle(NourishColors.ink)
                                Text("One tap fills the whole meal. You can still edit everything.")
                                    .font(NourishTypography.caption)
                                    .foregroundStyle(NourishColors.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Button {
                                showingManageFavorites = true
                            } label: {
                                Label("Manage", systemImage: "slider.horizontal.3")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(appTheme.deepAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(.white.opacity(0.68), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(spacing: 10) {
                            ForEach(sortedMealTemplates.prefix(4)) { template in
                                Button {
                                    applyTemplate(template)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(appTheme.accent.opacity(0.14))
                                            Image(systemName: template.mealType.icon)
                                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                                .foregroundStyle(appTheme.accent)
                                        }
                                        .frame(width: 42, height: 42)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                                .foregroundStyle(NourishColors.ink)
                                                .lineLimit(1)
                                            Text("\(template.foodItems.count) items - \(template.totalCalories) cal")
                                                .font(NourishTypography.caption)
                                                .foregroundStyle(NourishColors.muted)
                                        }

                                        Spacer()

                                        Text("Use")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(appTheme.deepAccent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(.white.opacity(0.68), in: Capsule())
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(.white.opacity(0.68))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                    .stroke(.white.opacity(0.80), lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var proteinShortcuts: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]

        return PastelCard(tint: NourishColors.mintSoft.opacity(0.72)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Protein shortcuts")
                            .font(NourishTypography.section)
                            .foregroundStyle(NourishColors.ink)
                        Text("Tap once, then adjust serving or calories if needed.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.lavenderDeep)
                        .padding(10)
                        .background(.white.opacity(0.68), in: Circle())
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(commonProteinShortcuts) { shortcut in
                        Button {
                            addDraft(shortcut.draft)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: shortcut.icon)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(shortcut.tint)
                                        .frame(width: 30, height: 30)
                                        .background(shortcut.tint.opacity(0.14), in: Circle())

                                    Spacer()

                                    Text("\(Int(shortcut.protein))g")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(NourishColors.ink.opacity(0.72))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(shortcut.name)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(NourishColors.ink)
                                        .lineLimit(1)
                                    Text("\(shortcut.calories) cal - \(shortcut.serving)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundStyle(NourishColors.muted)
                                        .lineLimit(1)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.white.opacity(0.70))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(.white.opacity(0.80), lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recentFoodsPicker: some View {
        Group {
            if !recentFoodShortcuts.isEmpty {
                PastelCard(tint: appTheme.softSurface.opacity(0.72)) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Recent foods")
                                    .font(NourishTypography.section)
                                    .foregroundStyle(NourishColors.ink)
                                Text("Bring back what you log often, then tweak the details.")
                                    .font(NourishTypography.caption)
                                    .foregroundStyle(NourishColors.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(appTheme.deepAccent)
                                .padding(10)
                                .background(.white.opacity(0.68), in: Circle())
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(recentFoodShortcuts) { shortcut in
                                    Button {
                                        addDraft(shortcut.draft)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Image(systemName: "arrow.uturn.forward.circle.fill")
                                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                                    .foregroundStyle(appTheme.accent)

                                                Spacer()

                                                Text("\(shortcut.calories)")
                                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                                    .foregroundStyle(NourishColors.ink.opacity(0.72))
                                            }

                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(shortcut.name)
                                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                                    .foregroundStyle(NourishColors.ink)
                                                    .lineLimit(1)
                                                Text(shortcut.serving)
                                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                    .foregroundStyle(NourishColors.muted)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(12)
                                        .frame(width: 150, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(.white.opacity(0.70))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                        .stroke(.white.opacity(0.80), lineWidth: 1)
                                                )
                                        )
                                        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    private var suggestions: some View {
        Group {
            if !detectedFoods.isEmpty {
                PastelCard(tint: NourishColors.mintSoft) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photo suggestions")
                            .font(NourishTypography.section)
                        Text("Suggestions are not auto-logged. Add only what looks right.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)

                        ForEach(detectedFoods) { result in
                            Button {
                                addDraft(FoodDraft(
                                    name: result.foodName,
                                    servingSize: result.estimatedServing,
                                    calories: result.estimatedCalories ?? 0
                                ))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(result.foodName)
                                            .font(NourishTypography.body)
                                        Text("\(result.estimatedServing) - \(Int(result.confidence * 100))% confidence")
                                            .font(NourishTypography.caption)
                                            .foregroundStyle(NourishColors.muted)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(NourishColors.lavender)
                                }
                                .padding(12)
                                .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var foodItemsEditor: some View {
        PastelCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Food items")
                        .font(NourishTypography.section)
                    Spacer()
                    Button {
                        addDraft(FoodDraft())
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.lavenderDeep)
                    }
                }

                ForEach($foodDrafts) { $draft in
                    FoodDraftCard(
                        draft: $draft,
                        canRemove: foodDrafts.count > 1,
                        focusedField: $focusedField,
                        onRemove: { removeDraft(id: draft.id) }
                    )
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                }

                PrimaryButton(
                    title: canSave ? "Save \(draftCalories) calorie meal" : "Add food calories to save",
                    systemImage: "checkmark.circle.fill"
                ) {
                    saveMeal()
                }
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.58)

                Button {
                    saveTemplate()
                } label: {
                    Label(templateSaveConfirmation ?? "Save this meal as a favorite", systemImage: templateSaveConfirmation == nil ? "star.fill" : "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(canSave ? appTheme.deepAccent : NourishColors.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.56)
            }
        }
    }

    private func actionPill(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(NourishTypography.caption)
            .foregroundStyle(NourishColors.lavenderDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var validDrafts: [FoodDraft] {
        foodDrafts.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.calories > 0 }
    }

    private var draftCalories: Int {
        validDrafts.reduce(0) { $0 + Int((Double($1.calories) * $1.quantity).rounded()) }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !validDrafts.isEmpty
    }

    private var sortedMealTemplates: [MealTemplate] {
        mealTemplates.sorted {
            let lhsIndex = $0.sortIndex ?? Int.max
            let rhsIndex = $1.sortIndex ?? Int.max
            if lhsIndex == rhsIndex {
                return $0.updatedAt > $1.updatedAt
            }
            return lhsIndex < rhsIndex
        }
    }

    private var commonProteinShortcuts: [ProteinShortcut] {
        [
            ProteinShortcut(name: "Greek yogurt", serving: "1 cup", calories: 150, protein: 20, carbs: 8, fat: 4, icon: "cup.and.saucer.fill", tint: NourishColors.lavenderDeep),
            ProteinShortcut(name: "Eggs", serving: "2 large eggs", calories: 140, protein: 12, carbs: 1, fat: 10, icon: "circle.grid.2x2.fill", tint: NourishColors.blush),
            ProteinShortcut(name: "Chicken", serving: "4 oz", calories: 180, protein: 35, carbs: 0, fat: 4, icon: "fork.knife", tint: NourishColors.mint),
            ProteinShortcut(name: "Salmon", serving: "4 oz", calories: 230, protein: 25, carbs: 0, fat: 14, icon: "fish.fill", tint: NourishColors.blueBell),
            ProteinShortcut(name: "Protein shake", serving: "1 shake", calories: 160, protein: 30, carbs: 5, fat: 2, icon: "waterbottle.fill", tint: NourishColors.lavender),
            ProteinShortcut(name: "Cottage cheese", serving: "1 cup", calories: 220, protein: 28, carbs: 8, fat: 9, icon: "heart.fill", tint: NourishColors.bubblegumPink)
        ]
    }

    private var recentFoodShortcuts: [RecentFoodShortcut] {
        var seenKeys = Set<String>()
        var shortcuts: [RecentFoodShortcut] = []

        for meal in recentMeals {
            for item in meal.foodItems {
                let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, item.estimatedCalories > 0 else { continue }

                let key = "\(name.lowercased())|\(item.servingSize.lowercased())"
                guard seenKeys.insert(key).inserted else { continue }

                shortcuts.append(
                    RecentFoodShortcut(
                        id: key,
                        name: name,
                        serving: item.servingSize,
                        quantity: item.quantity,
                        calories: item.estimatedCalories,
                        protein: item.protein,
                        carbs: item.carbs,
                        fat: item.fat
                    )
                )

                if shortcuts.count == 10 {
                    return shortcuts
                }
            }
        }

        return shortcuts
    }

    private func addDraft(_ draft: FoodDraft) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            if foodDrafts.count == 1,
               foodDrafts[0].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               foodDrafts[0].calories == 0 {
                foodDrafts[0] = draft
            } else {
                foodDrafts.append(draft)
            }
        }
    }

    private func applyTemplate(_ template: MealTemplate) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            name = template.name
            mealType = template.mealType
            foodDrafts = template.foodItems.map {
                FoodDraft(
                    name: $0.name,
                    servingSize: $0.servingSize,
                    quantity: $0.quantity,
                    calories: $0.estimatedCalories,
                    protein: $0.protein,
                    carbs: $0.carbs,
                    fat: $0.fat
                )
            }
            if foodDrafts.isEmpty {
                foodDrafts = [FoodDraft()]
            }
            focusedField = nil
        }
    }

    private func saveTemplate() {
        guard canSave else { return }

        let templateName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingTemplate = mealTemplates.first {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveCompare(templateName) == .orderedSame
        }
        let template = existingTemplate ?? MealTemplate(name: templateName, mealType: mealType, sortIndex: nextTemplateSortIndex)

        template.name = templateName
        template.mealType = mealType
        template.updatedAt = .now
        for item in template.foodItems {
            modelContext.delete(item)
        }
        template.foodItems.removeAll()
        template.foodItems = validDrafts.map {
            TemplateFoodItem(
                name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                servingSize: $0.servingSize,
                quantity: $0.quantity,
                estimatedCalories: $0.calories,
                protein: $0.protein,
                carbs: $0.carbs,
                fat: $0.fat,
                template: template
            )
        }

        if existingTemplate == nil {
            modelContext.insert(template)
        }
        templateSaveConfirmation = "Favorite saved"
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            templateSaveConfirmation = nil
        }
    }

    private var nextTemplateSortIndex: Int {
        (mealTemplates.compactMap(\.sortIndex).max() ?? -1) + 1
    }

    private func removeDraft(id: UUID) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            guard foodDrafts.count > 1 else {
                foodDrafts = [FoodDraft()]
                return
            }
            foodDrafts.removeAll { $0.id == id }
        }
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        selectedImage = image
        detectedFoods = []
    }

    private func detectFoods() async {
#if DEBUG
        guard let selectedImage else { return }
        isDetecting = true
        defer { isDetecting = false }
        detectedFoods = (try? await recognitionService.detectFoods(in: selectedImage)) ?? []
#endif
    }

    private func saveMeal() {
        let photoFileName = try? selectedImage.map(ImageStore.saveImage)
        let meal = Meal(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            mealType: mealType,
            photoFileName: photoFileName ?? nil
        )
        meal.foodItems = validDrafts.map {
            FoodItem(
                name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines),
                servingSize: $0.servingSize,
                quantity: $0.quantity,
                estimatedCalories: $0.calories,
                protein: $0.protein,
                carbs: $0.carbs,
                fat: $0.fat,
                meal: meal
            )
        }
        modelContext.insert(meal)
        dismiss()
    }

    private enum Field: Hashable {
        case mealName
        case foodName(UUID)
        case serving(UUID)
        case quantity(UUID)
        case calories(UUID)
        case protein(UUID)
        case carbs(UUID)
        case fat(UUID)
    }

    private struct ProteinShortcut: Identifiable {
        let id = UUID()
        let name: String
        let serving: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let icon: String
        let tint: Color

        var draft: FoodDraft {
            FoodDraft(
                name: name,
                servingSize: serving,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
        }
    }

    private struct RecentFoodShortcut: Identifiable {
        let id: String
        let name: String
        let serving: String
        let quantity: Double
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double

        var draft: FoodDraft {
            FoodDraft(
                name: name,
                servingSize: serving,
                quantity: quantity,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat
            )
        }
    }

    private struct FoodDraftCard: View {
        @Binding var draft: FoodDraft
        let canRemove: Bool
        var focusedField: FocusState<Field?>.Binding
        let onRemove: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Food name", text: $draft.name)
                            .font(NourishTypography.body)
                            .focused(focusedField, equals: .foodName(draft.id))
                        Text("\(lineCalories) cal")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.lavenderDeep)
                    }

                    Spacer()

                    if canRemove {
                        Button(role: .destructive, action: onRemove) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                        }
                    }
                }

                HStack(spacing: 10) {
                    entryField("Serving", text: $draft.servingSize, field: .serving(draft.id))
                    numberField("Qty", value: $draft.quantity, field: .quantity(draft.id), width: 76)
                    intField("Cal", value: $draft.calories, field: .calories(draft.id), width: 82)
                }

                HStack(spacing: 10) {
                    numberField("Protein", value: $draft.protein, field: .protein(draft.id))
                    numberField("Carbs", value: $draft.carbs, field: .carbs(draft.id))
                    numberField("Fat", value: $draft.fat, field: .fat(draft.id))
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

        private var lineCalories: Int {
            Int((Double(draft.calories) * draft.quantity).rounded())
        }

        private func entryField(_ title: String, text: Binding<String>, field: Field) -> some View {
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

        private func numberField(_ title: String, value: Binding<Double>, field: Field, width: CGFloat? = nil) -> some View {
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
}

struct FoodDraft: Identifiable {
    let id = UUID()
    var name = ""
    var servingSize = "1 serving"
    var quantity = 1.0
    var calories = 0
    var protein = 0.0
    var carbs = 0.0
    var fat = 0.0
}

private struct ManageFavoriteMealsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @Query private var templates: [MealTemplate]

    private var sortedTemplates: [MealTemplate] {
        templates.sorted {
            let lhsIndex = $0.sortIndex ?? Int.max
            let rhsIndex = $1.sortIndex ?? Int.max
            if lhsIndex == rhsIndex {
                return $0.updatedAt > $1.updatedAt
            }
            return lhsIndex < rhsIndex
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        if sortedTemplates.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(sortedTemplates.enumerated()), id: \.element.id) { index, template in
                                    FavoriteMealManageRow(
                                        template: template,
                                        canMoveUp: index > 0,
                                        canMoveDown: index < sortedTemplates.count - 1,
                                        onMoveUp: { move(template, offset: -1) },
                                        onMoveDown: { move(template, offset: 1) },
                                        onDelete: { delete(template) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 26)
                }
            }
            .navigationTitle("Favorite Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .onAppear(perform: normalizeSortOrder)
        }
    }

    private var header: some View {
        PastelCard(tint: .white) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(appTheme.secondaryAccent.opacity(0.42))
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(appTheme.accent)
                }
                .frame(width: 70, height: 70)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Keep the fast stuff close")
                        .font(NourishTypography.section)
                        .foregroundStyle(NourishColors.ink)
                    Text("Rename, delete, or reorder the meals you use most.")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
        }
    }

    private var emptyState: some View {
        PastelCard(tint: appTheme.softSurface.opacity(0.74)) {
            VStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(appTheme.accent)
                Text("No favorites yet")
                    .font(NourishTypography.cardTitle)
                    .foregroundStyle(NourishColors.ink)
                Text("Save a meal from the logging screen and it will appear here.")
                    .font(NourishTypography.body)
                    .foregroundStyle(NourishColors.muted)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func move(_ template: MealTemplate, offset: Int) {
        var ordered = sortedTemplates
        guard let source = ordered.firstIndex(where: { $0.id == template.id }) else { return }
        let destination = source + offset
        guard ordered.indices.contains(destination) else { return }

        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            ordered.swapAt(source, destination)
            normalize(ordered)
        }
    }

    private func delete(_ template: MealTemplate) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            let remaining = sortedTemplates.filter { $0.id != template.id }
            modelContext.delete(template)
            normalize(remaining)
        }
    }

    private func normalizeSortOrder() {
        normalize(sortedTemplates)
    }

    private func normalize(_ ordered: [MealTemplate]) {
        for (index, template) in ordered.enumerated() {
            template.sortIndex = index
        }
    }
}

private struct FavoriteMealManageRow: View {
    @Environment(\.appTheme) private var appTheme
    @Bindable var template: MealTemplate
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(appTheme.accent.opacity(0.14))
                    Image(systemName: template.mealType.icon)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(appTheme.accent)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 5) {
                    TextField("Favorite meal name", text: $template.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .textInputAutocapitalization(.words)
                        .onChange(of: template.name) { _, _ in
                            template.updatedAt = .now
                        }
                    Text("\(template.foodItems.count) items - \(template.totalCalories) cal")
                        .font(NourishTypography.caption)
                        .foregroundStyle(NourishColors.muted)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onMoveUp) {
                    manageActionLabel("Up", icon: "chevron.up")
                }
                .disabled(!canMoveUp)
                .opacity(canMoveUp ? 1 : 0.38)

                Button(action: onMoveDown) {
                    manageActionLabel("Down", icon: "chevron.down")
                }
                .disabled(!canMoveDown)
                .opacity(canMoveDown ? 1 : 0.38)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.magentaBloom)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(.white.opacity(0.62), in: Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.78), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private func manageActionLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(appTheme.deepAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.62), in: Capsule())
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding private var image: UIImage?
        private let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            self._image = image
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            image = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
