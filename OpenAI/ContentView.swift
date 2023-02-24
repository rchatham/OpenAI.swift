//
//  ContentView.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import SwiftUI
import CoreData
import Introspect

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Completion.createdAt, ascending: false)],
        animation: .default)
    var completions: FetchedResults<Completion>
    @StateObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            VStack {
                completionList
                messageComposerView
            }
            .navigationTitle("OpenAI")
            .toolbar {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
    }
    
    var completionList: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(completions, id: \.self) { completion in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(completion.prompt ?? "")
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                                    .padding(8)
                            }
                            .background(.secondary)
                            HStack {
                                Text(completion.response ?? "")
                                    .font(.subheadline)
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                                    .padding(8)
                            }
                        }
                        if completion != completions.last {
                            Divider()
                        }
                    }
                    .onDelete(perform: delete)
                }
                .padding(16)
            }
            .onAppear {
                scrollToBottom(scrollProxy: scrollProxy)
            }
            .onChange(of: completions.last) { _ in
                scrollToBottom(scrollProxy: scrollProxy)
            }
        }
    }
    
    var messageComposerView: some View {
        HStack {
            TextField("Enter your prompt", text: $viewModel.input)
                .textFieldStyle(.automatic)
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 10))
                .foregroundColor(.primary)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
            Button(action: submitButtonTapped) {
                Text("Submit")
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 20))
                    .foregroundColor(.accentColor)
            }
            .invalidInputAlert(isPresented: $viewModel.showingAlert)
            .enterOpenAIKeyAlert(
                isPresented: $viewModel.enterApiKey,
                apiKey: $viewModel.apiKey,
                updateApiKey: viewModel.updateApiKey)
        }
    }
    
    
    func scrollToBottom(scrollProxy proxy: ScrollViewProxy) {
        guard let last = completions.last else { return }
        withAnimation {
            proxy.scrollTo(last)
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            guard let completionId = completions[index].id else {
                fatalError("Completion id should never be nil")
            }
            viewModel.delete(id: completionId)
        }
    }
    
    func submitButtonTapped() {
        Task {
            do {
                try await viewModel.submitButtonTapped {}
            } catch {
                // Show pop-up to enter username
                viewModel.enterApiKey = true
            }
        }
    }
}

extension View {
    func invalidInputAlert(isPresented: Binding<Bool>) -> some View {
        return alert(Text("Invalid Input"), isPresented: isPresented, actions: {
            Button("OK", role: .cancel, action: {})
        }, message: { Text("Please enter a valid prompt") })
    }
    
    func enterOpenAIKeyAlert(isPresented: Binding<Bool>, apiKey: Binding<String>, updateApiKey: @escaping () -> Void) -> some View {
        return alert("Enter OpenAI API Key", isPresented: isPresented, actions: {
            TextField("OpenAI API Key", text: apiKey)

            Button("Save", action: updateApiKey)
            Button("Cancel", role: .cancel, action: {})
        }, message: { Text("Please enter your OpenAI API key.") })
    }
}

extension ContentView {
    @MainActor class ViewModel: ObservableObject {
        @Published var apiKey = ""
        @Published var input = ""
        @Published var showingAlert = false
        @Published var enterApiKey = false
        private let completionService: CompletionService
        
        init(completionService: CompletionService) {
            self.completionService = completionService
        }
        
        func submitButtonTapped(completion: @escaping () -> Void) async throws {
            guard !input.isEmpty else {
                showingAlert = true
                return
            }
            try await completionService.getCompletion(for: input, completion: completion)
            input = ""
        }
        
        func delete(id: UUID) {
            completionService.deleteCompletion(id: id)
        }
        
        func updateApiKey() {
            completionService.updateApiKey(apiKey)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentView.ViewModel(completionService: PersistenceController.preview.completionService)).environment(\.managedObjectContext, PersistenceController.preview.completionService.completionDB.container.viewContext)
    }
}
