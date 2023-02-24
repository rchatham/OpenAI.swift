//
//  KeychainService.swift
//  OpenAI
//
//  Created by Reid Chatham on 1/20/23.
//

import Foundation
import KeychainAccess

class KeychainService {
    let keychain = Keychain(service: "com.reidchatham.OpenAI")

    func saveApiKey(apiKey: String) {
        do {
            try keychain.set(apiKey, key: "apiKey")
        } catch let error {
            print("Error saving API key to keychain: \(error)")
        }
    }

    func getApiKey() -> String? {
        do {
            let apiKey = try keychain.getString("apiKey")
            return apiKey
        } catch let error {
            print("Error fetching API key from keychain: \(error)")
            return nil
        }
    }

    func deleteApiKey() {
        do {
            try keychain.remove("apiKey")
        } catch let error {
            print("Error deleting API key from keychain: \(error)")
        }
    }
}
