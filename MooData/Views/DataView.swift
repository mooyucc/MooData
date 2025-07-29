import SwiftUI
import UniformTypeIdentifiers

// Tab页数据结构
struct DesignIndicatorTab: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var indicatorGroups: [DesignIndicatorGroup]
}

// Tab页视图
struct DesignIndicatorView: View {
    let projectId: UUID
    let name: String
    @Binding var groups: [DesignIndicatorGroup]
    let projectColor: String
    // 新增：卡片输入相关状态
    @Binding var notePopoverId: UUID?
    @Binding var showInputAlert: Bool
    @Binding var inputAlertMessage: String
    @Binding var lastValidValues: [UUID: String]
    var focusedField: FocusState<UUID?>.Binding
    var onAutoCalculate: () -> Void
    var onAnyValueChange: (() -> Void)? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    // 新增：每行最大高度
    @State private var rowHeights: [Int: CGFloat] = [:]

    let minCardWidth: CGFloat = 340
    let cardSpacing: CGFloat = 24
    let horizontalPadding: CGFloat = 32

    // 卡片视图
    var body: some View {
        let gradient = LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.1),
                Color(hex: projectColor)?.opacity(0.1) ?? Color.blue.opacity(0.1),
                Color.white.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        ZStack {
            gradient
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: cardSpacing) {
                        Text(name)
                            .font(.largeTitle)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 8)
                        ForEach($groups) { $group in
                            IndicatorCardView(
                                group: $group,
                                notePopoverId: $notePopoverId,
                                showInputAlert: $showInputAlert,
                                inputAlertMessage: $inputAlertMessage,
                                lastValidValues: $lastValidValues,
                                focusedField: focusedField,
                                onAutoCalculate: onAutoCalculate,
                                projectColor: projectColor
                            )
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: 600, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("设计指标")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Spacer()
                Button {
                    exportCSV()
                } label: {
                    Label("导出CSV", systemImage: "square.and.arrow.up")
                }
                Button {
                    importCSV()
                } label: {
                    Label("导入CSV", systemImage: "square.and.arrow.down")
                }
            }
        }
        .alert(alertMessage, isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        }
        .onAppear { loadData() }
        .onChange(of: projectId) { _, _ in loadData() }
    }

    // 仅用于外部获取当前数据
    func getCurrentData() -> [DesignIndicatorGroup] {
        return groups
    }
    // 加载数据
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "DesignIndicatorData-\(projectId.uuidString)"),
           let savedGroups = try? JSONDecoder().decode([DesignIndicatorGroup].self, from: data) {
            groups = savedGroups
        }
    }
    //保存数据到本地
    private func saveData() {
        if let data = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(data, forKey: "DesignIndicatorData-\(projectId.uuidString)")
        }
        onAnyValueChange?()
    }
    // 默认分组静态方法
    static func defaultGroups() -> [DesignIndicatorGroup] {
        return [
            // 一、规划指标
            DesignIndicatorGroup(
                groupName: "一、规划指标",
                indicators: [
                    .init(name: "1. 用地红线面积", value: "", unit: "㎡", note: ""),
                    .init(name: "2. 计容建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: "3. 容积率", value: "", unit: "/", note: ""),
                    .init(name: "4. 建筑密度", value: "", unit: "%", note: ""),
                ]
            ),
            // 二、建设面积指标
            DesignIndicatorGroup(
                groupName: "二、建设面积指标",
                indicators: [
                    .init(name: "1. 总建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "其中:", value: "", unit: "", note: ""),
                    .init(name: " 地上建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: " 地下建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "其中:", value: "", unit: "", note: ""),
                    .init(name: " 计容建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: " 不计容建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "其中:", value: "", unit: "", note: ""),
                    .init(name: " 住宅建筑面积", value: "", unit: "㎡", note: "地上+地下建筑面积，可售"),
                    .init(name: " 配套及其他", value: "", unit: "㎡", note: ""),
                ]
            ),
            
            // 三、住宅面积指标
            DesignIndicatorGroup(
                groupName: "三、住宅面积指标",
                indicators: [
                    .init(name: "1. 住宅套内建筑面积", value: "", unit: "㎡", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "2. 住宅计容面积", value: "", unit: "㎡", note: ""),
                    .init(name: "其中:", value: "", unit: "", note: ""),
                    .init(name: " 高层", value: "", unit: "㎡", note: ""),
                    .init(name: " 洋房", value: "", unit: "㎡", note: ""),
                    .init(name: " 低层住宅（别墅）", value: "", unit: "㎡", note: ""),
                    .init(name: " 低层住宅（平层）", value: "", unit: "㎡", note: ""),
                    .init(name: " 保障房", value: "", unit: "㎡", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "3. 住宅不计容面积（地上）", value: "", unit: "㎡", note: ""),
                    .init(name: "其中:", value: "", unit: "", note: ""),
                    .init(name: " 政策奖励面积", value: "", unit: "㎡", note: "屋顶不超过标准层面积1/8的出屋面楼梯间及设备机房，分摊"),
                    .init(name: " 其他", value: "", unit: "㎡", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "4. 住宅不计容面积（地下）", value: "", unit: "㎡", note: ""),
                    .init(name: "其中:", value: "", unit: "", note: ""),
                    .init(name: " 住宅共有部位", value: "", unit: "㎡", note: ""),
                    .init(name: " 住宅独用面积", value: "", unit: "㎡", note: ""),
                ]
            ),
            
            // 四、开发效率指标
            DesignIndicatorGroup(
                groupName: "四、开发效率指标",
                indicators: [
                    .init(name: "1. 开发效率", value: "", unit: "%", note: "计容面积/总建筑面积"),
                    .init(name: "2. 住宅可售比", value: "", unit: "%", note: "住宅建筑面积/总建筑面积"),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "3. 总户数", value: "", unit: "户", note: ""),
                    .init(name: "其中：", value: "", unit: "", note: ""),
                    .init(name: " 高层户数", value: "", unit: "户", note: ""),
                    .init(name: " 洋房户数", value: "", unit: "户", note: ""),
                    .init(name: " 低层住宅（别墅）户数", value: "", unit: "户", note: ""),
                    .init(name: " 低层住宅（平层）户数", value: "", unit: "户", note: ""),
                    .init(name: " 保障房户数", value: "", unit: "户", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "4. 户均建筑面积", value: "", unit: "㎡/户", note: "住宅建筑面积/总户数"),
                    .init(name: "5. 小户型面积", value: "", unit: "㎡", note: ""),
                    .init(name: "6. 小户型面积比", value: "", unit: "%", note: "小户型面积/ 住宅建筑面积"),
                ]
            ),
            // 五、停车指标
            DesignIndicatorGroup(
                groupName: "五、停车指标",
                indicators: [
                    .init(name: "1. 机动车位数量（报批）", value: "", unit: "辆", note: "按规范折算后"),
                    .init(name: "其中：", value: "", unit: "", note: ""),
                    .init(name: " 地上车位数量", value: "", unit: "辆", note: ""),
                    .init(name: " 地下车位数量", value: "", unit: "辆", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "2. 可销售车位数（按自然数统计）", value: "", unit: "辆", note: ""),
                    .init(name: "其中：", value: "", unit: "", note: ""),
                    .init(name: " 普通车位", value: "", unit: "辆", note: ""),
                    .init(name: " 无障碍车位", value: "", unit: "辆", note: ""),
                    .init(name: " 子母车位", value: "", unit: "辆", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "3. 不可销售车位数（按自然数统计）", value: "", unit: "辆", note: ""),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "4. 户均车位数", value: "", unit: "辆/户", note: "机动车位数量/总户数"),
                    .init(name: "5. 地下室单车位指标", value: "", unit: "㎡/辆", note: "地下建筑面积/地下车位数量"),
                ]
            ),
            // 六、配套指标
            DesignIndicatorGroup(
                groupName: "六、配套指标",
                indicators: [
                    .init(name: "1. 配套建筑面积", value: "", unit: "㎡", note: "含计容和不计容配套面积"),
                    .init(name: "__divider__", value: "", unit: "", note: ""),
                    .init(name: "其中：（按产权区分）", value: "", unit: "", note: ""),
                    .init(name: " 开发商产权配套面积", value: "", unit: "㎡", note: "物业用房、业委会、门卫、地库出入口"),
                    .init(name: " 政府产权配套面积", value: "", unit: "㎡", note: "配电房、变电站、门卫、垃圾房、架空层出入口、居委会、养老服务点、生活垃圾站、浴室锅炉房、变电站、及其他"),
                ]
            ),
        ]
    }

    // MARK: - CSV 导出
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.nameFieldStringValue = name + ".csv"
        panel.begin { result in
            if result == .OK, let url = panel.url {
                let indicators = groupsToIndicatorValues(groups: groups, tabName: name)
                let csvString = indicatorValuesToCSV(indicators)
                do {
                    try csvString.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    alertMessage = "导出失败：\(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    // MARK: - CSV 导入
    private func importCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { result in
            if result == .OK, let url = panel.url {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    let indicators = csvToIndicatorValues(content, tabName: name)
                    var newGroups = groups
                    updateGroupsFromIndicatorValuesWithNote(groups: &newGroups, indicators: indicators, tabName: name)
                    groups = newGroups
                    saveData()
                } catch {
                    alertMessage = "导入失败：\(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    // MARK: - IndicatorValue <-> CSV
    private func indicatorValuesToCSV(_ indicators: [IndicatorValue]) -> String {
        var lines = ["分组,指标,数值,单位,备注"]
        for v in indicators {
            // 查找unit和note
            let group = groups.first(where: { $0.groupName == v.groupName })
            let indicator = group?.indicators.first(where: { $0.name == v.indicatorName })
            let unit = indicator?.unit ?? ""
            let note = indicator?.note ?? ""
            let line = "\(v.groupName),\(v.indicatorName),\(v.value),\(unit),\(note)"
            lines.append(line)
        }
        return lines.joined(separator: "\n")
    }
    private func csvToIndicatorValues(_ csv: String, tabName: String) -> [IndicatorValueExt] {
        let lines = csv.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else { return [] }
        var result: [IndicatorValueExt] = []
        for line in lines.dropFirst() {
            let parts = line.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
            if parts.count >= 3 {
                let group = parts[0]
                let indicator = parts[1]
                let value = parts[2]
                let note = parts.count >= 5 ? parts[4] : ""
                result.append(IndicatorValueExt(tabName: tabName, groupName: group, indicatorName: indicator, value: value, note: note))
            }
        }
        return result
    }
    // 扩展结构体用于导入
    private struct IndicatorValueExt {
        let tabName: String
        let groupName: String
        let indicatorName: String
        let value: String
        let note: String
    }
    // 修改updateGroupsFromIndicatorValues逻辑，支持更新备注，重命名为updateGroupsFromIndicatorValuesWithNote
    private func updateGroupsFromIndicatorValuesWithNote(groups: inout [DesignIndicatorGroup], indicators: [IndicatorValueExt], tabName: String) {
        for i in 0..<groups.count {
            for j in 0..<groups[i].indicators.count {
                if let new = indicators.first(where: { $0.tabName == tabName && $0.groupName == groups[i].groupName && $0.indicatorName == groups[i].indicators[j].name }) {
                    groups[i].indicators[j].value = new.value
                    if !new.note.isEmpty { groups[i].indicators[j].note = new.note }
                }
            }
        }
    }
}

// 辅助方法：DesignIndicatorGroup <-> IndicatorValue 互转
func groupsToIndicatorValues(groups: [DesignIndicatorGroup], tabName: String) -> [IndicatorValue] {
    var result: [IndicatorValue] = []
    for group in groups {
        for indicator in group.indicators {
            result.append(IndicatorValue(tabName: tabName, groupName: group.groupName, indicatorName: indicator.name, value: indicator.value))
        }
    }
    return result
}

// 指标Tab视图
struct DesignIndicatorTabsView: View {
    let projectId: UUID
    let projectName: String
    let projectColor: String
    @State private var tabs: [DesignIndicatorTab] = []
    @State private var selectedTabId: UUID?
    @State private var newTabCount = 1
    @State private var showEditSheet = false
    @State private var showNewTabAlert = false
    @State private var newTabName = ""
    @State private var newTabNameError = ""
    enum IndicatorTabViewType: String, CaseIterable, Identifiable {
        case detail = "指标详情"
        case compare = "指标对比"
        var id: String { self.rawValue }
    }
    @State private var currentViewType: IndicatorTabViewType = .detail
    // 卡片输入相关状态
    @State private var notePopoverId: UUID?
    @State private var showInputAlert = false
    @State private var inputAlertMessage = ""
    @State private var lastValidValues: [UUID: String] = [:]
    @FocusState private var focusedField: UUID?
    // 卡片高度自适应
    @State private var rowHeights: [Int: CGFloat] = [:]
    let minCardWidth: CGFloat = 340
    let cardSpacing: CGFloat = 24
    let horizontalPadding: CGFloat = 32

    var body: some View {
        VStack(spacing: 0) {
            headerView
            mainContentView
        }
        .onAppear {
            loadTabs()
        }
        .onChange(of: projectId) { _, newValue in
            loadTabs()
        }
        .onChange(of: tabs) { _, _ in
            saveTabs()
        }
        .toolbar { toolbarContent }
        .sheet(isPresented: $showEditSheet) { editSheetView }
        .alert("请输入新视图名称", isPresented: $showNewTabAlert, actions: { alertActions }, message: { alertMessage })
        .alert(inputAlertMessage, isPresented: $showInputAlert) {
            Button("确定", role: .cancel) {}
        }
    }

    // 拆分：顶部项目名
    private var headerView: some View {
        Text(projectName)
            .font(.title3)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 32)
            .padding(.top, 8)
    }

    // 拆分：主内容区
    @ViewBuilder
    private var mainContentView: some View {
        if currentViewType == .detail {
            if let idx = tabs.firstIndex(where: { $0.id == selectedTabId }) {
                DesignIndicatorView(
                    projectId: projectId,
                    name: tabs[idx].name,
                    groups: $tabs[idx].indicatorGroups,
                    projectColor: projectColor,
                    notePopoverId: $notePopoverId,
                    showInputAlert: $showInputAlert,
                    inputAlertMessage: $inputAlertMessage,
                    lastValidValues: $lastValidValues,
                    focusedField: $focusedField,
                    onAutoCalculate: {
                        var indicators = groupsToIndicatorValues(groups: tabs[idx].indicatorGroups, tabName: tabs[idx].name)
                        IndicatorCalculator.calculateAll(
                            indicators: &indicators,
                            tab: tabs[idx].name,
                            formulas: IndicatorCalculator.defaultFormulas(tab: tabs[idx].name)
                        )
                        updateGroupsFromIndicatorValues(groups: &tabs[idx].indicatorGroups, indicators: indicators, tabName: tabs[idx].name)
                    }
                )
            } else {
                Text("请先新增或选择一个指标视图")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else if currentViewType == .compare {
            CompareView(tabs: tabs, projectColor: projectColor)
        }
    }

    // 拆分：工具栏
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            HStack(spacing: 0) {
                ForEach(IndicatorTabViewType.allCases) { type in
                    Button(action: {
                        currentViewType = type
                    }) {
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 110, height: 24)
                            .background(currentViewType == type ? Color.blue : Color.clear)
                            .foregroundColor(currentViewType == type ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .cornerRadius(12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gray.opacity(0.12))
            )
            .frame(width: 220)
            if currentViewType == .detail {
                Picker("选择指标视图", selection: $selectedTabId) {
                    ForEach(tabs) { tab in
                        Text(tab.name).tag(tab.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 200)
                Button {
                    newTabName = ""
                    showNewTabAlert = true
                } label: {
                    Label("新建", systemImage: "plus")
                }
                Button {
                    showEditSheet = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
            }
        }
    }

    // 拆分：编辑sheet
    private var editSheetView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("管理指标视图")
                .font(.headline)
            ForEach($tabs) { $tab in
                HStack {
                    TextField("名称", text: $tab.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 200)
                    Spacer()
                    Button(action: {
                        if let idx = tabs.firstIndex(where: { $0.id == tab.id }), idx > 0 {
                            tabs.swapAt(idx, idx - 1)
                            saveTabs()
                        }
                    }) {
                        Image(systemName: "arrow.up")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(tabs.first?.id == tab.id)
                    Button(action: {
                        if let idx = tabs.firstIndex(where: { $0.id == tab.id }), idx < tabs.count - 1 {
                            tabs.swapAt(idx, idx + 1)
                            saveTabs()
                        }
                    }) {
                        Image(systemName: "arrow.down")
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(tabs.last?.id == tab.id)
                    Button {
                        let id = tab.id
                        tabs.removeAll { $0.id == id }
                        if selectedTabId == id {
                            selectedTabId = tabs.first?.id
                        }
                        saveTabs()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(tabs.count <= 1)
                }
            }
            HStack {
                Spacer()
                Button("完成") {
                    showEditSheet = false
                    saveTabs()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400)
    }

    // 拆分：新建Tab弹窗actions
    @ViewBuilder
    private var alertActions: some View {
        TextField("名称", text: $newTabName)
            .onChange(of: newTabName) { _, newValue in
                let name = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if name.isEmpty {
                    newTabNameError = "名称不能为空"
                } else if tabs.contains(where: { $0.name == name }) {
                    newTabNameError = "名称已存在，请输入其他名称"
                } else {
                    newTabNameError = ""
                }
            }
        Button("确定") {
            let name = newTabName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty && !tabs.contains(where: { $0.name == name }) {
                let newTab = DesignIndicatorTab(id: UUID(), name: name, indicatorGroups: DesignIndicatorView.defaultGroups())
                tabs.append(newTab)
                selectedTabId = newTab.id
                saveTabs()
                newTabCount += 1
            }
        }
        .disabled(newTabName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || tabs.contains(where: { $0.name == newTabName.trimmingCharacters(in: .whitespacesAndNewlines) }))
        Button("取消", role: .cancel) {}
    }

    // 拆分：新建Tab弹窗message
    @ViewBuilder
    private var alertMessage: some View {
        if !newTabNameError.isEmpty {
            Text(newTabNameError)
        } else {
            Text("新建一个指标视图")
        }
    }

    // 加载/保存
    func loadTabs() {
        if let data = UserDefaults.standard.data(forKey: "DesignIndicatorTabs-\(projectId.uuidString)"),
           let savedTabs = try? JSONDecoder().decode([DesignIndicatorTab].self, from: data) {
            tabs = savedTabs
            selectedTabId = tabs.first?.id
        } else {
            tabs = []
            selectedTabId = nil
        }
    }
    func saveTabs() {
        if let data = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(data, forKey: "DesignIndicatorTabs-\(projectId.uuidString)")
        }
    }
}

// 保留全局方法
func updateGroupsFromIndicatorValues(groups: inout [DesignIndicatorGroup], indicators: [IndicatorValue], tabName: String) {
    for i in 0..<groups.count {
        for j in 0..<groups[i].indicators.count {
            if let newValue = indicators.first(where: { $0.tabName == tabName && $0.groupName == groups[i].groupName && $0.indicatorName == groups[i].indicators[j].name })?.value {
                groups[i].indicators[j].value = newValue
            }
        }
    }
}

