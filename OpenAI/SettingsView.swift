//
//  SettingsView.swift
//  OpenAI
//
//  Created by Reid Chatham on 2/13/23.
//

import SwiftUI
import OpenAISwift

struct SettingsView: View {
    @State private var model: OpenAIModelType = UserDefaults.standard.model
    @State private var maxTokens = UserDefaults.standard.maxTokens
    @State private var temperature = UserDefaults.standard.temperature

    let userDefaults = UserDefaults.standard

    var body: some View {
        Form {
            Picker(selection: $model, label: Text("AI Model")) {
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
                Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 1...1000)
                Slider(value: $temperature, in: 0...1, step: 0.01)
            }

            Button("Save Settings") {
                saveSettings()
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettings()
        }
    }
    
    private func loadSettings() {
        model = userDefaults.model
        maxTokens = userDefaults.maxTokens
        temperature = userDefaults.temperature
    }
    
    private func saveSettings() {
        userDefaults.model = model
        userDefaults.maxTokens = maxTokens
        userDefaults.temperature = temperature
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
