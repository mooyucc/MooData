import SwiftUI
import AppKit
//注册视图
struct RegisterView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // 表单验证状态
    @State private var usernameError: String = ""
    @State private var emailError: String = ""
    @State private var passwordError: String = ""
    @State private var confirmPasswordError: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 5) {
                    Text("创建账户")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("请填写以下信息完成注册")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // 注册表单
                VStack(spacing: 18) {
                    // 用户名输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("用户名")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("请输入用户名", text: $username)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(usernameError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .onChange(of: username) { oldValue, newValue in
                                validateUsername()
                            }
                        
                        if !usernameError.isEmpty {
                            Text(usernameError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 邮箱输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("邮箱")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("请输入邮箱", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(emailError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .onChange(of: email) { oldValue, newValue in
                                validateEmail()
                            }
                        
                        if !emailError.isEmpty {
                            Text(emailError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(passwordError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .onChange(of: password) { oldValue, newValue in
                                validatePassword()
                                validateConfirmPassword()
                            }
                        
                        if !passwordError.isEmpty {
                            Text(passwordError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // 确认密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("确认密码")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        SecureField("请再次输入密码", text: $confirmPassword)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(confirmPasswordError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                            )
                            .onChange(of: confirmPassword) { oldValue, newValue in
                                validateConfirmPassword()
                            }
                        
                        if !confirmPasswordError.isEmpty {
                            Text(confirmPasswordError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // 注册按钮
                Button(action: {
                    validateForm()
                    if usernameError.isEmpty && emailError.isEmpty && passwordError.isEmpty && confirmPasswordError.isEmpty {
                        authViewModel.register(username: username, email: email, password: password)
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        
                        Text("注册")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .opacity(authViewModel.isLoading ? 0.7 : 1.0)
                }
                .disabled(authViewModel.isLoading)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 返回登录
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("返回登录")
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.vertical, 30)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if authViewModel.isAuthenticated {
                dismiss()
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
        .alert(isPresented: $authViewModel.showError) {
            Alert(
                title: Text("注册失败"),
                message: Text(authViewModel.error?.message ?? "未知错误"),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // 验证用户名
    private func validateUsername() {
        usernameError = ""
        if username.isEmpty {
            usernameError = "用户名不能为空"
        } else if username.count < 3 {
            usernameError = "用户名至少需要3个字符"
        }
    }
    
    // 验证邮箱
    private func validateEmail() {
        emailError = ""
        if email.isEmpty {
            emailError = "邮箱不能为空"
        } else if !authViewModel.isValidEmail(email) {
            emailError = "请输入有效的邮箱地址"
        }
    }
    
    // 验证密码
    private func validatePassword() {
        passwordError = ""
        if password.isEmpty {
            passwordError = "密码不能为空"
        } else if !authViewModel.isValidPassword(password) {
            passwordError = "密码至少需要6个字符"
        }
    }
    
    // 验证确认密码
    private func validateConfirmPassword() {
        confirmPasswordError = ""
        if confirmPassword.isEmpty {
            confirmPasswordError = "请确认密码"
        } else if confirmPassword != password {
            confirmPasswordError = "两次输入的密码不一致"
        }
    }
    
    // 验证表单
    private func validateForm() {
        validateUsername()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
    }
}

#Preview {
    RegisterView(authViewModel: AuthViewModel())
} 