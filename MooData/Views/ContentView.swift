import SwiftUI
import AppKit

//定义颜色
private let SelectColor = Color("SelectColor")//从Assets.xcassets中获取选中颜色
private let ProjectCardColor = Color("ProjectCardColor")//从Assets.xcassets中获取项目卡片颜色
private let UserColor = Color("UserColor")//从Assets.xcassets中获取用户颜色

//主视图
struct ContentView: View {
    @StateObject private var viewModel = ProjectViewModel()
    @EnvironmentObject private var authViewModel: AuthViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingNewProjectSheet = false
    @State private var showingNewGroupSheet = false
    @State private var showingSettingsSheet = false
    @State private var isEditing = false
    @State private var selectedProjects = Set<UUID>()
    @State private var selectedProjectId: UUID?
    @State private var showLogoutAlert = false
    @State private var showingDeleteGroupSheet = false
    @State private var showingOpenFilePanel = false
    @State private var showingSaveFilePanel = false
    @State private var showingSaveAsFilePanel = false
    @State private var currentFileURL: URL?
    @State private var hasOpenFile = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // 搜索栏
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(8)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 获取搜索结果
                        let searchResults = viewModel.searchProjects(searchText: searchText)
                        
                        // 如果搜索文本为空，显示正常的分组视图
                        if searchText.isEmpty {
                            // 未分组的项目
                            if !viewModel.ungroupedProjects().isEmpty {
                                ProjectGridSection(
                                    title: "未分组项目",
                                    projects: viewModel.ungroupedProjects(),
                                    viewModel: viewModel,
                                    isEditing: isEditing,
                                    groupId: nil,
                                    selectedProjects: $selectedProjects,
                                    selectedProjectId: $selectedProjectId
                                )
                            }
                            
                            // 分组的项目
                            ForEach(viewModel.groups) { group in
                                if !viewModel.projectsInGroup(group.id).isEmpty {
                                    ProjectGridSection(
                                        title: group.name,
                                        projects: viewModel.projectsInGroup(group.id),
                                        viewModel: viewModel,
                                        isEditing: isEditing,
                                        groupId: group.id,
                                        selectedProjects: $selectedProjects,
                                        selectedProjectId: $selectedProjectId
                                    )
                                }
                            }
                        } else {
                            // 显示搜索结果
                            if !searchResults.isEmpty {
                                ProjectGridSection(
                                    title: "搜索结果",
                                    projects: searchResults,
                                    viewModel: viewModel,
                                    isEditing: isEditing,
                                    groupId: nil,
                                    selectedProjects: $selectedProjects,
                                    selectedProjectId: $selectedProjectId
                                )
                            } else {
                                // 没有搜索结果时显示提示
                                VStack(spacing: 20) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    Text("没有搜索结果")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                    }
                    .padding()
                }
                
                // 底部工具栏
                HStack {
                    Spacer()
                    
                    // 主题切换按钮
                    Button(action: {
                        isDarkMode.toggle()
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .frame(height: 44)
                .padding(.horizontal)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .navigationTitle("项目列表")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingNewProjectSheet = true }) {
                            Label("新建项目", systemImage: "plus")
                        }
                        Button(action: { showingNewGroupSheet = true }) {
                            Label("新建项目组", systemImage: "folder.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(SelectColor)
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    if isEditing {
                        HStack(spacing: 12) {
                            Button(action: {
                                // 删除选中的项目
                                let selectedProjectIds = Array(selectedProjects)
                                
                                // 过滤掉可能已经不存在的项目ID
                                let filteredIds = selectedProjectIds.filter { projectId in
                                    viewModel.projects.contains { $0.id == projectId }
                                }
                                
                                if !filteredIds.isEmpty {
                                    let indexSet = IndexSet(viewModel.projects.enumerated()
                                        .filter { filteredIds.contains($0.element.id) }
                                        .map { $0.offset })
                                    
                                    // 确保索引集合有效
                                    if !indexSet.isEmpty {
                                        // 使用try-catch捕获可能的异常
                                        do {
                                            viewModel.deleteProject(at: indexSet)
                                        } catch {
                                            print("删除项目时出错: \(error.localizedDescription)")
                                        }
                                    }
                                }
                                
                                selectedProjects.removeAll()
                                isEditing = false
                            }) {
                                Label("删除", systemImage: "trash")
                                    .foregroundColor(.red)
                            }
                            .disabled(selectedProjects.isEmpty)
                            
                            Button(action: {
                                isEditing = false
                                selectedProjects.removeAll()
                            }) {
                                Label("完成", systemImage: "checkmark")
                            }
                        }
                    } else {
                        Menu {
                            Button(action: {
                                isEditing = true
                            }) {
                                Label("删除项目", systemImage: "trash")
                            }
                            
                            Button(action: {
                                showingDeleteGroupSheet = true
                            }) {
                                Label("删除项目组", systemImage: "folder.badge.minus")
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(SelectColor)
                        }
                    }
                }
                
                // 添加用户信息和注销按钮
                ToolbarItem(placement: .automatic) {
                    Menu {
                        if let user = authViewModel.currentUser {
                            Text("用户: \(user.username)")
                            Divider()
                        }
                        
                        Button(action: {
                            let openPanel = NSOpenPanel()
                            openPanel.allowsMultipleSelection = false
                            openPanel.canChooseDirectories = false
                            openPanel.canCreateDirectories = false
                            openPanel.allowedContentTypes = [.json]
                            openPanel.begin { result in
                                if result == .OK, let url = openPanel.url {
                                    loadFromFile(url: url)
                                    currentFileURL = url
                                    hasOpenFile = true
                                }
                            }
                        }) {
                            Label("打开", systemImage: "folder")
                        }
                        
                        Button(action: {
                            if let url = currentFileURL {
                                saveToFile(url: url)
                            } else {
                                let savePanel = NSSavePanel()
                                savePanel.allowedContentTypes = [.json]
                                savePanel.canCreateDirectories = true
                                savePanel.begin { result in
                                    if result == .OK, let url = savePanel.url {
                                        saveToFile(url: url)
                                        currentFileURL = url
                                        hasOpenFile = true
                                    }
                                }
                            }
                        }) {
                            Label("保存", systemImage: "square.and.arrow.down")
                        }
                        .disabled(currentFileURL == nil)
                        
                        Button(action: {
                            let savePanel = NSSavePanel()
                            savePanel.allowedContentTypes = [.json]
                            savePanel.canCreateDirectories = true
                            savePanel.begin { result in
                                if result == .OK, let url = savePanel.url {
                                    saveToFile(url: url)
                                    currentFileURL = url
                                    hasOpenFile = true
                                }
                            }
                        }) {
                            Label("另存为", systemImage: "square.and.arrow.down.on.square")
                        }
                        
                        Button(action: {
                            closeCurrentFile()
                        }) {
                            Label("关闭", systemImage: "xmark.circle")
                        }
                        .disabled(!hasOpenFile)
                        
                        Divider()
                        
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            Label("注销", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(UserColor)
                            .imageScale(.large)
                    }
                    .tint(UserColor)
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(viewModel: viewModel, isPresented: $showingNewProjectSheet)
            }
            .sheet(isPresented: $showingNewGroupSheet) {
                NewGroupSheet(viewModel: viewModel, isPresented: $showingNewGroupSheet)
            }
            .alert("确认注销", isPresented: $showLogoutAlert) {
                Button("取消", role: .cancel) {}
                Button("注销", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("注销确认消息")
            }
        } detail: {
            if let projectId = selectedProjectId {
                if let project = viewModel.projects.first(where: { $0.id == projectId }) {
                    DesignIndicatorTabsView(projectId: projectId, projectName: project.name, projectColor: project.color)
                } else {
                    DesignIndicatorTabsView(projectId: projectId, projectName: "", projectColor: "#007AFF")
                }
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .padding()
                    Text("选择项目")
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 300)
        .sheet(isPresented: $showingDeleteGroupSheet) {
            DeleteGroupSheet(viewModel: viewModel, isPresented: $showingDeleteGroupSheet)
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            // 监听设置显示通知
            NotificationCenter.default.addObserver(forName: .showSettings, object: nil, queue: .main) { _ in
                showingSettingsSheet = true
            }
            
            // 监听文件操作通知
            NotificationCenter.default.addObserver(forName: .openFile, object: nil, queue: .main) { _ in
                let openPanel = NSOpenPanel()
                openPanel.allowsMultipleSelection = false
                openPanel.canChooseDirectories = false
                openPanel.canCreateDirectories = false
                openPanel.allowedContentTypes = [.json]
                openPanel.begin { result in
                    if result == .OK, let url = openPanel.url {
                        loadFromFile(url: url)
                        currentFileURL = url
                        hasOpenFile = true
                    }
                }
            }
            
            NotificationCenter.default.addObserver(forName: .saveFile, object: nil, queue: .main) { _ in
                if let url = currentFileURL {
                    saveToFile(url: url)
                } else {
                    let savePanel = NSSavePanel()
                    savePanel.allowedContentTypes = [.json]
                    savePanel.canCreateDirectories = true
                    savePanel.begin { result in
                        if result == .OK, let url = savePanel.url {
                            saveToFile(url: url)
                            currentFileURL = url
                            hasOpenFile = true
                        }
                    }
                }
            }
            
            NotificationCenter.default.addObserver(forName: .saveAsFile, object: nil, queue: .main) { _ in
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.json]
                savePanel.canCreateDirectories = true
                savePanel.begin { result in
                    if result == .OK, let url = savePanel.url {
                        saveToFile(url: url)
                        currentFileURL = url
                        hasOpenFile = true
                    }
                }
            }
            
            NotificationCenter.default.addObserver(forName: .closeFile, object: nil, queue: .main) { _ in
                closeCurrentFile()
            }
            
            NotificationCenter.default.addObserver(forName: .showNewProjectSheet, object: nil, queue: .main) { _ in
                showingNewProjectSheet = true
            }
        }
    }
    
    // 将文件操作方法移到ContentView结构体内部
    private func loadFromFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let projectData = try decoder.decode(ProjectData.self, from: data)
            viewModel.loadFromData(projectData)
            // 自动选中第一个项目
            if let firstProject = projectData.projects.first {
                selectedProjectId = firstProject.id
            }
            // 加载设计指标Tab数据
            if let tabs = projectData.designIndicatorTabs, let projectId = selectedProjectId {
                if let encoded = try? JSONEncoder().encode(tabs) {
                    UserDefaults.standard.set(encoded, forKey: "DesignIndicatorTabs-\(projectId.uuidString)")
                }
            }
        } catch {
            print("Error loading file: \(error.localizedDescription)")
        }
    }
    
    private func saveToFile(url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            var projectData = viewModel.getProjectData()
            // 读取当前IndicatorStore的tabs
            if let projectId = selectedProjectId,
               let data = UserDefaults.standard.data(forKey: "DesignIndicatorTabs-\(projectId.uuidString)"),
               let tabs = try? JSONDecoder().decode([DesignIndicatorTab].self, from: data) {
                projectData.designIndicatorTabs = tabs
            }
            let data = try encoder.encode(projectData)
            try data.write(to: url)
        } catch {
            print("Error saving file: \(error.localizedDescription)")
        }
    }
    
    private func closeCurrentFile() {
        // 先清除本地缓存
        if let projectId = selectedProjectId {
            UserDefaults.standard.removeObject(forKey: "DesignIndicatorData-\(projectId.uuidString)")
            UserDefaults.standard.removeObject(forKey: "DesignIndicatorTabs-\(projectId.uuidString)")
        }
        currentFileURL = nil
        hasOpenFile = false
        viewModel.clearAllData()
        selectedProjectId = nil
    }
}

//预览
#Preview {
    ContentView()
}

//项目编辑弹窗
struct EditProjectSheet: View {
    var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var isPresented: Bool
    @State private var projectName: String
    @State private var projectColor: String
    @State private var selectedColor: Color
    
    init(project: Project, viewModel: ProjectViewModel, isPresented: Binding<Bool>) {
        self.project = project
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._projectName = State(initialValue: project.name)
        self._projectColor = State(initialValue: project.color)
        self._selectedColor = State(initialValue: Color(hex: project.color) ?? .blue)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("编辑项目")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 15) {
                // 项目名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("项目名称")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("输入项目名称", text: $projectName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                
                // 项目颜色选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("项目颜色")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 显示当前选中的颜色
                    Rectangle()
                        .fill(selectedColor)
                        .frame(height: 40)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // 颜色选择器
                    ColorPicker("选择颜色", selection: $selectedColor)
                        .onChange(of: selectedColor) { oldValue, newColor in
                            projectColor = newColor.toHex() ?? project.color
                        }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.large)
                
                Button("保存") {
                    viewModel.updateProject(project, newName: projectName, newColor: projectColor)
                    isPresented = false
                }
                .buttonStyle(ModernButtonStyle())
                .controlSize(.large)
                .disabled(projectName.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 380)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

//项目卡片
struct ProjectCard: View {
    let project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @State private var showingEditSheet = false
    @State private var isHovered = false
    @State private var refreshView = false
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()//项目名称和任务数量之间的间距
                
                // 编辑按钮
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .symbolVariant(.circle)
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(6)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("指标数量" + "\(getTabCount(for: project.id))")
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(isHovered ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditProjectSheet(project: project, viewModel: viewModel, isPresented: $showingEditSheet)
        }
        .id(refreshView) // 使用id强制视图在refreshView改变时刷新
    }
    
    private func getTabCount(for projectId: UUID) -> Int {
        if let data = UserDefaults.standard.data(forKey: "DesignIndicatorTabs-\(projectId.uuidString)"),
           let tabs = try? JSONDecoder().decode([DesignIndicatorTab].self, from: data) {
            return tabs.count
        }
        return 0
    }
}

//删除选中标记
struct CheckmarkOverlay: View {
    let isSelected: Bool
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)  // 创建一个半透明的灰色背景,透明度为0.1
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .white)
                .font(.system(size: 24))
        }
        .cornerRadius(12)
    }
}

//新建项目
struct NewProjectSheet: View {
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var isPresented: Bool
    @State private var projectName = ""
    @State private var selectedGroupId: UUID?
    @State private var projectColor: String
    @State private var selectedColor: Color
    
    init(viewModel: ProjectViewModel, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        
        // 从循环颜色中获取初始颜色
        let initialColor = viewModel.getNextProjectColorPreview()
        self._projectColor = State(initialValue: initialColor)
        
        // 从十六进制转换为Color
        let colorFromHex = Color(hex: initialColor) ?? .blue
        self._selectedColor = State(initialValue: colorFromHex)
        
        print("初始化颜色: \(initialColor), 显示颜色: \(colorFromHex)")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新建项目")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 15) {
                // 项目名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("项目名称")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("输入项目名称", text: $projectName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                
                // 项目组选择
                if !viewModel.groups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("所属项目组")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("所属项目组", selection: $selectedGroupId) {
                            Text("未分组").tag(nil as UUID?)
                            ForEach(viewModel.groups) { group in
                                Text(group.name).tag(group.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                }
                
                // 项目颜色选择
                VStack(alignment: .leading, spacing: 8) {
                    Text("项目颜色")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // 显示当前选中的颜色
                    Rectangle()
                        .fill(selectedColor)
                        .frame(height: 40)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    // 颜色选择器
                    ColorPicker("选择颜色", selection: $selectedColor)
                        .onChange(of: selectedColor) { oldValue, newColor in
                            projectColor = newColor.toHex() ?? "#007AFF"
                        }
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.large)
                
                Button("创建") {
                    if !projectName.isEmpty {
                        viewModel.addProject(name: projectName, groupId: selectedGroupId, color: projectColor)
                        isPresented = false
                    }
                }
                .buttonStyle(ModernButtonStyle())
                .controlSize(.large)
                .disabled(projectName.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 450)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            // 确保在表单显示时获取最新的颜色预览
            let previewColor = viewModel.getNextProjectColorPreview()
            projectColor = previewColor
            selectedColor = Color(hex: previewColor) ?? .blue
            print("表单打开时颜色：\(previewColor), 项目数量：\(viewModel.projects.count)")
        }
    }
}

//自定义现代化按钮样式
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .foregroundColor(.primary)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

//新建项目组
struct NewGroupSheet: View {
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var isPresented: Bool
    @State private var groupName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("新建项目组")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 15) {
                // 项目组名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("项目组名称")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("输入项目组名称", text: $groupName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.large)
                
                Button("创建") {
                    if !groupName.isEmpty {
                        viewModel.addGroup(name: groupName)
                        isPresented = false
                    }
                }
                .buttonStyle(ModernButtonStyle())
                .controlSize(.large)
                .disabled(groupName.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 250)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

//项目网格区域
struct ProjectGridSection: View {
    let title: String
    let projects: [Project]
    let viewModel: ProjectViewModel
    let isEditing: Bool
    let groupId: UUID?
    @Binding var selectedProjects: Set<UUID>
    @Binding var selectedProjectId: UUID?
    @State private var isTargeted = false
    @State private var isEditingGroupName = false
    @State private var editedGroupName = ""
    @State private var draggedProjectId: UUID?
    
    private func projectCard(for project: Project) -> some View {
        ProjectCard(project: project, viewModel: viewModel, isSelected: selectedProjects.contains(project.id))
    }
    
    private func editingProjectCard(for project: Project) -> some View {
        ZStack {
            projectCard(for: project)
                .overlay(
                    CheckmarkOverlay(isSelected: selectedProjects.contains(project.id))
                )
                .onTapGesture {
                    if selectedProjects.contains(project.id) {
                        selectedProjects.remove(project.id)
                    } else {
                        selectedProjects.insert(project.id)
                    }
                }
        }
    }
    
    private func normalProjectCard(for project: Project) -> some View {
        ZStack {
            // 主项目卡片
            ProjectCard(project: project, viewModel: viewModel, isSelected: selectedProjectId == project.id)
                .onTapGesture {
                    selectedProjectId = project.id
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedProjectId == project.id ? SelectColor.opacity(1) : Color.clear) // 选中时背景加深
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .overlay(
                    ZStack {
                        if draggedProjectId == project.id {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        }
                    }
                )
            
            // 顶部放置区（在卡片上方插入）
            VStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 12)
                    .dropDestination(for: String.self) { items, location in
                        guard let droppedProjectIdString = items.first,
                              let droppedProjectId = UUID(uuidString: droppedProjectIdString),
                              let draggedProject = viewModel.projects.first(where: { $0.id == droppedProjectId }),
                              let targetProject = viewModel.projects.first(where: { $0.id == project.id }),
                              draggedProject.id != targetProject.id else {
                            return false
                        }
                        
                        // 重置拖动标记
                        DispatchQueue.main.async {
                            draggedProjectId = nil
                        }
                        
                        // 如果两个项目在同一个分组，则直接插入
                        if draggedProject.groupId == targetProject.groupId {
                            viewModel.insertProject(draggedProject, beforeProject: targetProject)
                            return true
                        } else if targetProject.groupId == groupId {
                            // 如果拖动的项目不在当前组，则移动到当前组，并在目标项目前插入
                            viewModel.moveProject(draggedProject, toGroup: groupId)
                            viewModel.insertProject(draggedProject, beforeProject: targetProject)
                            return true
                        }
                        
                        return false
                    } isTargeted: { topIsTargeted in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            if topIsTargeted {
                                #if os(iOS)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                #elseif os(macOS)
                                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                                #endif
                            }
                        }
                    }
                
                Spacer()
            }
            
            // 底部放置区（在卡片下方插入）
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 12)
                    .dropDestination(for: String.self) { items, location in
                        guard let droppedProjectIdString = items.first,
                              let droppedProjectId = UUID(uuidString: droppedProjectIdString),
                              let draggedProject = viewModel.projects.first(where: { $0.id == droppedProjectId }),
                              let targetProject = viewModel.projects.first(where: { $0.id == project.id }),
                              draggedProject.id != targetProject.id else {
                            return false
                        }
                        
                        // 重置拖动标记
                        DispatchQueue.main.async {
                            draggedProjectId = nil
                        }
                        
                        // 如果两个项目在同一个分组，则直接插入
                        if draggedProject.groupId == targetProject.groupId {
                            viewModel.insertProject(draggedProject, afterProject: targetProject)
                            return true
                        } else if targetProject.groupId == groupId {
                            // 如果拖动的项目不在当前组，则移动到当前组，并在目标项目后插入
                            viewModel.moveProject(draggedProject, toGroup: groupId)
                            viewModel.insertProject(draggedProject, afterProject: targetProject)
                            return true
                        }
                        
                        return false
                    } isTargeted: { bottomIsTargeted in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            if bottomIsTargeted {
                                #if os(iOS)
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                #elseif os(macOS)
                                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                                #endif
                            }
                        }
                    }
            }
        }
        // 拖动手势
        .onDrag {
            // 设置拖动的项目ID
            draggedProjectId = project.id
            return NSItemProvider(object: project.id.uuidString as NSString)
        }
        // 中间区域放置目标（替换/交换）
        .dropDestination(for: String.self) { items, location in
            guard let droppedProjectIdString = items.first,
                  let droppedProjectId = UUID(uuidString: droppedProjectIdString),
                  let draggedProject = viewModel.projects.first(where: { $0.id == droppedProjectId }),
                  let targetProject = viewModel.projects.first(where: { $0.id == project.id }),
                  draggedProject.id != targetProject.id else {
                return false
            }
            
            // 重置拖动标记
            DispatchQueue.main.async {
                draggedProjectId = nil
            }
            
            // 确保在同一组内调整顺序
            if draggedProject.groupId == targetProject.groupId {
                // 交换两个项目的顺序
                viewModel.swapProjectOrder(projectId1: draggedProject.id, projectId2: targetProject.id)
                return true
            } else if targetProject.groupId == groupId {
                // 如果拖动的项目不在当前组，则移动到当前组，并设置顺序为目标项目的顺序
                viewModel.moveProject(draggedProject, toGroup: groupId)
                viewModel.swapProjectOrder(projectId1: draggedProject.id, projectId2: targetProject.id)
                return true
            }
            
            return false
        } isTargeted: { isTargeted in
            // 当前项目是否是放置的目标
            withAnimation {
                if isTargeted {
                    // 创建一个轻微的视觉反馈以指示可放置
                    #if os(iOS)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    #elseif os(macOS)
                    NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                    #endif
                }
            }
        }
    }
    
    private var projectGrid: some View {
        // 使用LazyVGrid创建一个网格布局
        // columns参数设置为自适应列宽,最小宽度100,列间距12
        // spacing参数设置网格行间距为12
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 6)
        ], spacing: 6) {
            ForEach(projects) { project in
                if isEditing {
                    editingProjectCard(for: project)
                        .frame(maxWidth: .infinity)
                } else {
                    normalProjectCard(for: project)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 项目组名称
            if let groupId = groupId {
                HStack {
                    if isEditingGroupName {
                        TextField("项目组名称", text: $editedGroupName)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.title3.bold())
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .onSubmit {
                                if !editedGroupName.isEmpty {
                                    if let group = viewModel.groups.first(where: { $0.id == groupId }) {
                                        viewModel.updateGroupName(group, newName: editedGroupName)
                                    }
                                }
                                isEditingGroupName = false
                            }
                    } else {
                        Text(title)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .onTapGesture {
                    editedGroupName = title
                    isEditingGroupName = true
                }
            } else {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            projectGrid
        }
        .padding(12)//项目组名称和项目卡片之间的间距
        .background(ProjectCardColor)  // 使用预定义的ProjectCardColor作为背景颜色
        .cornerRadius(24)
        .overlay( // 添加叠加层
            RoundedRectangle(cornerRadius: 24) // 创建圆角矩形
                .stroke(isTargeted ? Color.blue.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1) // 设置边框颜色和宽度,当被拖拽目标时显示蓝色,否则显示白色
                .animation(.easeInOut, value: isTargeted) // 添加动画效果,根据isTargeted值变化时平滑过渡
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .dropDestination(for: String.self) { items, location in
            guard let droppedProjectIdString = items.first,
                  let droppedProjectId = UUID(uuidString: droppedProjectIdString),
                  let project = viewModel.projects.first(where: { $0.id == droppedProjectId }),
                  project.groupId != groupId else {
                return false
            }
            
            // 将项目移动到当前组
            viewModel.moveProject(project, toGroup: groupId)
            
            // 重置拖动标记
            DispatchQueue.main.async {
                draggedProjectId = nil
            }
            
            return true
        } isTargeted: { isTargeted in
            self.isTargeted = isTargeted
            
            // 提供触觉反馈
            if isTargeted {
                #if os(iOS)
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                #elseif os(macOS)
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                #endif
            }
        }
        .onTapGesture {
            if isEditingGroupName {
                if !editedGroupName.isEmpty {
                    if let groupId = groupId {
                        let foundGroup = viewModel.groups.first(where: { $0.id == groupId })
                        if let group = foundGroup {
                            viewModel.updateGroupName(group, newName: editedGroupName)
                        }
                    }
                }
                isEditingGroupName = false
            }
        }
    }
}

// 删除项目组弹窗
struct DeleteGroupSheet: View {
    @ObservedObject var viewModel: ProjectViewModel
    @Binding var isPresented: Bool
    @State private var selectedGroupId: UUID?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("删除项目组")
                .font(.headline)
                .padding(.top)
            
            VStack(spacing: 15) {
                // 项目组选择
                if !viewModel.groups.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("选择要删除的项目组")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("选择要删除的项目组", selection: $selectedGroupId) {
                            ForEach(viewModel.groups) { group in
                                Text(group.name).tag(group.id as UUID?)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    }
                } else {
                    Text("没有可用项目组")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.large)
                
                Button("删除") {
                    if let groupId = selectedGroupId,
                       let group = viewModel.groups.first(where: { $0.id == groupId }) {
                        viewModel.deleteGroup(group)
                        isPresented = false
                    }
                }
                .buttonStyle(ModernButtonStyle())
                .controlSize(.large)
                .disabled(selectedGroupId == nil)
            }
            .padding(.bottom)
        }
        .frame(width: 400, height: 250)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
} 
