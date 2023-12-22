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

    static var preview: PersistenceController = {
        var result = PersistenceController(inMemory: true)
//        let viewContext = result.container.viewContext
//        for int in 0..<20 {
//            let completion = Completion(context: viewContext)
//            completion.createdAt = Date()
//            completion.id = UUID()
//            completion.prompt = "prompt \(int)"
//            completion.response = "response \(int)"
//        }
//        do { try viewContext.save()}
//        catch { print("Unresolved error \(error), \(error.localizedDescription)")}
        return result
    }()

    lazy private(set) var  conversationService: ConversationService = ConversationService(conversationDB: ConversationDB(persistence: self))

    // MARK: - Private
    private let ckContainer = CKContainer(identifier: "iCloud.com.reidchatham.openai")
    private lazy var privateDatabase: CKDatabase = {
        ckContainer.requestApplicationPermission(.userDiscoverability) { (status, error) in
            if let error = error { return print("Error: \(error.localizedDescription)")}
            if status == .granted { print("User granted permission to access CloudKit")}
        }
        return ckContainer.privateCloudDatabase
    }()
    private(set) lazy var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "OpenAI")
        if inMemory { container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")}

        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: ckContainer.containerIdentifier!)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        do { try container.viewContext.setQueryGenerationFrom(.current) }
        catch { print(error.localizedDescription) }

        container.loadPersistentStores { $1.map { print("Unresolved error \($0), \($0.localizedDescription)") } }

        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        do { try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeDescription?.url, options: options) }
        catch { print(error.localizedDescription) }

        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    private let inMemory: Bool

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
}
