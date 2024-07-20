//
//  InboxView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/1/23.
//

import SwiftUI

struct InboxView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Conversation.createdAt, ascending: false)], animation: .default)
    private var conversations: FetchedResults<Conversation>

    @State private var showCreateConversationView = false
    @State private var newConversationStore: ConversationStore = ConversationStore()

    let conversationService: ConversationService

    @State var newConversationNavLink: NavigationLink<Text, ConversationView>?

#if canImport(AppKit)
    @State var navVisibility: NavigationSplitViewVisibility = .automatic
#endif

    var body: some View {
#if canImport(UIKit)
        NavigationView {
            conversationList
                .navigationBarTitle("Inbox", displayMode: .large)
                .navigationBarItems(trailing: addButton)
                .sheet(isPresented: $showCreateConversationView) { createConversationView }
                .background(newConversationNavLink)
        }
        .onAppear { NotificationManager.shared.requestPushNotificationPermission()}
#elseif canImport(AppKit)
        NavigationSplitView(columnVisibility: $navVisibility) {
            conversationList
                .navigationTitle("Inbox")
                .toolbar { addButton }
                .sheet(isPresented: $showCreateConversationView) { createConversationView }
        } detail: { NavigationStack { conversationView(newConversationStore)}}
#endif
    }

    var conversationList: some View {
        List {
            ForEach(conversations) { conversation in
                NavigationLink(destination: conversationView(conversation)) { Text(conversation.title ?? "") }}
                .onDelete(perform: { $0.map { conversations[$0] }.forEach(viewContext.delete); saveContext()})
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
        do { try viewContext.save()}
        catch { fatalError("Unresolved error \(error), \(error.localizedDescription)")}
    }

    private var addButton: some View {
        Button(action: { showCreateConversationView = true }, label: { Image(systemName: "plus") })
    }

    private func deleteConversations(offsets: IndexSet) {
        withAnimation {
            offsets.map { conversations[$0] }.forEach { conversation in
                conversationService.deleteConversation(id: conversation.id!)
                viewContext.delete(conversation)
            }

            do { try viewContext.save()}
            catch { fatalError("Unresolved error \(error), \(error.localizedDescription)")}
        }
    }

    var shouldNavigateToNewConversation: Binding<Bool> {
        Binding<Bool>(
            get: { newConversationStore.conversation != nil },
            set: { if !$0 { newConversationStore.conversation = nil }}
        )
    }
}

struct InboxView_Previews: PreviewProvider {
    static var previews: some View {
        InboxView(conversationService: PersistenceController.preview.conversationService)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
