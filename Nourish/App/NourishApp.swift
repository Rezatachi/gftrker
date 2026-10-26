import Foundation
import SwiftData
import SwiftUI

@main
struct NourishApp: App {
    private static let modelSchema = Schema([
        Meal.self,
        FoodItem.self,
        MealTemplate.self,
        TemplateFoodItem.self,
        WaterEntry.self,
        FoodCorrection.self,
        AppSettings.self
    ])

    private static let storeDirectoryURL: URL = {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directoryURL = baseURL.appendingPathComponent("Nourish", isDirectory: true)
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }()

    private static let storeURL = storeDirectoryURL.appendingPathComponent("Nourish.store")

    private static let bootstrap = makeModelContainer()
    private let sharedModelContainer = bootstrap.container

    var body: some Scene {
        WindowGroup {
            AppRootView(storageWarning: Self.bootstrap.warning)
        }
        .modelContainer(sharedModelContainer)
    }

    private static func makeModelContainer() -> ModelContainerBootstrap {
        let configuration = ModelConfiguration(
            schema: modelSchema,
            url: storeURL,
            cloudKitDatabase: .none
        )

        do {
            return ModelContainerBootstrap(
                container: try ModelContainer(for: modelSchema, configurations: [configuration]),
                warning: nil
            )
        } catch {
            do {
                let fallback = ModelConfiguration(
                    schema: modelSchema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                return ModelContainerBootstrap(
                    container: try ModelContainer(for: modelSchema, configurations: [fallback]),
                    warning: "Nourish could not open its saved data. This session will not be saved. Your existing data was not deleted."
                )
            } catch {
                fatalError("Unable to initialize Nourish storage: \(error)")
            }
        }
    }
}

private struct ModelContainerBootstrap {
    let container: ModelContainer
    let warning: String?
}

private struct AppRootView: View {
    let storageWarning: String?
    @State private var showingStorageWarning: Bool

    init(storageWarning: String?) {
        self.storageWarning = storageWarning
        _showingStorageWarning = State(initialValue: storageWarning != nil)
    }

    var body: some View {
        RootTabView()
            .preferredColorScheme(.light)
            .alert("Storage unavailable", isPresented: $showingStorageWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(storageWarning ?? "")
            }
    }
}
