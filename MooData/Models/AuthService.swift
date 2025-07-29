import Foundation
import Combine

class AuthService {
    // 可以根据实际情况修改API的基础URL
    private let baseURL = "https://api.yourservice.com"
    
    // 用于存储当前认证的用户和令牌
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "authToken"
    private let userKey = "currentUser"
    
    // 测试用户信息
    private let testUsername = "TestAccount"
    private let testPassword = "123456"
    private let testEmail = "Test@test.com"
    
    // 发送登录请求
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, AuthError> {
        // 开发阶段测试用户登录
        if (email == testEmail || email == testUsername) && password == testPassword {
            return createTestUserResponse()
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        return performAuthRequest(path: "/login", request: loginRequest)
    }
    
    // 创建测试用户响应
    private func createTestUserResponse() -> AnyPublisher<AuthResponse, AuthError> {
        let testUser = User(
            id: UUID(),
            username: testUsername,
            email: testEmail,
            createdAt: Date()
        )
        
        let response = AuthResponse(
            user: testUser,
            token: "test_token_\(Int(Date().timeIntervalSince1970))"
        )
        
        return Just(response)
            .setFailureType(to: AuthError.self)
            .eraseToAnyPublisher()
    }
    
    // 发送注册请求
    func register(username: String, email: String, password: String) -> AnyPublisher<AuthResponse, AuthError> {
        // 开发阶段测试用户注册
        if username == testUsername && (email == testEmail || email == testUsername) && password == testPassword {
            return createTestUserResponse()
        }
        
        let registerRequest = RegisterRequest(username: username, email: email, password: password)
        return performAuthRequest(path: "/register", request: registerRequest)
    }
    
    // 执行认证请求的通用方法
    private func performAuthRequest<T: Encodable>(path: String, request: T) -> AnyPublisher<AuthResponse, AuthError> {
        guard let url = URL(string: baseURL + path) else {
            return Fail(error: AuthError.networkError("无效URL")).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: AuthError.networkError("请求编码失败")).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .mapError { error -> AuthError in
                return .networkError(error.localizedDescription)
            }
            .flatMap { data, response -> AnyPublisher<AuthResponse, AuthError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: AuthError.networkError("无效的响应")).eraseToAnyPublisher()
                }
                
                if httpResponse.statusCode == 401 {
                    return Fail(error: AuthError.invalidCredentials).eraseToAnyPublisher()
                }
                
                if httpResponse.statusCode == 409 {
                    return Fail(error: AuthError.userExists).eraseToAnyPublisher()
                }
                
                if httpResponse.statusCode != 200 {
                    return Fail(error: AuthError.serverError).eraseToAnyPublisher()
                }
                
                return Just(data)
                    .decode(type: AuthResponse.self, decoder: JSONDecoder())
                    .mapError { error -> AuthError in
                        return .networkError("解析响应失败: \(error.localizedDescription)")
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // 保存认证信息
    func saveAuthInfo(token: String, user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            userDefaults.set(userData, forKey: userKey)
            userDefaults.set(token, forKey: tokenKey)
        }
    }
    
    // 获取当前用户
    func getCurrentUser() -> User? {
        guard let userData = userDefaults.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
    
    // 获取认证令牌
    func getAuthToken() -> String? {
        return userDefaults.string(forKey: tokenKey)
    }
    
    // 检查用户是否已登录
    func isUserLoggedIn() -> Bool {
        return getAuthToken() != nil && getCurrentUser() != nil
    }
    
    // 注销
    func logout() {
        userDefaults.removeObject(forKey: tokenKey)
        userDefaults.removeObject(forKey: userKey)
    }
} 