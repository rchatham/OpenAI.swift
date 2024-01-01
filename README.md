# OpenAI-Swift

The smallest OpenAI API implementation written in Swift. 

This package provides a simple Swift interface for interacting with OpenAI's Chat API, with full support for functions. Written in a highly compact manor, minimizing the number of lines of code, keeping things light while increasing readability, efficiency, maintainability, and extensibility.

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
    .package(url: "https://github.com/rchatham/OpenAI-Swift.git", .upToNextMajor(from: "1.0.0"))
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

## Contributing

Contributions are welcome. Please open an issue or submit a pull request with your changes.

## TODO

- [ ] Use async/await/actor
- [ ] Pass closures to functions api
- [ ] Optionally call OpenAI functions without returning intermediate tool message to dev
- [ ] Implement Assistants endpoint
- [ ] Implement other api endpoints

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
