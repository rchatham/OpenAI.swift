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
        do { try keychain.set(apiKey, key: "apiKey")}
        catch { print("Error saving API key to keychain: \(error)")}
    }

    func getApiKey() -> String? {
        do { return try keychain.getString("apiKey") }
        catch { print("Error fetching API key from keychain: \(error)"); return nil}
    }

    func deleteApiKey() {
        do { try keychain.remove("apiKey")}
        catch { print("Error deleting API key from keychain: \(error)")}
    }
}
