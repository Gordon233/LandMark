import Foundation

// MARK: - Chat API Endpoints
enum ChatEndpoint: APIEndpoint {
    case sendMessage
    
    var path: String {
        switch self {
        case .sendMessage:
            return "/api/ai/chat"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .sendMessage:
            return .POST
        }
    }
}
