//
//  InboxView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/1/23.
//

import SwiftUI

struct EmptyLabel: View {
    var body: some View {
        Label {
            Text("")
        } icon: {
            Image(systemName: "")
        }
    }
}

struct InboxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.createdAt, ascending: false)], animation: .default)
    private var conversations: FetchedResults<Conversation>
    
    @State private var showCreateConversationView = false
    @State private var newConversationStore: ConversationStore = ConversationStore()

    let conversationService: ConversationService
    
    @State var newConversationNavLink: NavigationLink<Text, ConversationView>?

    var body: some View {
        NavigationView {
            conversationList
                .navigationBarTitle("Inbox", displayMode: .large)
                .navigationBarItems(trailing: Button(action: {
                    showCreateConversationView = true
                }) {
                    Image(systemName: "plus")
                })
                .sheet(isPresented: $showCreateConversationView) {
                    createConversationView
                }
                .background(newConversationNavLink)
        }
    }
    
    var conversationList: some View {
        List {
            ForEach(conversations) { conversation in
                NavigationLink(
                    destination: conversationView(conversation)) {
                    Text(conversation.title ?? "")
                }
            }
            .onDelete(perform: { indexSet in
                indexSet.map { conversations[$0] }.forEach(viewContext.delete)
                saveContext()
            })
        }
    }
    
    var createConversationView: some View {
        CreateConversationView(viewModel: CreateConversationView.ViewModel(conversationService: conversationService)) { createdConversation in

            newConversationNavLink = NavigationLink("", destination: conversationView(newConversationStore), isActive: self.shouldNavigateToNewConversation)
            
            newConversationStore.conversation = createdConversation
            showCreateConversationView = false
        }
        .environment(\.managedObjectContext, viewContext)
    }
    
    func conversationView(_ conversation: Conversation) -> ConversationView {
        return ConversationView(
            viewModel: ConversationView.ViewModel(
                messageService:  conversationService.messageService(),
                conversation: conversation))
    }
    
    func conversationView(_ conversationStore: ConversationStore) -> ConversationView {
        return ConversationView(
            viewModel: ConversationView.ViewModel(
                messageService:  conversationService.messageService(),
                conversationStore: conversationStore))
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private var addButton: some View {
        Button(action: {
            showCreateConversationView = true
        }) {
            Image(systemName: "plus")
        }
    }
    
    private func deleteConversations(offsets: IndexSet) {
        withAnimation {
            offsets.map { conversations[$0] }.forEach { conversation in
                conversationService.deleteConversation(id: conversation.id!)
                viewContext.delete(conversation)
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    var shouldNavigateToNewConversation: Binding<Bool> {
        Binding<Bool>(
            get: { newConversationStore.conversation != nil },
            set: { active in
                if !active {
                    newConversationStore.conversation = nil
                }
            }
        )
    }
}

struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        InboxView(conversationService: PersistenceController.preview.conversationService)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
