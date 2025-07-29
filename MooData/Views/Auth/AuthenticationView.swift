import SwiftUI
//认证视图
struct AuthenticationView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // 显示主应用内容
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                // 显示登录视图
                LoginView(authViewModel: authViewModel)
            }
        }
    }
}

#Preview {
    AuthenticationView()
} 