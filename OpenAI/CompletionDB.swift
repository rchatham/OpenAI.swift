//
//  CompletionDB.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/21/23.
//

import Foundation
import CoreData
import CloudKit

class CompletionDB {
//    let container: NSPersistentContainer
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
    
    
    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
    
//    init(inMemory: Bool = false) {
//        container = NSPersistentContainer(name: "OpenAI")
//        if inMemory {
//            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
//        }
//
//
//        container.loadPersistentStores { _, error in
//            if let error = error {
//                fatalError("Failed to load persistent stores: \(error)")
//            }
//        }
//
//        privateDatabase = CKContainer.default().privateCloudDatabase
//    }
    
//    init(inMemory: Bool = false) {
//        container = NSPersistentCloudKitContainer(name: "OpenAI")
//        if inMemory {
//            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
//        }
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        })
//        container.viewContext.automaticallyMergesChangesFromParent = true
//        privateDatabase = CKContainer.default().privateCloudDatabase
//    }

    func createCompletion(prompt: String, response: String) { // -> Completion {
        let context = container.viewContext
        let completion = Completion(context: context)
        completion.id = UUID()
        let createdAt = Date()
        completion.createdAt = createdAt
        completion.prompt = prompt
        completion.response = response
        
        do {
            try context.save()
            let completionRecord = CKRecord(recordType: "Completion", recordID: CKRecord.ID(recordName: completion.id?.uuidString ?? ""))
            completionRecord["prompt"] = prompt as CKRecordValue
            completionRecord["response"] = response as CKRecordValue
            completionRecord["createdAt"] = createdAt as CKRecordValue

            privateDatabase.save(completionRecord) { _, error in
                if let error = error {
                    print("Failed to save completion to CloudKit: \(error)")
                }
            }
        } catch {
            print("Failed to insert completion: \(error)")
        }
//        return completion
    }

//    func fetchCompletions(completion: @escaping (_ completions: [Completion]) -> ()) {
//        let context = container.newBackgroundContext()
//        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
//        do {
//            let completions = try context.fetch(request)
//            completion(completions)
//        } catch {
//            print("Failed to fetch completions: \(error)")
//            completion([])
//        }
//    }

    func deleteCompletion(id: UUID) {
        let context = container.newBackgroundContext()
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let completion = try context.fetch(request).first
            context.delete(completion!)
            try context.save()
            let completionRecordID = CKRecord.ID(recordName: id.uuidString)
            privateDatabase.delete(withRecordID: completionRecordID) { _, error in
                if let error = error {
                    print("Failed to delete completion from CloudKit: \(error)")
                }
            }
        } catch {
            print("Failed to delete completion: \(error)")
        }
    }
    
    func updateCompletion(id: UUID, prompt: String, response: String) {
        let context = container.newBackgroundContext()
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let completion = try context.fetch(request).first
            completion?.prompt = prompt
            completion?.response = response
            try context.save()
            let completionRecordID = CKRecord.ID(recordName: id.uuidString)
            privateDatabase.fetch(withRecordID: completionRecordID) { record, _ in
                if let record = record {
                    record["prompt"] = prompt as CKRecordValue
                    record["response"] = response as CKRecordValue
                    self.privateDatabase.save(record) { _, error in
                        if let error = error {
                            print("Failed to update completion in CloudKit: \(error)")
                        }
                    }
                }
            }
        } catch {
            print("Failed to update completion: \(error)")
        }
    }
}
