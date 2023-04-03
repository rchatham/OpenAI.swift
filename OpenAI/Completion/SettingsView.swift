//
//  SettingsView.swift
//  OpenAI
//
//  Created by Reid Chatham on 2/13/23.
//

import SwiftUI
import OpenAISwift

struct SettingsView: View {
    @StateObject var viewModel: ViewModel

    var body: some View {
        Form {
            Picker(selection: $viewModel.model, label: Text("AI Model")) {
                Section(header: Text("GPT3").bold()) {
                    ForEach(OpenAIModelType.GPT3.cases, id: \.self) { model in
                        Text(model.rawValue).tag(OpenAIModelType.gpt3(model))
                    }
                }

                Section(header: Text("Codex").bold()) {
                    ForEach(OpenAIModelType.Codex.cases, id: \.self) { model in
                        Text(model.rawValue).tag(OpenAIModelType.codex(model))
                    }
                }

                Section(header: Text("Feature").bold()) {
                    ForEach(OpenAIModelType.Feature.cases, id: \.self) { model in
                        Text(model.rawValue).tag(OpenAIModelType.feature(model))
                    }
                }
            }
            .pickerStyle(.menu)

            Section(header: Text("Model Settings")) {
                Stepper("Max Tokens: \(viewModel.maxTokens)", value: $viewModel.maxTokens, in: 1...1000)
                Slider(value: $viewModel.temperature, in: 0...1, step: 0.01)
            }

            Button("Save Settings") {
                viewModel.saveSettings()
            }

            Button("Update API Key") {
                viewModel.enterApiKey = true
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            viewModel.loadSettings()
        }
        .onDisappear {
            viewModel.saveSettings()
        }
        .enterOpenAIKeyAlert(isPresented: $viewModel.enterApiKey,
                             apiKey: $viewModel.apiKey)
    }
}

extension SettingsView {
    @MainActor class ViewModel: ObservableObject {
        @Published var apiKey = ""
        @Published var enterApiKey = false

        @Published var model: OpenAIModelType = UserDefaults.standard.model
        @Published var maxTokens = UserDefaults.standard.maxTokens
        @Published var temperature = UserDefaults.standard.temperature

        let userDefaults = UserDefaults.standard

        func loadSettings() {
            model = userDefaults.model
            maxTokens = userDefaults.maxTokens
            temperature = userDefaults.temperature
        }

        func saveSettings() {
            userDefaults.model = model
            userDefaults.maxTokens = maxTokens
            userDefaults.temperature = temperature
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsView.ViewModel())
    }
}
