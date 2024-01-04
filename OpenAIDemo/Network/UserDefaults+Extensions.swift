//
//  UserDefaults+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 2/13/23.
//

import SwiftUI

extension UserDefaults {
    static var model: Model {
        get { standard.string(forKey: "model").flatMap(Model.init) ?? .gpt35Turbo }
        set { standard.set(newValue.rawValue, forKey: "model") }
    }
    
    static var maxTokens: Int {
        get { standard.integer(forKey: "max_tokens")}
        set { standard.set(newValue, forKey: "max_tokens")}
    }
    
    static var temperature: Double {
        get { return standard.double(forKey: "temperature")}
        set { standard.set(newValue, forKey: "temperature")}
    }
}

// UserDefaults extension for setting and getting the device token
extension UserDefaults {
    private static let deviceTokenKey = "kdeviceToken"

    static var deviceToken: String? {
        get { standard.string(forKey: deviceTokenKey)}
        set { standard.setValue(newValue, forKey: deviceTokenKey)}
    }
}
