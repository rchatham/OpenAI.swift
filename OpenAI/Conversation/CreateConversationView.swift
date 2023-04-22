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
            TextField("Enter system message", text: $viewModel.systemMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
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
        viewModel.createConversationTapped  { conversation in
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

        func createConversationTapped(completion: @escaping (Conversation) -> Void) {
            guard !systemMessage.isEmpty else {
                self.showAlert = true
                self.errorMessage = "System message cannot be empty."
                return
            }
            isGeneratingTitle = true
            do {
                try conversationService.getTitleForConversation(withSystemMessage: systemMessage) { result in
                    switch result {
                    case .success(let response):
                        if let title = response.choices.first?.message?.content {
                            let conversation = self.conversationService.createConversation(title: title, systemMessage: self.systemMessage)
                            DispatchQueue.main.async {
                                completion(conversation)
                            }
                        } else {
                            self.errorMessage = "Failed to generate a title."
                            self.showAlert = true
                        }
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showAlert = true
                    }
                    self.isGeneratingTitle = false
                }
            } catch {
                self.errorMessage = "Failed to send a chat completion request."
                self.showAlert = true
                self.isGeneratingTitle = false
                
                // Show pop-up to enter API key
                self.enterApiKey = true
            }
        }

    }
}
