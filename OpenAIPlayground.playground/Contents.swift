import UIKit
import OpenAI

var greeting = "Hello, playground"

let openAI = OpenAI(apiKey: "")

let chatRequest = OpenAI.ChatCompletionRequest(
    model: .gpt4,
    messages: [
        .init(role: .system, content: "You are a weather bot, if the user asks you for the weather use the getCurrentWeather function to get the weather. You MUST ask the user for the location they would like the weather for if you do not already know it. Assume Fahrenheit unless the user specifies. When you call getCurrentWeather ONLY OUTPUT JSON."),
        .init(role: .user, content: "What is the weather?")
    ],
    temperature: nil,
    top_p: nil,
    n: nil,
    stream: false,
    stop: nil,
    max_tokens: nil,
    presence_penalty: nil,
    frequency_penalty: nil,
    logit_bias: nil,
    user: nil,
    response_type: nil,
    seed: nil,
    tools: [
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
                required: ["location", "format"])))
    ],
    tool_choice: .auto)

openAI.perform(request: chatRequest) { result in
    switch result {
    case .success(let response): print(response.choices[0].message?.content.description ?? response.choices[0].delta?.content ?? "no text")
    case .failure(let err): print(err.localizedDescription)
    }
}

let response = try await openAI.perform(request: chatRequest)
print(response.choices[0].message?.content.description ?? "no text")

for try await chunk in openAI.stream(request: chatRequest) {
    print(chunk.choices[0].delta?.content ?? response.choices[0].message?.content.description ?? "no text")
}
