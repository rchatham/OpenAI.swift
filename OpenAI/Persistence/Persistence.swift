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
        let viewContext = result.container.viewContext
        for int in 0..<20 {
            let completion = Completion(context: viewContext)
            completion.createdAt = Date()
            completion.id = UUID()
            completion.prompt = "prompt \(int)"
            completion.response = "response \(int)"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    lazy private(set) var completionService: CompletionService = CompletionService(networkClient: NetworkClient(), completionDB: CompletionDB(persistence: self))
    lazy private(set) var  conversationService: ConversationService = ConversationService(conversationDB: ConversationDB(persistence: self))
    
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
    
    // MARK: - Private
    lazy private(set) var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "OpenAI")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    let ckContainer = CKContainer(identifier: "iCloud.com.reidchatham.openai")
    lazy var privateDatabase: CKDatabase = {
        ckContainer.requestApplicationPermission(.userDiscoverability) { (status, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            if status == .granted {
                print("User granted permission to access CloudKit")
            }
        }
        return ckContainer.privateCloudDatabase
    }()

    private let inMemory: Bool
}
