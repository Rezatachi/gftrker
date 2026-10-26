import SwiftData
import SwiftUI

struct FoodChatLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @Query private var settingsRows: [AppSettings]
    @State private var messages: [FoodChatMessage] = [
        FoodChatMessage(role: .assistant, text: "Tell me what you ate in plain English. I will estimate it, then you can adjust before anything is added.")
    ]
    @State private var inputText = ""
    @State private var isParsing = false
    @State private var parsedResult: ParsedFoodResult?
    @State private var reviewItems: [ParsedFoodItemDraft] = []
    @State private var mealType = MealType.currentDefault
    @State private var errorMessage: String?
    @State private var showingManualLog = false
    @FocusState private var inputFocused: Bool

    private let quickPrompts = [
        FoodQuickPrompt(title: "yogurt bowl", message: "Greek yogurt bowl with granola"),
        FoodQuickPrompt(title: "protein bar", message: "1 protein bar"),
        FoodQuickPrompt(title: "coffee", message: "iced latte"),
        FoodQuickPrompt(title: "same breakfast", message: "Greek yogurt bowl with granola and coffee"),
        FoodQuickPrompt(title: "chicken bowl", message: "chicken rice bowl"),
        FoodQuickPrompt(title: "eggs + toast", message: "two eggs and avocado toast")
    ]

    private var settings: AppSettings {
        settingsRows.first ?? AppSettings()
    }

    private var parsingService: FoodParsingService {
        correctionMemoryService
    }

    private var correctionMemoryService: FoodCorrectionMemoryService {
        FoodCorrectionMemoryService(
            parser: FoodParsingRouter(
                preferLocalParsing: settings.effectivePreferLocalParsing,
                aiFallbackEnabled: settings.effectiveAIFallbackEnabled,
                localLLMEnabled: settings.effectiveLocalLLMEnabled,
                ollamaBaseURL: settings.effectiveOllamaBaseURL,
                ollamaModel: settings.effectiveOllamaModel,
                usdaSearchEnabled: settings.effectiveUSDASearchEnabled,
                usdaAPIKey: settings.effectiveUSDAAPIKey,
                nutritionixSearchEnabled: settings.effectiveNutritionixSearchEnabled,
                nutritionixAppID: settings.effectiveNutritionixAppID,
                nutritionixAPIKey: settings.effectiveNutritionixAPIKey,
                openFoodFactsSearchEnabled: settings.effectiveOpenFoodFactsSearchEnabled
            ),
            store: FoodCorrectionStoreProvider.shared
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 16) {
                                hero
                                promptChips
                                chatTimeline

                                if isParsing {
                                    ThinkingBubble()
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }

                                if !reviewItems.isEmpty {
                                    ParsedFoodReviewCard(
                                        mealType: $mealType,
                                        items: $reviewItems,
                                        onConfirm: saveParsedMeal,
                                        onDiscard: discardParsedResult
                                    )
                                    .transition(.scale(scale: 0.97).combined(with: .opacity))
                                }
                            }
                            .padding(20)
                            .padding(.bottom, 18)
                            .id("chat-bottom")
                        }
                        .onChange(of: messages.count) { _, _ in
                            scrollToBottom(proxy)
                        }
                        .onChange(of: reviewItems.count) { _, _ in
                            scrollToBottom(proxy)
                        }
                    }

                    chatInputBar
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Manual") {
                        showingManualLog = true
                    }
                    .fontWeight(.bold)
                }
            }
            .sheet(isPresented: $showingManualLog) {
                AddMealView()
            }
            .alert("Could not parse that", isPresented: errorAlertBinding) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                inputFocused = true
            }
        }
    }

    private var hero: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [appTheme.secondaryAccent.opacity(0.44), appTheme.softSurface.opacity(0.56)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(appTheme.accent)
                    }
                    .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Log by chatting")
                            .font(NourishTypography.cardTitle)
                            .foregroundStyle(NourishColors.ink)
                        Text("Type naturally. Nothing is added until you review it.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                    }
                }

                HStack(spacing: 8) {
                    Label("Local-first estimates", systemImage: "lock.fill")
                    Circle().fill(NourishColors.muted.opacity(0.32)).frame(width: 4, height: 4)
                    Text("Review before saving")
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(NourishColors.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(appTheme.softSurface.opacity(0.58), in: Capsule())
            }
        }
    }

    private var promptChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickPrompts) { prompt in
                    Button {
                        inputText = prompt.message
                        inputFocused = true
                    } label: {
                        Text(prompt.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(appTheme.deepAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.68), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var chatTimeline: some View {
        VStack(spacing: 12) {
            ForEach(messages) { message in
                ChatBubble(message: message)
            }
        }
    }

    private var chatInputBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Tell me what you ate...", text: $inputText, axis: .vertical)
                    .font(NourishTypography.body)
                    .lineLimit(1...5)
                    .padding(.horizontal, 17)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white.opacity(0.74))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(.white.opacity(0.82), lineWidth: 1)
                            )
                    )
                    .focused($inputFocused)

                Button(action: sendMessage) {
                    Image(systemName: canSend ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(canSend ? appTheme.accent : NourishColors.muted.opacity(0.35))
                        .symbolEffect(.bounce, value: canSend)
                }
                .disabled(!canSend)
                .buttonStyle(.plain)
            }

            Text("Estimates only. Adjust grams before adding.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(NourishColors.muted.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.top, 13)
        .padding(.bottom, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(appTheme.softSurface.opacity(0.28))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isParsing
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isShowing in
                if !isShowing {
                    errorMessage = nil
                }
            }
        )
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""
        parsedResult = nil
        reviewItems = []

        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            messages.append(FoodChatMessage(role: .user, text: text))
            isParsing = true
        }

        Task {
            do {
                let result = try await parsingService.parseFoodLogMessage(text)
                await MainActor.run {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                        parsedResult = result
                        reviewItems = result.items.map(ParsedFoodItemDraft.init)
                        mealType = MealType.inferred(from: text)
                        messages.append(FoodChatMessage(role: .assistant, text: "I found a draft. Adjust anything below, then add it when it looks right."))
                        isParsing = false
                    }
                }
            } catch {
                await MainActor.run {
                    isParsing = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func saveParsedMeal() {
        guard !reviewItems.isEmpty else { return }
        let confirmedResult = parsedResult.map { originalResult in
            ParsedFoodResult(
                id: originalResult.id,
                originalText: originalResult.originalText,
                items: reviewItems.map { draft in
                    ParsedFoodItem(
                        id: draft.id,
                        name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        sourcePhrase: draft.sourcePhrase,
                        detectedQuantity: draft.detectedQuantity,
                        estimatedServing: draft.estimatedServing,
                        estimatedGrams: draft.estimatedGrams,
                        minSuggestedGrams: min(draft.minSuggestedGrams, draft.estimatedGrams),
                        maxSuggestedGrams: max(draft.maxSuggestedGrams, draft.estimatedGrams),
                        estimatedCalories: draft.scaledCalories,
                        estimatedProtein: draft.scaledProtein,
                        estimatedCarbs: draft.scaledCarbs,
                        estimatedFat: draft.scaledFat,
                        confidence: max(draft.confidence, 0.95),
                        source: draft.source,
                        providerCandidateID: draft.providerCandidateID,
                        providerID: draft.providerID,
                        providerDataType: draft.providerDataType,
                        brandOwner: draft.brandOwner,
                        candidateOptions: draft.candidateOptions
                    )
                },
                createdAt: originalResult.createdAt,
                status: .confirmed
            )
        }

        let meal = Meal(
            name: mealTitle,
            mealType: mealType,
            date: .now
        )
        meal.foodItems = reviewItems.map { draft in
            FoodItem(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                servingSize: draft.estimatedServing,
                quantity: 1,
                estimatedCalories: draft.scaledCalories,
                protein: draft.scaledProtein,
                carbs: draft.scaledCarbs,
                fat: draft.scaledFat,
                quantityText: draft.detectedQuantity,
                grams: draft.estimatedGrams,
                minSuggestedGrams: draft.minSuggestedGrams,
                maxSuggestedGrams: draft.maxSuggestedGrams,
                confidence: draft.confidence,
                source: draft.source,
                meal: meal
            )
        }

        modelContext.insert(meal)
        parsedResult = nil
        reviewItems = []
        messages.append(FoodChatMessage(role: .assistant, text: "Added to today. You can still edit it from Meals."))
        if let confirmedResult {
            let service = correctionMemoryService
            Task {
                await service.rememberCorrections(from: confirmedResult)
            }
        }
        dismiss()
    }

    private var mealTitle: String {
        let itemNames = reviewItems.prefix(2).map(\.name).joined(separator: ", ")
        return itemNames.isEmpty ? "\(mealType.rawValue) from chat" : itemNames
    }

    private func discardParsedResult() {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            parsedResult = nil
            reviewItems = []
            messages.append(FoodChatMessage(role: .assistant, text: "Discarded. Send a new description whenever you are ready."))
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo("chat-bottom", anchor: .bottom)
            }
        }
    }
}

private struct FoodChatMessage: Identifiable {
    let id = UUID()
    let role: FoodChatRole
    let text: String
    let createdAt = Date()
}

private struct FoodQuickPrompt: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private enum FoodChatRole {
    case user
    case assistant
}

private struct ChatBubble: View {
    @Environment(\.appTheme) private var appTheme
    let message: FoodChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 42)
            }

            Text(message.text)
                .font(NourishTypography.body)
                .foregroundStyle(message.role == .user ? .white : NourishColors.ink)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(message.role == .user ? appTheme.accent.opacity(0.88) : .white.opacity(0.68))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(.white.opacity(message.role == .user ? 0.22 : 0.74), lineWidth: 1)
                        )
                )
                .shadow(color: NourishColors.charcoalBlue.opacity(message.role == .user ? 0.08 : 0.04), radius: 10, x: 0, y: 7)
                .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer(minLength: 42)
            }
        }
    }
}

private struct ThinkingBubble: View {
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                SwiftUI.ProgressView()
                    .controlSize(.small)
                    .tint(appTheme.accent)
                Text("Drafting an estimate...")
                    .font(NourishTypography.caption)
                    .foregroundStyle(NourishColors.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.white.opacity(0.66), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.68), lineWidth: 1)
            )

            Spacer()
        }
    }
}

private struct ParsedFoodReviewCard: View {
    @Environment(\.appTheme) private var appTheme
    @Binding var mealType: MealType
    @Binding var items: [ParsedFoodItemDraft]
    let onConfirm: () -> Void
    let onDiscard: () -> Void

    private var totalCalories: Int {
        items.reduce(0) { $0 + $1.scaledCalories }
    }

    private var totalProtein: Int {
        Int(items.reduce(0) { $0 + $1.scaledProtein }.rounded())
    }

    private var totalCarbs: Int {
        Int(items.reduce(0) { $0 + $1.scaledCarbs }.rounded())
    }

    private var totalFat: Int {
        Int(items.reduce(0) { $0 + $1.scaledFat }.rounded())
    }

    var body: some View {
        PastelCard(tint: .white) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: "checklist.checked")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(appTheme.accent, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                        .shadow(color: appTheme.accent.opacity(0.18), radius: 14, x: 0, y: 9)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Ready for your review")
                            .font(NourishTypography.cardTitle)
                            .foregroundStyle(NourishColors.ink)
                        Text("Tune serving sizes first. This will not count until you tap Add to Today.")
                            .font(NourishTypography.caption)
                            .foregroundStyle(NourishColors.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ReviewSummaryTray(
                    calories: totalCalories,
                    protein: totalProtein,
                    carbs: totalCarbs,
                    fat: totalFat,
                    foodCount: items.count
                )

                mealTypePicker

                VStack(spacing: 12) {
                    ForEach($items) { $item in
                        FoodReviewItemCard(item: $item)
                    }
                }

                VStack(spacing: 10) {
                    PrimaryButton(title: "Add to Today", systemImage: "checkmark.circle.fill", action: onConfirm)

                    Button(role: .destructive, action: onDiscard) {
                        Text("Discard estimate")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(NourishColors.magentaBloom.opacity(0.86))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(appTheme.softSurface.opacity(0.42), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.50))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.72), lineWidth: 1)
                        )
                )
            }
        }
    }

    private var mealTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MealType.allCases) { type in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                            mealType = type
                        }
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(mealType == type ? .white : appTheme.deepAccent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .background(mealType == type ? appTheme.accent : .white.opacity(0.62), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ReviewSummaryTray: View {
    @Environment(\.appTheme) private var appTheme
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let foodCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(calories)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                    Text("estimated calories")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(protein)g")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(appTheme.deepAccent)
                    Text("protein")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.muted)
                }
            }

            HStack(spacing: 8) {
                ChatStatPill(title: "Foods", value: "\(foodCount)")
                ChatStatPill(title: "Carbs", value: "\(carbs)g")
                ChatStatPill(title: "Fat", value: "\(fat)g")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [appTheme.softSurface.opacity(0.76), .white.opacity(0.58)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.74), lineWidth: 1)
                )
        )
    }
}

private struct FoodReviewItemCard: View {
    @Environment(\.appTheme) private var appTheme
    @Binding var item: ParsedFoodItemDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(appTheme.accent.opacity(0.82))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.58), in: Circle())

                VStack(alignment: .leading, spacing: 5) {
                    TextField("Food name", text: $item.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(NourishColors.ink)
                        .textInputAutocapitalization(.words)
                    HStack(spacing: 6) {
                        Text(item.detectedQuantity)
                        Circle().fill(NourishColors.muted.opacity(0.34)).frame(width: 4, height: 4)
                        Text(item.source.rawValue)
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(NourishColors.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(Int((item.confidence * 100).rounded()))% sure")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(appTheme.deepAccent.opacity(0.84))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.white.opacity(0.56), in: Capsule())

                    if item.candidateOptions.count > 1 {
                        candidateMenu
                    }
                }
            }

            GramRangeSlider(item: $item)

            HStack(spacing: 10) {
                macroBadge("Cal", "\(item.scaledCalories)")
                macroBadge("Protein", "\(Int(item.scaledProtein.rounded()))g")
                macroBadge("Carbs", "\(Int(item.scaledCarbs.rounded()))g")
                macroBadge("Fat", "\(Int(item.scaledFat.rounded()))g")
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(appTheme.softSurface.opacity(0.50))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(.white.opacity(0.76), lineWidth: 1)
                )
        )
    }

    private var candidateMenu: some View {
        Menu {
            ForEach(item.candidateOptions) { candidate in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        item.select(candidate)
                    }
                } label: {
                    Label(
                        candidateMenuTitle(candidate),
                        systemImage: candidate.id == item.providerCandidateID
                            ? "checkmark"
                            : "circle"
                    )
                }
            }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(appTheme.deepAccent)
                .frame(width: 34, height: 30)
                .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel("Change food match")
    }

    private func candidateMenuTitle(_ candidate: ParsedFoodCandidate) -> String {
        let detail = candidate.brandOwner?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? candidate.providerDataType
            ?? candidate.source.rawValue
        return "\(candidate.name) · \(detail) · \(Int(candidate.estimatedGrams.rounded()))g"
    }

    private func macroBadge(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(NourishColors.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ChatStatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(NourishColors.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(.white.opacity(0.54), in: Capsule())
    }
}

private struct GramRangeSlider: View {
    @Environment(\.appTheme) private var appTheme
    @Binding var item: ParsedFoodItemDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("How much?")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(NourishColors.muted)
                Spacer()
                Text("\(Int(item.estimatedGrams.rounded()))g")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(NourishColors.ink)
            }

            Slider(
                value: $item.estimatedGrams,
                in: item.minSuggestedGrams...item.maxSuggestedGrams
            )
            .tint(appTheme.accent)
            .padding(.vertical, 2)

            HStack {
                Text("\(Int(item.minSuggestedGrams))g")
                Spacer()
                Text(item.estimatedServing)
                Spacer()
                Text("\(Int(item.maxSuggestedGrams))g")
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(NourishColors.muted)

            HStack(spacing: 8) {
                quickSizeButton("small", grams: item.minSuggestedGrams)
                quickSizeButton("normal", grams: item.baseGrams)
                quickSizeButton("large", grams: item.maxSuggestedGrams)
            }
        }
    }

    private func quickSizeButton(_ title: String, grams: Double) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                item.estimatedGrams = grams
            }
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(appTheme.deepAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.white.opacity(0.66), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ParsedFoodItemDraft: Identifiable {
    let id: UUID
    var name: String
    var detectedQuantity: String
    var estimatedServing: String
    var estimatedGrams: Double
    var minSuggestedGrams: Double
    var maxSuggestedGrams: Double
    var baseGrams: Double
    var baseCalories: Int
    var baseProtein: Double
    var baseCarbs: Double
    var baseFat: Double
    var confidence: Double
    var source: FoodLogSource
    var sourcePhrase: String?
    var providerCandidateID: String?
    var providerID: String?
    var providerDataType: String?
    var brandOwner: String?
    var candidateOptions: [ParsedFoodCandidate]

    init(item: ParsedFoodItem) {
        self.id = item.id
        self.name = item.name
        self.detectedQuantity = item.detectedQuantity
        self.estimatedServing = item.estimatedServing
        self.estimatedGrams = item.estimatedGrams
        self.minSuggestedGrams = item.minSuggestedGrams
        self.maxSuggestedGrams = item.maxSuggestedGrams
        self.baseGrams = max(item.estimatedGrams, 1)
        self.baseCalories = item.estimatedCalories
        self.baseProtein = item.estimatedProtein
        self.baseCarbs = item.estimatedCarbs
        self.baseFat = item.estimatedFat
        self.confidence = item.confidence
        self.source = item.source
        self.sourcePhrase = item.sourcePhrase
        self.providerCandidateID = item.providerCandidateID
        self.providerID = item.providerID
        self.providerDataType = item.providerDataType
        self.brandOwner = item.brandOwner
        self.candidateOptions = item.candidateOptions
    }

    mutating func select(_ candidate: ParsedFoodCandidate) {
        name = candidate.name
        detectedQuantity = candidate.detectedQuantity
        estimatedServing = candidate.estimatedServing
        estimatedGrams = candidate.estimatedGrams
        minSuggestedGrams = candidate.minSuggestedGrams
        maxSuggestedGrams = candidate.maxSuggestedGrams
        baseGrams = max(candidate.estimatedGrams, 1)
        baseCalories = candidate.estimatedCalories
        baseProtein = candidate.estimatedProtein
        baseCarbs = candidate.estimatedCarbs
        baseFat = candidate.estimatedFat
        confidence = candidate.confidence
        source = candidate.source
        providerCandidateID = candidate.id
        providerID = candidate.providerID
        providerDataType = candidate.providerDataType
        brandOwner = candidate.brandOwner
    }

    private var scale: Double {
        estimatedGrams / max(baseGrams, 1)
    }

    var scaledCalories: Int {
        Int((Double(baseCalories) * scale).rounded())
    }

    var scaledProtein: Double {
        baseProtein * scale
    }

    var scaledCarbs: Double {
        baseCarbs * scale
    }

    var scaledFat: Double {
        baseFat * scale
    }
}

private extension MealType {
    static var currentDefault: MealType {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<11:
            return MealType.breakfast
        case 11..<16:
            return MealType.lunch
        case 16..<21:
            return MealType.dinner
        default:
            return MealType.snack
        }
    }

    static func inferred(from text: String) -> MealType {
        let lowercased = text.lowercased()
        if lowercased.contains("breakfast") { return .breakfast }
        if lowercased.contains("lunch") { return .lunch }
        if lowercased.contains("dinner") { return .dinner }
        if lowercased.contains("snack") { return .snack }
        return .currentDefault
    }
}
