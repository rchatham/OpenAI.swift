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
        do { try viewContext.save()}
        catch { print("Unresolved error \(error), \(error.localizedDescription)")}
        return result
    }()

    lazy private(set) var  conversationService: ConversationService = ConversationService(conversationDB: ConversationDB(persistence: self))
    
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
    
    // MARK: - Private
    lazy private(set) var container: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "OpenAI")
        if inMemory { container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")}
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error { print("Unresolved error \(error), \(error.localizedDescription)")}
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    let ckContainer = CKContainer(identifier: "iCloud.com.reidchatham.openai")
    lazy var privateDatabase: CKDatabase = {
        ckContainer.requestApplicationPermission(.userDiscoverability) { (status, error) in
            if let error = error { return print("Error: \(error.localizedDescription)")}
            if status == .granted { print("User granted permission to access CloudKit")}
        }
        return ckContainer.privateCloudDatabase
    }()

    private let inMemory: Bool
}
