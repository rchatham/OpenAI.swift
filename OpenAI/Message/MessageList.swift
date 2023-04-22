//
//  MessageList.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/2/23.
//

import SwiftUI

struct MessageList: View {
    @Environment(\.managedObjectContext) private var viewContext
    let conversation: Conversation
    @FetchRequest private var messages: FetchedResults<Message>

    init(conversation: Conversation) {
        self.conversation = conversation
        _messages = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Message.createdAt, ascending: true)],
            predicate: NSPredicate(format: "conversation.id == %@", conversation.id! as CVarArg),
            animation: .default)
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(messages, id: \.self) { message in
                        MessageView(message: message)
                    }
                    // ... (rest of the code)
                }
                .padding(16)
            }
            .onAppear {
                scrollToBottom(scrollProxy: scrollProxy)
                #if os(iOS)
                    NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { notification in
                        scrollToBottom(scrollProxy: scrollProxy)
                    }
                #endif
            }
            .onDisappear {
                #if os(iOS)
                    NotificationCenter.default.removeObserver(self)
                #endif
            }
            .onChange(of: messages.last?.content) { _ in
                scrollToBottom(scrollProxy: scrollProxy)
            }
        }
    }

    func scrollToBottom(scrollProxy proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        withAnimation {
            proxy.scrollTo(last, anchor: UnitPoint(x: UnitPoint.bottom.x, y: 0.95))
        }
    }
}

struct MessageList_Previews: PreviewProvider {
    static var previews: some View {
        MessageList(conversation: Conversation.example)
    }
}
