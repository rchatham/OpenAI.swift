//
//  CoreData+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import OpenAI

extension Message {
    func toOpenAIMessage() -> OpenAI.Message? { // make throw instead of return nil
        guard let role = role, let contentType = contentType else { return nil }
        var content: OpenAI.Message.Content!
        switch contentType {
        case .null: content = .null
        case .string:
            guard let str = contentText else { return nil }
            content = .string(str)
        case .array:
            guard let str = contentText, let url = imageURL else { return nil }
            content = .array([
                .text(.init(text: str)),
                .image(.init(image_url: .init(url: url, detail: imageDetailString.flatMap{.init(rawValue: $0)} )))
            ])
        }
        let toolCalls = toolCalls.flatMap { $0.count > 0 ? $0 : nil }?.compactMap { ($0 as? ToolCall)?.toOpenAIToolCall() }
        return try? OpenAI.Message(role: role, content: content, name: name, tool_calls: toolCalls, tool_call_id: toolCallId)
    }
}

// Conversion functions for Conversation and Message Core Data models
extension Conversation {
    func toOpenAIMessages() -> [OpenAI.Message] {
        let systemMessage = OpenAI.Message(role: .system, content: self.systemMessage ?? "You are a friendly chatbot designed to be helpful. Always be nice, but if you don't have a clear understanding of what should come next, try to indicate that.")
        guard let messages = self.messages else { return [systemMessage] }
        return [systemMessage] + messages.sorted(by: { ($0 as? Message)?.createdAt ?? Date() < ($1 as? Message)?.createdAt ?? Date() }).compactMap { ($0 as? Message)?.toOpenAIMessage() }
    }
}

extension ToolCall {
    func toOpenAIToolCall() -> OpenAI.Message.ToolCall? {
        guard let id = id, let name = name, let args = arguments else { return nil }
        return OpenAI.Message.ToolCall(index: Int(index), id: id, type: .function, function: .init(name: name, arguments: args))
    }
}


import CoreData

// Conversion functions for OpenAIChatAPI.ChatCompletionRequest and OpenAIChatAPI.ChatCompletionResponse models
extension OpenAI.Message {
    @discardableResult
    func toCoreDataMessage(in context: NSManagedObjectContext, for conversation: Conversation, with uuid: UUID = UUID()) -> Message { // should only be needed to decode server messages
        return Message(context: context).update(contentText: content.text, contentType: contentType, imageURL: imageURL, createdAt: Date(), id: uuid, imageDetail: imageDetail, name: name, role: role, toolCallId: tool_call_id, conversation: conversation, toolCalls: tool_calls?.map({ $0.toCoreDataToolCall(in: context) }))
    }

    private var contentType: ContentType {
        switch content {
        case .null: return .null
        case .string: return .string
        case .array: return .array
        }
    }

    private var imageURL: String? {
        if case .array(let arr) = content { for val in arr { if case .image(let img) = val { return img.image_url.url } } }
        return nil
    }

    private var imageDetail: ImageDetail? {
        if case .array(let arr) = content { for val in arr { if case .image(let img) = val, let detail = img.image_url.detail { switch detail {
        case .auto: return .auto
        case .high: return .high
        case .low: return .low
        } } } }
        return nil
    }
}

extension OpenAI.Message.ToolCall {
    func toCoreDataToolCall(in context: NSManagedObjectContext) -> ToolCall {
        let tool = ToolCall(context: context)
        tool.id = id
        tool.index = Int32(index ?? 0)
        tool.typeString = type?.rawValue
        tool.name = function.name
        tool.arguments = function.arguments
        return tool
    }
}

extension OpenAI.Message.Content {
    func flatMap<U>(_ transform: (Self) throws -> U?) rethrows -> U? {
        return try transform(self)
    }
    var text: String? {
        switch self {
        case .string(let str): return str
        case .array(let arr): for val in arr { if case .text(let txt) = val { return txt.text } }; fallthrough
        default: return nil
        }
    }
}
