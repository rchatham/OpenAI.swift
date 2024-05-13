//
//  Persistence.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    #if DEBUG
    static var preview = PersistenceController(inMemory: true)
    #endif

    lazy private(set) var conversationService = ConversationService(conversationDB: ConversationDB(persistence: self))
    lazy private(set) var container: NSPersistentContainer = createPersistentContainer()

    #if DEBUG
    lazy var testManagedObjectContext: NSManagedObjectContext = createTestManagedObjectContext()
    #endif

    // MARK: - Private
    private let inMemory: Bool

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        self.container = createPersistentContainer()
    }

    private func createPersistentContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "OpenAI")
        configurePersistentStore(for: container)
        return container
    }

    private func configurePersistentStore(for container: NSPersistentContainer) {
        guard let storeDescription = container.persistentStoreDescriptions.first else { return }

        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }

        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Unresolved error \(error), \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        if !inMemory {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            do {
                try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeDescription.url, options: options)
            } catch {
                print("Error adding persistent store: \(error.localizedDescription)")
            }
        }
    }

    #if DEBUG
    private func createTestManagedObjectContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.container.persistentStoreCoordinator
        return context
    }
    #endif
}
