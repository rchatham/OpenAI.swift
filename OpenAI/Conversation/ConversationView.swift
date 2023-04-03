//
//  ConversationView.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import SwiftUI
import CoreData

class ConversationStore: ObservableObject {
    @Published var conversation: Conversation?
}

struct ConversationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var viewModel: ViewModel
    @FocusState private var promptTextFieldIsActive: Bool

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            messageList
            messageComposerView
                .invalidInputAlert(isPresented: $viewModel.showAlert)
                .enterOpenAIKeyAlert(
                    isPresented: $viewModel.enterApiKey,
                    apiKey: $viewModel.apiKey)
        }
        .navigationTitle("ChatGPT")
        .toolbar {
            NavigationLink(destination: viewModel.settingsView()) {
                Image(systemName: "gear")
            }
        }
    }

    @ViewBuilder
    var messageList: some View {
        if let conversation = viewModel.conversationStore.conversation {
            MessageList(conversation: conversation)
        } else {
            Spacer()
            Text("Error loading conversation")
            Spacer()
        }
    }

    @ViewBuilder
    var messageComposerView: some View {
        if let messageComposerViewModel = viewModel.messageComposerViewModel() {
            MessageComposerView(viewModel: messageComposerViewModel)
        } else {
            Spacer()
        }
    }
}

extension ConversationView {
    @MainActor class ViewModel: ObservableObject {
        
        @ObservedObject var conversationStore: ConversationStore
        
        @Published var apiKey = ""
        @Published var input = ""
        @Published var showAlert = false
        @Published var enterApiKey = false
        let messageService: MessageService
        
        init(messageService: MessageService, conversation: Conversation? = nil) {
            self.messageService = messageService
            conversationStore = ConversationStore()
            conversationStore.conversation = conversation
        }
        
        init(messageService: MessageService, conversationStore: ConversationStore) {
            self.messageService = messageService
            self.conversationStore = conversationStore
        }
        
        func submitButtonTapped() throws {
            guard let conversation = conversationStore.conversation, !input.isEmpty else {
                showAlert = true
                return
            }
            try messageService.sendMessageCompletionRequest(message: input, for: conversation)
            input = ""
        }
        
        func delete(id: UUID) {
            messageService.deleteMessage(id: id)
        }

        func settingsView() -> some View {
            return SettingsView(viewModel: SettingsView.ViewModel())
        }
        
        func messageComposerViewModel() -> MessageComposerView.ViewModel? {
            guard let conversation = conversationStore.conversation else { return nil }
            return MessageComposerView.ViewModel(messageService: messageService, conversation: conversation)
        }
    }
}

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationView(viewModel: ConversationView.ViewModel(messageService: PersistenceController.preview.conversationService.messageService(), conversation: Conversation.example)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
