import SwiftUI

// MARK: - 同步滚动的NSScrollView封装
struct SyncedScrollView<Content: View>: NSViewRepresentable {
    @Binding var syncOffset: CGFloat
    let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        let hosting = NSHostingView(rootView: content())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = hosting
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.didScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        // 让内容宽度自适应
        NSLayoutConstraint.activate([
            hosting.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let hostingView = nsView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content()
        }
        // 只在外部同步时设置offset，避免死循环
        if abs(nsView.contentView.bounds.origin.y - syncOffset) > 1 {
            nsView.contentView.scroll(to: NSPoint(x: 0, y: syncOffset))
        }
    }

    class Coordinator: NSObject {
        var parent: SyncedScrollView
        var isSyncing = false

        init(_ parent: SyncedScrollView) {
            self.parent = parent
        }

        @objc func didScroll(_ notification: Notification) {
            guard let scrollView = notification.object as? NSClipView else { return }
            if !isSyncing {
                isSyncing = true
                DispatchQueue.main.async {
                    self.parent.syncOffset = scrollView.bounds.origin.y
                    self.isSyncing = false
                }
            }
        }
    }
}

// MARK: - 主CompareView
struct CompareView: View {
    let tabs: [DesignIndicatorTab]
    let projectColor: String
    @State private var selectedTabId1: UUID?
    @State private var selectedTabId2: UUID?

    var selectedTab1: DesignIndicatorTab? {
        tabs.first { $0.id == selectedTabId1 } ?? tabs.first
    }
    var selectedTab2: DesignIndicatorTab? {
        tabs.first { $0.id == selectedTabId2 } ?? tabs.first
    }

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
                HStack(alignment: .top, spacing: 8) {
                    // 第一列
                    VStack(alignment: .leading, spacing: 16) {
                        header(title: "对比指标1", selectedTabId: $selectedTabId1)
                        Group {
                            if let tab = selectedTab1 {
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(tab.indicatorGroups) { group in
                                        IndicatorGroupCard(group: group)
                                    }
                                }
                                .padding()
                            } else {
                                VStack {
                                    Text("暂无可用指标视图")
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(16)
                    .padding(4)
                    .padding(.leading, 8)
                    .padding(.bottom, 8)

                    // 第二列
                    VStack(alignment: .leading, spacing: 16) {
                        header(title: "对比指标2", selectedTabId: $selectedTabId2)
                        Group {
                            if let tab = selectedTab2 {
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(tab.indicatorGroups) { group in
                                        IndicatorGroupCard(group: group)
                                    }
                                }
                                .padding()
                            } else {
                                VStack {
                                    Text("暂无可用指标视图")
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(16)
                    .padding(4)
                    .padding(.bottom, 8)

                    // 第三列（对比结果）
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("差值（指标2-指标1）")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(NSColor.darkGray))
                                )
                            Spacer()
                        }
                        .padding(.horizontal)
                        Group {
                            if let tab1 = selectedTab1, let tab2 = selectedTab2 {
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(tab2.indicatorGroups) { group2 in
                                        let group1 = tab1.indicatorGroups.first(where: { $0.groupName == group2.groupName })
                                        CompareDiffGroupCard(group1: group1, group2: group2)
                                    }
                                }
                                .padding()
                            } else {
                                VStack {
                                    Text("暂无可用指标视图")
                                        .foregroundColor(.secondary)
                                        .padding()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(16)
                    .padding(4)
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .navigationTitle("对比")
        .onAppear {
            if selectedTabId1 == nil, let first = tabs.first?.id {
                selectedTabId1 = first
            }
            if selectedTabId2 == nil, let first = tabs.first?.id {
                selectedTabId2 = first
            }
        }
    }

    private func header(title: String, selectedTabId: Binding<UUID?>) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(NSColor.darkGray))
                )
            Spacer()
            Picker("", selection: selectedTabId) {
                ForEach(tabs) { tab in
                    Text(tab.name).tag(tab.id as UUID?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 200)
        }
        .padding(.horizontal)
    }
}

struct IndicatorGroupCard: View {
    let group: DesignIndicatorGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.groupName)
                .font(.headline)
                .padding(.bottom, 4)
            ForEach(group.indicators) { indicator in
                if indicator.name != "__divider__" && !indicator.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    HStack {
                        Text(indicator.name)
                            .frame(minWidth: 120, maxWidth: 240, alignment: .leading)
                        Spacer()
                        Text(indicator.value.isEmpty ? "-" : indicator.value)
                            .foregroundColor(.primary)
                        Text(indicator.unit)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.18), radius: 8, x: 0, y: 4)
    }
}

struct CompareDiffGroupCard: View {
    let group1: DesignIndicatorGroup?
    let group2: DesignIndicatorGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group2.groupName)
                .font(.headline)
                .padding(.bottom, 4)
            ForEach(group2.indicators) { indicator2 in
                if indicator2.name != "__divider__" && !indicator2.name.trimmingCharacters(in: .whitespaces).isEmpty {
                    HStack {
                        Text(indicator2.name)
                            .frame(minWidth: 120, maxWidth: 240, alignment: .leading)
                        Spacer()
                        let diff = diffNumber(for: indicator2)
                        Text(diffValue(for: indicator2))
                            .foregroundColor(diff == nil ? .blue : (diff! < 0 ? .red : .blue))
                        Text(indicator2.unit)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private func diffValue(for indicator2: DesignIndicator) -> String {
        guard let group1 = group1,
              let indicator1 = group1.indicators.first(where: { $0.name == indicator2.name }),
              let v2 = Double(indicator2.value),
              let v1 = Double(indicator1.value) else {
            // 只在tab2有，或无法转为数字
            return indicator2.value.isEmpty ? "-" : indicator2.value
        }
        let diff = v2 - v1
        // 保留两位小数
        return String(format: "%g", diff)
    }
    
    private func diffNumber(for indicator2: DesignIndicator) -> Double? {
        guard let group1 = group1,
              let indicator1 = group1.indicators.first(where: { $0.name == indicator2.name }),
              let v2 = Double(indicator2.value),
              let v1 = Double(indicator1.value) else {
            return nil
        }
        return v2 - v1
    }
}

struct CompareView_Previews: PreviewProvider {
    static var previews: some View {
        // 示例数据
        let indicator = DesignIndicator(name: "示例指标", value: "123", unit: "㎡", note: "")
        let group = DesignIndicatorGroup(groupName: "示例分组", indicators: [indicator])
        let tab = DesignIndicatorTab(id: UUID(), name: "Tab1", indicatorGroups: [group])
        CompareView(tabs: [tab], projectColor: "#007AFF")
    }
} 
