//
//  View+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 4/1/23.
//

import SwiftUI

extension View {
    func invalidInputAlert(isPresented: Binding<Bool>) -> some View {
        return alert(Text("Invalid Input"), isPresented: isPresented, actions: {
            Button("OK", role: .cancel, action: {})
        }, message: { Text("Please enter a valid prompt") })
    }

    func enterOpenAIKeyAlert(isPresented: Binding<Bool>, apiKey: Binding<String>) -> some View {
        return alert("Enter OpenAI API Key", isPresented: isPresented, actions: {
            TextField("OpenAI API Key", text: apiKey)
            Button("Save", action: {
                do { try NetworkClient.shared.updateApiKey(apiKey.wrappedValue)}
                catch { if case .emptyApiKey = error as? NetworkClient.NetworkError { print("Empty api key") }}
            })
            Button("Cancel", role: .cancel, action: {})
        }, message: { Text("Please enter your OpenAI API key.") })
    }
}

struct EmptyLabel: View {
    var body: some View {
        Label(title: { Text("") }, icon: {Image(systemName: "")})
    }
}
