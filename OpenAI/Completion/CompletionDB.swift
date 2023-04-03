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
    
    var persistence: PersistenceController
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func createCompletion(prompt: String, response: String) {
        let context = persistence.container.viewContext
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

            persistence.privateDatabase.save(completionRecord) { _, error in
                if let error = error {
                    print("Failed to save completion to CloudKit: \(error)")
                }
            }
        } catch {
            print("Failed to insert completion: \(error)")
        }
    }

    func deleteCompletion(id: UUID) {
        let context = persistence.container.newBackgroundContext()
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let completion = try context.fetch(request).first
            context.delete(completion!)
            try context.save()
            let completionRecordID = CKRecord.ID(recordName: id.uuidString)
            persistence.privateDatabase.delete(withRecordID: completionRecordID) { _, error in
                if let error = error {
                    print("Failed to delete completion from CloudKit: \(error)")
                }
            }
        } catch {
            print("Failed to delete completion: \(error)")
        }
    }
    
    func updateCompletion(id: UUID, prompt: String, response: String) {
        let context = persistence.container.newBackgroundContext()
        let request: NSFetchRequest<Completion> = Completion.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do {
            let completion = try context.fetch(request).first
            completion?.prompt = prompt
            completion?.response = response
            try context.save()
            let completionRecordID = CKRecord.ID(recordName: id.uuidString)
            persistence.privateDatabase.fetch(withRecordID: completionRecordID) { record, _ in
                if let record = record {
                    record["prompt"] = prompt as CKRecordValue
                    record["response"] = response as CKRecordValue
                    self.persistence.privateDatabase.save(record) { _, error in
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
