//
//  MessageView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/2/23.
//

import SwiftUI

struct MessageView: View {
    @ObservedObject var message: Message
    @Environment(\.colorScheme) var colorScheme // Get the current color scheme
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            VStack(alignment: .leading) {
                Text(message.content ?? "")
                    .font(.system(size: 18)) // Adjust the font size if necessary
                    .foregroundColor(message.role == "user" ? (colorScheme == .dark ? .white : .black) : .white)
                    .padding(10) // Add padding around the text
                    .background(message.role == "user" ? (colorScheme == .dark ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2)) : Color.blue) // Set background color for message bubble
                    .cornerRadius(10) // Add rounded corners to the message bubble
            }
            if message.role != "user" {
                Spacer()
            }
        }
        .padding(.horizontal, 10) // Add horizontal padding to HStack
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: Message.example)
    }
}
