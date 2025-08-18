import Foundation
import SwiftUI

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    
    init(message: String, userId: String? = nil) {
        self.model = "google/gemini-2.0-flash-001"
        self.messages = [ChatMessage(role: "user", content: message)]
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
    let refusal: String?
    let reasoning: String?
    let reasoningDetails: [ReasoningDetail]?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case refusal
        case reasoning
        case reasoningDetails = "reasoning_details"
    }

    // 简化的初始化器，用于发送请求
    init(role: String, content: String) {
        self.role = role
        self.content = content
        self.refusal = nil
        self.reasoning = nil
        self.reasoningDetails = nil
    }
}

struct ReasoningDetail: Codable {
    let type: String
    let text: String
    let format: String
    let index: Int
}

struct ChatResponse: Codable {
    let success: Bool
    let data: ChatData
}

struct ChatData: Codable {
    let id: String
    let provider: String
    let model: String
    let object: String
    let created: Int
    let choices: [ChatChoice]
    let usage: ChatUsage
}

struct ChatChoice: Codable {
    let logprobs: String?
    let finishReason: String
    let nativeFinishReason: String
    let index: Int
    let message: ChatMessage

    enum CodingKeys: String, CodingKey {
        case logprobs
        case finishReason = "finish_reason"
        case nativeFinishReason = "native_finish_reason"
        case index
        case message
    }
}

struct ChatUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

@MainActor
@Observable
final class ChatViewModel {
    var isLoading = false
    var lastResponse: String?
    var errorMessage: String?
    var isSuccess = false

    private let apiClient = APIClient.shared

    func sendMessage(_ message: String) async {
        clearState()

        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Message cannot be empty"
            return
        }

        isLoading = true

        do {
            let request = ChatRequest(message: message)
            let endpoint = ChatEndpoint.sendMessage
            let response: ChatResponse = try await apiClient.request(endpoint, body: request)

            if response.success, let firstChoice = response.data.choices.first {
                lastResponse = firstChoice.message.content
                isSuccess = true
                errorMessage = nil
            } else {
                errorMessage = "Invalid response format"
            }

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    func clearAll() {
        clearState()
        lastResponse = nil
    }

    private func clearState() {
        errorMessage = nil
        isSuccess = false
    }

    private func handleError(_ error: Error) {
        if let networkError = error as? NetworkError {
            errorMessage = networkError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        
        isSuccess = false
    }
}


extension ChatViewModel {

    var hasData: Bool {
        return lastResponse != nil
    }

    var hasError: Bool {
        return errorMessage != nil
    }

    var formattedResponse: String {
        guard let response = lastResponse else {
            return "No response yet"
        }
        return response
    }

    var responsePreview: String {
        guard let response = lastResponse else {
            return "No response yet"
        }

        // 如果响应太长，显示预览
        if response.count > 200 {
            let preview = String(response.prefix(200))
            return "\(preview)..."
        }

        return response
    }
}