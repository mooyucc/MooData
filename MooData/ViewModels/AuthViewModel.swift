import Foundation
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    // 发布用户登录状态变化
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    
    // 加载状态
    @Published var isLoading: Bool = false
    
    // 错误处理
    @Published var error: AuthError?
    @Published var showError: Bool = false
    
    // 认证服务
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 检查是否已经登录
        checkAuthStatus()
    }
    
    private func checkAuthStatus() {
        if authService.isUserLoggedIn() {
            isAuthenticated = true
            currentUser = authService.getCurrentUser()
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // 登录测试用户
    func loginTestUser() {
        login(email: "Test@test.com", password: "123456")
    }
    
    // 登录方法
    func login(email: String, password: String) {
        isLoading = true
        error = nil
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                        self?.showError = true
                    }
                },
                receiveValue: { [weak self] response in
                    self?.authService.saveAuthInfo(token: response.token, user: response.user)
                    self?.isAuthenticated = true
                    self?.currentUser = response.user
                }
            )
            .store(in: &cancellables)
    }
    
    // 注册方法
    func register(username: String, email: String, password: String) {
        isLoading = true
        error = nil
        
        authService.register(username: username, email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                        self?.showError = true
                    }
                },
                receiveValue: { [weak self] response in
                    self?.authService.saveAuthInfo(token: response.token, user: response.user)
                    self?.isAuthenticated = true
                    self?.currentUser = response.user
                }
            )
            .store(in: &cancellables)
    }
    
    // 注销方法
    func logout() {
        authService.logout()
        isAuthenticated = false
        currentUser = nil
    }
    
    // 验证邮箱格式
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // 验证密码强度
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
} 