//
//  MessageService.swift
//  OpenAI
//
//  Created by Reid Chatham on 3/31/23.
//

import Foundation
import OpenAI

class MessageService {
    let networkClient: NetworkClient
    let messageDB: MessageDB
    
    init(networkClient: NetworkClient = NetworkClient(), messageDB: MessageDB) {
        self.networkClient = networkClient
        self.messageDB = messageDB
    }

    var tools: [OpenAI.ChatCompletionRequest.Tool]? {
        return [
            .function(.init(
                name: "getCurrentWeather",
                description: "Get the current weather",
                parameters: .init(
                    properties: [
                        "location": .init(
                            type: "string",
                            description: "The city and state, e.g. San Francisco, CA"),
                        "format": .init(
                            type: "string",
                            enumValues: ["celsius", "fahrenheit"],
                            description: "The temperature unit to use. Infer this from the users location.")
                    ],
                    required: ["location", "format"]))),
            .function(.init(
                name: "getAnswerToUniverse",
                description: "The answer to the universe, life, and everything.",
                parameters: .init()))
        ]
    }
    
    func performMessageCompletionRequest(message: String, for conversation: Conversation, stream: Bool = false) async throws {
        await messageDB.createMessage(for: conversation, content: message)
        do {
            try await getChatCompletion(for: conversation, stream: stream)
        } catch let error as OpenAIError {
            switch error {
            case .jsonParsingFailure(let error): print("json parsing error: \(error.localizedDescription)")
            case .apiError(let error): print("openai api error: \(error.localizedDescription)")
            case .invalidData: print("invalid data")
            case .invalidURL: print("invalid url")
            case .requestFailed(let error): print("request failed with error: \(error?.localizedDescription ?? "no error")")
            case .responseUnsuccessful(statusCode: let code, let error): print("unsuccessful status code: \(code), error: \(error?.localizedDescription ?? "no error")")
            case .streamParsingFailure: print("stream parsing failure")
            }
        } catch {
            print("openai error: " + error.localizedDescription)
        }
    }

    func getChatCompletion(for conversation: Conversation, stream: Bool) async throws {
        var id: UUID!
        var content = ""

        var streamToolInfo: StreamToolInfo?
        let toolChoice = (tools?.isEmpty ?? true) ? nil : OpenAI.ChatCompletionRequest.ToolChoice.auto

        for try await response in try networkClient.streamChatCompletionRequest(messages: conversation.toOpenAIMessages(), stream: stream, tools: tools, toolChoice: toolChoice) {

            // handle non-streamed messages
            if let message = response.choices.first?.message {
                print("message received: \(message)")
                id = await messageDB.createMessage(for: conversation, from: message)

                if let toolCalls = message.tool_calls {
                    await messageDB.updateMessage(id: id, toolCalls: toolCalls)
                    await callTools(toolCalls, for: conversation)
                }
            }

            // handle stream messages
            if let delta = response.choices.first?.delta {
                if id == nil { id = await messageDB.createMessage(for: conversation, content: "", role: delta.role!) }
                if let chunk = delta.content {
                    content += chunk
                    await messageDB.updateMessage(id: id!, content: content)
                }
                if let toolCalls = delta.tool_calls {
                    if streamToolInfo == nil { streamToolInfo = StreamToolInfo(toolCallCount: toolCalls.count) }
                    await streamToolInfo?.update(toolCalls: toolCalls)
                }
            }

            // handle finish reason
            if let finishReason = response.choices.first?.finish_reason {
                switch finishReason {
                case .tool_calls:
                    if let toolCalls = await streamToolInfo?.tools {
                        await messageDB.updateMessage(id: id, toolCalls: toolCalls)
                        await callTools(toolCalls, for: conversation)
                    }
                    do { try await getChatCompletion(for: conversation, stream: stream) }
                    catch { print("error calling chat completion: \(error.localizedDescription)") }
                case .stop:
                    guard !content.isEmpty else { return }
                    print("message received: \(content)")
                case .length, .content_filter: break
                }
            }

        }
    }

    func deleteMessage(id: UUID) {
        messageDB.deleteMessage(id: id)
    }

    func callTools(_ toolCalls: [OpenAI.Message.ToolCall], for conversation: Conversation) async {
        for tool in toolCalls {
            print("utilizing tool: \(tool)")
            guard let toolText = useTool(tool) else { continue }
            await messageDB.createToolMessage(for: conversation, content: toolText, toolCallId: tool.id!, name: tool.function.name!)
        }
    }

    func useTool(_ tool: OpenAI.Message.ToolCall) -> String? {
        print("utilize tools")
        let args = tool.function.arguments.data(using: .utf8).flatMap { try? JSONSerialization.jsonObject(with: $0, options: []) as? [String:String] }

        if tool.function.name == "getCurrentWeather" {
            if let location = args?["location"], let format = args?["format"] {
                return getCurrentWeather(location: location, format: format)
            } else {
                print("failed to decode function parameters")
            }
        }
        if tool.function.name == "getAnswerToUniverse" {
            return "42"
        }
        return nil
    }

    @objc func getCurrentWeather(location: String, format: String) -> String {
        return "27"
    }
}

actor StreamToolInfo {
    var tools: [OpenAI.Message.ToolCall]
    init(toolCallCount: Int) {
        tools = Array(repeating: .init(index: 0, id: "", type: .function, function: .init(name: "", arguments: "")), count: toolCallCount)
    }
    func update(toolCalls: [OpenAI.Message.ToolCall]) {
        for tool in toolCalls {
            guard let index = tool.index else { continue }
            update(index: index, toolCall: tool)
        }
    }
    func update(index: Int, toolCall: OpenAI.Message.ToolCall) {
        tools[index] = OpenAI.Message.ToolCall(
            index: index,
            id: toolCall.id ?? tools[index].id ?? "",
            type: .function,
            function: OpenAI.Message.ToolCall.Function(
                name: toolCall.function.name ?? tools[index].function.name ?? "",
                arguments: tools[index].function.arguments + toolCall.function.arguments))
    }
}
