//
//  OpenAIApp.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import SwiftUI

@main
struct OpenAIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            InboxView(conversationService: persistenceController.conversationService)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
