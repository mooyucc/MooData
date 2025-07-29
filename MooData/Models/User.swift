import Foundation
import Combine

struct User: Identifiable, Codable {
    var id: UUID
    var username: String
    var email: String
    var createdAt: Date
    
    init(id: UUID = UUID(), username: String, email: String, createdAt: Date = Date()) {
        self.id = id
        self.username = username
        self.email = email
        self.createdAt = createdAt
    }
}

// 用于登录和注册的请求模型
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
}

// 服务器响应模型
struct AuthResponse: Codable {
    let user: User
    let token: String
}

// 验证错误
enum AuthError: Error {
    case invalidCredentials
    case networkError(String)
    case userExists
    case validationError(String)
    case serverError
    
    var message: String {
        switch self {
        case .invalidCredentials:
            return "邮箱或密码不正确"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .userExists:
            return "用户已存在"
        case .validationError(let message):
            return message
        case .serverError:
            return "服务器错误，请稍后再试"
        }
    }
} 