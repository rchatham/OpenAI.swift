//
//  Message+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/30/23.
//

import Foundation

extension Message {
    var isUser: Bool { role == .user }
    var isAssistant: Bool { role == .assistant }
    var isSystem: Bool { role == .system }
    var role: Role? {
        get { roleString.flatMap{Role(rawValue: $0)}}
        set { newValue.flatMap{ roleString = $0.rawValue }}
    }
}
