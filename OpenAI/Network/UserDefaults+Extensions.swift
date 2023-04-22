//
//  UserDefaults+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 2/13/23.
//

import SwiftUI

extension UserDefaults {
    var model: Model {
        get {
            if let modelName = string(forKey: "model"), let model = Model(rawValue: modelName) {
                return model
            } else {
                return .gpt35Turbo
            }
        }
        set {
            set(newValue.rawValue, forKey: "model")
        }
    }
    
    var maxTokens: Int {
        get {
            return integer(forKey: "max_tokens")
        }
        set {
            set(newValue, forKey: "max_tokens")
        }
    }
    
    var temperature: Double {
        get {
            return double(forKey: "temperature")
        }
        set {
            set(newValue, forKey: "temperature")
        }
    }
}
