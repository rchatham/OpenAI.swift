//
//  SettingsView.swift
//  OpenAI
//
//  Created by Reid Chatham on 2/13/23.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: ViewModel

    var body: some View {
        Form {
            Picker(selection: $viewModel.model, label: Text("AI Model")) {
                ForEach(Model.cases, id: \.self) { model in
                    Text(model.rawValue).tag(model)
                }
            }
            .pickerStyle(.menu)

            Section(header: Text("Model Settings")) {
                Stepper("Max Tokens: \(viewModel.maxTokens)", value: $viewModel.maxTokens, in: 1...1000)
                HStack {
                    Text("Temperature:")
                    Slider(value: $viewModel.temperature, in: 0...1, step: 0.01)
                }
            }
            if let deviceToken = $viewModel.deviceToken.wrappedValue {
                Text("Device Token: " + deviceToken)
            } else {
                Button("Register for notifications") {
                    NotificationManager.shared.requestPushNotificationPermission()
                }
            }
            Button("Save Settings") { viewModel.saveSettings()}
            Button("Update API Key") { viewModel.enterApiKey = true}
        }
        .navigationTitle("Settings")
        .onAppear { viewModel.loadSettings()}
        .onDisappear { viewModel.saveSettings()}
        .enterOpenAIKeyAlert(isPresented: $viewModel.enterApiKey, apiKey: $viewModel.apiKey)
    }
}

extension SettingsView {
    @MainActor class ViewModel: ObservableObject {
        @Published var apiKey = ""
        @Published var enterApiKey = false

        @Published var model: Model = UserDefaults.model
        @Published var maxTokens = UserDefaults.maxTokens
        @Published var temperature = UserDefaults.temperature
        @Published var deviceToken = UserDefaults.deviceToken

        func loadSettings() {
            model = UserDefaults.model
            maxTokens = UserDefaults.maxTokens
            temperature = UserDefaults.temperature
        }

        func saveSettings() {
            UserDefaults.model = model
            UserDefaults.maxTokens = maxTokens
            UserDefaults.temperature = temperature
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsView.ViewModel())
    }
}
