//
//  Persistence.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import CoreData
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()

    #if DEBUG
    static var preview = PersistenceController(inMemory: true)
    #endif

    lazy private(set) var conversationService = ConversationService(conversationDB: ConversationDB(persistence: self))
    lazy private(set) var container: NSPersistentCloudKitContainer = createPersistentCloudKitContainer()

    #if DEBUG
    lazy var testManagedObjectContext: NSManagedObjectContext = createTestManagedObjectContext()
    #endif


    // MARK: - Private
    private let inMemory: Bool
    private let ckContainer = CKContainer(identifier: "iCloud.com.reidchatham.openaidemo")
    lazy private var privateDatabase: CKDatabase = createPrivateDatabase()

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }

    private func createPrivateDatabase() -> CKDatabase {
        ckContainer.requestApplicationPermission(.userDiscoverability) { [weak self] (status, error) in
            guard let self = self else { return }

            if let error = error {
                self.handlePermissionError(error)
                return
            }

            if status == .granted {
                print("User granted permission to access CloudKit")
            }
        }
        return ckContainer.privateCloudDatabase
    }

    private func createPersistentCloudKitContainer() -> NSPersistentCloudKitContainer {
        let container = NSPersistentCloudKitContainer(name: "OpenAI")
        configurePersistentStore(for: container)
        return container
    }

    private func configurePersistentStore(for container: NSPersistentCloudKitContainer) {
        guard let storeDescription = container.persistentStoreDescriptions.first else { return }

        if inMemory {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }

        storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: ckContainer.containerIdentifier!)
        storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            print("Error setting query generation: \(error.localizedDescription)")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Unresolved error \(error), \(error.localizedDescription)")
            }
        }

        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        do {
            try container.persistentStoreCoordinator.addPersistentStore(ofType: inMemory ? NSInMemoryStoreType : NSSQLiteStoreType, configurationName: nil, at: storeDescription.url, options: options)
        } catch {
            print("Error adding persistent store: \(error.localizedDescription)")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private func handlePermissionError(_ error: Error) {
        // Implement appropriate error handling
        print("Error requesting application permission: \(error.localizedDescription)")
    }

    #if DEBUG
    private func createTestManagedObjectContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.container.persistentStoreCoordinator
        return context
    }
    #endif
}
