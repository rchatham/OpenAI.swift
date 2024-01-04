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
    var isToolCall: Bool { role == .tool }
    var role: Role? {
        get { roleString.flatMap{Role(rawValue: $0)}}
        set { newValue.flatMap{ roleString = $0.rawValue }}
    }
    var contentType: ContentType? {
        get { contentTypeString.flatMap{ContentType(rawValue: $0)}}
        set { newValue.flatMap{ contentTypeString = $0.rawValue }}
    }
    var imageDetail: ImageDetail? {
        get { imageDetailString.flatMap{ImageDetail(rawValue: $0)}}
        set { newValue.flatMap{ imageDetailString = $0.rawValue }}
    }
}

extension Message {
    @discardableResult
    func update(contentText: String? = nil, contentType: ContentType? = nil, imageURL: String? = nil, createdAt: Date? = nil, id: UUID? = nil, imageDetail: ImageDetail? = nil, name: String? = nil, role: Role? = nil, toolCallId: String? = nil, conversation: Conversation? = nil, toolCalls: [ToolCall]? = nil) -> Message {
        self.contentText ?= contentText
        self.contentType ?= contentType
        self.imageURL ?= imageURL
        self.imageDetail ?= imageDetail
        self.name ?= name
        self.role ?= role
        self.id ?= id
        self.createdAt ?= createdAt
        self.toolCallId ?= toolCallId
        self.conversation ?= conversation
        self.toolCalls ?= toolCalls.flatMap { NSSet(array: $0) }
        toolCalls?.forEach {self.addToToolCalls($0) }
        conversation?.addToMessages(self)
        return self
    }
}

enum ContentType: String {
    case null, string, array
}

enum ImageDetail: String {
    case auto, high, low
}
