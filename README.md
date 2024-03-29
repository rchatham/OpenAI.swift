# OpenAI.swift

The smallest OpenAI API implementation written in Swift. 

This package provides a simple Swift interface for interacting with OpenAI's Chat API, with full support for functions.

## Features

- Support for various OpenAI models including GPT-3.5 and GPT-4.
- Handling both regular and streaming API requests.
- Built-in error handling and response parsing.
- Support for functions.

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5+

## Installation

Include the following dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/rchatham/OpenAI.swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## Usage

### Initializing the Client

```swift
let openAI = OpenAI(apiKey: "your-api-key")
```

### Performing a Chat Completion Request

```swift
let chatRequest = OpenAI.ChatCompletionRequest(
    model: .gpt4,
    messages: [ /* Your messages here */ ],
    /* Other optional parameters */
)

openAI.perform(request: chatRequest) { result in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let err):
        print(err.localizedDescription)
    }
}
```

### Implementation Steps for Using Functions

#### Step 1: Define the Function Schema

Before using a function in a chat completion request, define its schema. This includes the function name, description, and parameters. Here's an example for a hypothetical `getCurrentWeather` function:

```swift
let getCurrentWeatherFunction = OpenAI.ChatCompletionRequest.Tool.FunctionSchema(
    name: "getCurrentWeather",
    description: "Get the current weather for a specified location.",
    parameters: .init(
        properties: [
            "location": .init(
                type: "string",
                description: "The city and state, e.g., San Francisco, CA"
            ),
            "format": .init(
                type: "string",
                enumValues: ["celsius", "fahrenheit"],
                description: "The temperature unit to use."
            )
        ],
        required: ["location", "format"]
    )
)
```

#### Step 2: Include the Function in the Chat Request

Incorporate the function schema into your chat completion request. You can specify one or more functions that the chat model can use during the conversation.

```swift
let chatRequest = OpenAI.ChatCompletionRequest(
    model: .gpt4,
    messages: [ /* Your messages here */ ],
    tools: [
        .function(getCurrentWeatherFunction)
    ],
    tool_choice: .auto
)
```

#### Step 3: Handle the Chat Completion Response

Process the response from the OpenAI API to utilize the output of your function call. Ensure your implementation can handle different types of responses, including those involving your custom function.

```swift
openAI.perform(request: chatRequest) { result in
    switch result {
    case .success(let response):
        // Process the response, including any function outputs
        if let toolCalls = response.choices.first?.message?.tool_calls ?? response.choices.first?.delta?.tool_calls {
            // handle function calls
            print(toolCalls)
        }
        print(response)
    case .failure(let err):
        print(err.localizedDescription)
    }
}
```

### Handling Image Content in Array Messages
When dealing with messages that contain arrays of content, including image content, follow these steps to handle them appropriately in your OpenAI.swift client implementation.

#### Step 1: Create Messages with Image Content
```swift
let imageMessage = OpenAI.Message(
    role: .user, 
    content: .array([
        .image(.init(
            image_url: .init(
                url: "https://example.com/image.jpg",
                detail: .high
            )
        ))
    ])
)
```

#### Step 2: Include Image Messages in the Chat Request
```swift
let chatRequest = OpenAI.ChatCompletionRequest(
    model: .gpt4,
    messages: [imageMessage, /* other messages here */],
    /* Other optional parameters */
)
```

---

## Contributing

Contributions are welcome. Please open an issue or submit a pull request with your changes.

## TODO

- [ ] Use async/await/actor
- [ ] Pass closures to functions api
- [ ] Optionally call OpenAI functions without returning intermediate tool message to dev
- [ ] Implement Assistants endpoint
- [ ] Implement other api endpoints

## License

This project is free to use under the [MIT LICENSE](LICENSE).

The other guys:
- https://github.com/MacPaw/OpenAI
- https://github.com/adamrushy/OpenAISwift
- https://github.com/OpenDive/OpenAIKit
- https://github.com/dylanshine/openai-kit
- https://github.com/SwiftBeta/SwiftOpenAI
