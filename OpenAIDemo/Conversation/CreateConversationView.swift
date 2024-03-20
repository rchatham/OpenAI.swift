//
//  CreateConversationView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/1/23.
//

import SwiftUI

struct CreateConversationView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ViewModel
    let onConversationCreated: (Conversation) -> Void

    var body: some View {
        VStack {
            TextField("Enter system message", text: $viewModel.systemMessage, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.leading)
                .lineLimit(20, reservesSpace: true)
                .padding()

            Button(action: {
                createConversationTapped()
            }, label: {
                Text("Create Conversation")
                    .foregroundColor(.white)
                    .padding()
                    .background(viewModel.isGeneratingTitle ? Color.gray : Color.blue)
                    .cornerRadius(8)
            })
            .disabled(viewModel.isGeneratingTitle)
            .alert(isPresented: $viewModel.showAlert, content: {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            })

            Spacer()
        }
        .padding()
        .navigationTitle("New Conversation")
        .enterOpenAIKeyAlert(
            isPresented: $viewModel.enterApiKey,
            apiKey: $viewModel.apiKey)
    }
    
    func createConversationTapped() {
        Task() {
            guard let conversation = await viewModel.createConversationTapped() else { return }
            onConversationCreated(conversation)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

extension CreateConversationView {
    @MainActor class ViewModel: ObservableObject {
        @Published var systemMessage: String = ""
        @Published var isGeneratingTitle: Bool = false
        @Published var showAlert: Bool = false
        @Published var errorMessage: String = ""
        @Published var enterApiKey: Bool = false
        @Published var apiKey: String = ""
        
        let conversationService: ConversationService
        
        init(conversationService: ConversationService) {
            self.conversationService = conversationService
        }

        func createConversationTapped() async -> Conversation? {
            guard !systemMessage.isEmpty else {
                self.errorMessage = "System message cannot be empty."
                self.showAlert = true
                return nil
            }
            isGeneratingTitle = true
            do {
                return try await conversationService.getTitleForConversation(withSystemMessage: systemMessage)
            } catch {
                self.errorMessage = error.localizedDescription
                self.isGeneratingTitle = false
                // Show pop-up to enter API key
                if case NetworkClient.NetworkError.missingApiKey = error {
                    self.enterApiKey = true
                } else {
                    self.showAlert = true
                }
            }
            return nil
        }
    }
}
