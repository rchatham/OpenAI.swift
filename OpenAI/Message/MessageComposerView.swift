//
//  MessageComposerView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/2/23.
//

import SwiftUI
import CoreData

// MessageComposerView
struct MessageComposerView: View {
    @ObservedObject var viewModel: ViewModel
    @FocusState private var promptTextFieldIsActive
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Enter your prompt", text: $viewModel.input)
                .textFieldStyle(.automatic)
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10))
                .foregroundColor(.primary)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .focused($promptTextFieldIsActive)
                .submitLabel(.done)
                .onSubmit {
                    submitButtonTapped()
                }
            Button(action: submitButtonTapped) {
                Text("Submit")
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 20))
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    func submitButtonTapped() {
        onSubmit()
    }
}

extension MessageComposerView {
    // MessageComposerViewModel
    class ViewModel: ObservableObject {
        @Published var input: String = ""
        
        private let messageService: MessageService
        private let conversation: Conversation
        
        init(messageService: MessageService, conversation: Conversation) {
            self.messageService = messageService
            self.conversation = conversation
        }
        
        func sendMessage() async {
            guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            // Send the message completion request
            do {
                try await messageService.sendMessageCompletionRequest(message: input, for: conversation)
            } catch {
                print("Error sending message completion request: \(error)")
            }
            
            // Clear the input field
            input = ""
        }
    }
}

struct MessageComposerView_Previews: PreviewProvider {
    static var previews: some View {
        MessageComposerView(viewModel: MessageComposerView.ViewModel(messageService: MessageService(messageDB: MessageDB(persistence: PersistenceController.preview)), conversation: Conversation.example), onSubmit: {})
    }
}
