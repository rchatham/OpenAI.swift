//
//  MessageView.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/2/23.
//

import SwiftUI

struct MessageView: View {
    @State var message: Message
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            VStack(alignment: .leading) {
                Text(message.content ?? "")
                    .font(.headline)
                    .foregroundColor(message.role == "user" ? .blue : .green)
            }
            if message.role != "user" {
                Spacer()
            }
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: Message.example)
    }
}
