import SwiftUI
//登录视图 
struct LoginView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegister: Bool = false
    @State private var showingForgotPassword: Bool = false
    
    // 表单验证状态
    @State private var emailError: String = ""
    @State private var passwordError: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            VStack(spacing: 5) {
                Text("欢迎回来")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                
                Text("请登录您的账户")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 30)
            
            // 登录表单
            VStack(spacing: 20) {
                // 邮箱输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("邮箱")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("请输入邮箱", text: $email)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
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
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(passwordError.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                        )
                        .onChange(of: password) { oldValue, newValue in
                            validatePassword()
                        }
                    
                    if !passwordError.isEmpty {
                        Text(passwordError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    // 忘记密码按钮
                    Button(action: {
                        showingForgotPassword = true
                    }) {
                        Text("忘记密码?")
                            .font(.callout)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 5)
                }
            }
            .padding(.horizontal, 20)
            
            // 登录按钮
            Button(action: {
                validateForm()
                if emailError.isEmpty && passwordError.isEmpty {
                    authViewModel.login(email: email, password: password)
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: authViewModel.isLoading ? .gray : .white))
                            .padding(.trailing, 5)
                    }
                    
                    Text("登录")
                        .font(.body)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(CustomButtonStyle(color: .purple))
            .disabled(authViewModel.isLoading)
            .opacity(authViewModel.isLoading ? 0.7 : 1.0)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // 开发测试用户快捷登录
            Button(action: {
                authViewModel.loginTestUser()
            }) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver")
                    Text("测试用户登录")
                        .font(.body)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(CustomButtonStyle(color: .green))
            .padding(.horizontal, 20)
            .padding(.top, 5)
            
            // 注册按钮
            HStack {
                Text("还没有账户?")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showRegister = true
                }) {
                    Text("立即注册")
                        .font(.body)
                        .foregroundColor(.purple)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.vertical, 30)
        .background(Color.primary.opacity(0.05))
        .frame(width: 300, height: 600)
        .alert(isPresented: $authViewModel.showError) {
            Alert(
                title: Text("登录失败"),
                message: Text(authViewModel.error?.message ?? "未知错误"),
                dismissButton: .default(Text("确定"))
            )
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showingForgotPassword) {
            Text("重置密码功能即将推出")
                .padding()
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
        }
    }
    
    // 验证表单
    private func validateForm() {
        validateEmail()
        validatePassword()
    }
}

// 自定义按钮样式
struct CustomButtonStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .cornerRadius(24)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    LoginView(authViewModel: AuthViewModel())
} 