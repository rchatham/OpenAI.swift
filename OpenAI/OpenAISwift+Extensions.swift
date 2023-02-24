//
//  OpenAISwift+Extensions.swift
//  OpenAI
//
//  Created by Reid Chatham on 2/13/23.
//

import Foundation
import OpenAISwift

extension UserDefaults {
    var model: OpenAIModelType {
        get {
            if let modelName = string(forKey: "model"), let model = OpenAIModelType(rawValue: modelName) {
                return model
            } else {
                return .gpt3(.davinci)
            }
        }
        set {
            set(newValue.modelName, forKey: "model")
        }
    }
    
    var maxTokens: Int {
        get {
            return integer(forKey: "max_tokens")
        }
        set {
            set(newValue, forKey: "max_tokens")
        }
    }
    
    var temperature: Double {
        get {
            return double(forKey: "temperature")
        }
        set {
            set(newValue, forKey: "temperature")
        }
    }
}

extension OpenAIModelType: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case GPT3.davinci.rawValue: self = .gpt3(.davinci)
        case GPT3.curie.rawValue: self = .gpt3(.curie)
        case GPT3.babbage.rawValue: self = .gpt3(.babbage)
        case GPT3.ada.rawValue: self = .gpt3(.ada)
        case Codex.davinci.rawValue: self = .codex(.davinci)
        case Codex.cushman.rawValue: self = .codex(.cushman)
        case Feature.davinci.rawValue: self = .feature(.davinci)
        default: return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .gpt3(let model): return model.rawValue
        case .codex(let model): return model.rawValue
        case .feature(let model): return model.rawValue
        }
    }
}

extension OpenAIModelType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(modelName)
    }
}

extension OpenAIModelType.GPT3 {
  static var cases: [OpenAIModelType.GPT3] {
    [.davinci, .curie, .babbage, .ada]
  }
}

extension OpenAIModelType.Codex {
  static var cases: [OpenAIModelType.Codex] {
    [.davinci, .cushman]
  }
}

extension OpenAIModelType.Feature {
  static var cases: [OpenAIModelType.Feature] {
    [.davinci]
  }
}

