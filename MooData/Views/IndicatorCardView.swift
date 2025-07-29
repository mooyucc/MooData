import SwiftUI

// 设计指标基本字段
struct DesignIndicator: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var value: String
    var unit: String
    var note: String
    init(id: UUID = UUID(), name: String, value: String, unit: String, note: String) {
        self.id = id
        self.name = name
        self.value = value
        self.unit = unit
        self.note = note
    }
}

// 设计指标卡片结构
struct DesignIndicatorGroup: Identifiable, Codable, Equatable {
    var id: UUID
    var groupName: String
    var indicators: [DesignIndicator]
    init(id: UUID = UUID(), groupName: String, indicators: [DesignIndicator]) {
        self.id = id
        self.groupName = groupName
        self.indicators = indicators
    }
}

// 卡片高度 PreferenceKey自适应高度
struct CardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { max($0, $1) })
    }
}

struct IndicatorCardView: View {
    @Binding var group: DesignIndicatorGroup
    @Binding var notePopoverId: UUID?
    @Binding var showInputAlert: Bool
    @Binding var inputAlertMessage: String
    @Binding var lastValidValues: [UUID: String]
    @FocusState.Binding var focusedField: UUID?
    var onAutoCalculate: () -> Void
    let projectColor: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(group.groupName)
                .font(.title2)
                .bold()
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.darkGray))
                )
                .foregroundColor(Color.white.opacity(0.95))
            VStack(alignment: .leading, spacing: 8) {
                ForEach($group.indicators) { $indicator in
                    if indicator.name == "__divider__" {
                        Spacer().frame(height: 12)
                    } else if indicator.value.isEmpty && indicator.unit.isEmpty && indicator.note.isEmpty {
                        Text(indicator.name)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        HStack(spacing: 8) {
                            let indent: CGFloat = indicator.name.hasPrefix(" ") ? 16 : 0
                            Text(indicator.name)
                                .frame(minWidth: 120 - indent, maxWidth: 240, alignment: .leading)
                                .padding(.leading, indent)
                            if IndicatorCardView.isReadOnlyFieldStatic(group: group, indicator: indicator) {
                                TextField("数值", text: .constant(indicator.value.isEmpty ? "0" : indicator.value))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minWidth: 80, maxWidth: .infinity)
                                    .allowsHitTesting(false)
                                    .foregroundColor(.primary)
                            } else {
                                TextField("数值", text: Binding(
                                    get: { indicator.value },
                                    set: { newValue in
                                        let filtered = newValue.replacingOccurrences(of: ",", with: ".")
                                        if filtered.isEmpty {
                                            indicator.value = ""
                                            lastValidValues[indicator.id] = ""
                                        } else if Double(filtered) != nil {
                                            indicator.value = filtered
                                            lastValidValues[indicator.id] = filtered
                                        } else {
                                            inputAlertMessage = "请输入数字"
                                            showInputAlert = true
                                            indicator.value = lastValidValues[indicator.id] ?? ""
                                        }
                                    }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(minWidth: 80, maxWidth: .infinity)
                                .focused($focusedField, equals: indicator.id)
                                .onAppear {
                                    lastValidValues[indicator.id] = indicator.value
                                }
                                .onSubmit {
                                    onAutoCalculate()
                                    focusedField = nil
                                }
                                .onChange(of: focusedField) { _, newValue in
                                    if newValue != indicator.id {
                                        onAutoCalculate()
                                    }
                                }
                                .foregroundColor(.primary)
                                .onChange(of: indicator.value) { _, _ in
                                    onAutoCalculate()
                                }
                            }
                            Text(indicator.unit)
                                .font(.caption)
                            Button {
                                notePopoverId = indicator.id
                            } label: {
                                Image(systemName: indicator.note.isEmpty ? "note.text" : "note.text.badge.plus")
                                    .foregroundColor(indicator.note.isEmpty ? .secondary : .accentColor)
                                    .help(indicator.note.isEmpty ? "添加备注" : "查看/编辑备注")
                            }
                            .buttonStyle(PlainButtonStyle())
                            .popover(isPresented: Binding(
                                get: { notePopoverId == indicator.id },
                                set: { if !$0 { notePopoverId = nil } }
                            )) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("备注")
                                        .font(.headline)
                                    TextEditor(text: $indicator.note)
                                        .frame(width: 220, height: 80)
                                        .padding(4)
                                    HStack {
                                        Spacer()
                                        Button("完成") {
                                            notePopoverId = nil
                                            onAutoCalculate()
                                        }
                                        .keyboardShortcut(.defaultAction)
                                    }
                                }
                                .padding()
                                .frame(width: 240)
                            }
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.textBackgroundColor))
        .cornerRadius(20)
        .shadow(color: .gray.opacity(0.15), radius: 6, x: 0, y: 2)
    }
    static func isReadOnlyFieldStatic(group: DesignIndicatorGroup, indicator: DesignIndicator) -> Bool {
        return (
            (indicator.name == "2. 住宅计容面积" && group.groupName == "三、住宅面积指标") ||
            (indicator.name == "1. 总建筑面积" && group.groupName == "二、建设面积指标") ||
            (indicator.name == "2. 计容建筑面积" && group.groupName == "一、规划指标") ||
            (indicator.name == "3. 住宅不计容面积（地上）" && group.groupName == "三、住宅面积指标") ||
            (indicator.name == "4. 住宅不计容面积（地下）" && group.groupName == "三、住宅面积指标") ||
            (indicator.name == "3. 总户数" && group.groupName == "四、开发效率指标") ||
            (indicator.name == "1. 机动车位数量（报批）" && group.groupName == "五、停车指标") ||
            (indicator.name == "2. 可销售车位数（按自然数统计）" && group.groupName == "五、停车指标") ||
            (indicator.name == "1. 配套建筑面积" && group.groupName == "六、配套指标") ||
            (indicator.name == "1. 开发效率" && group.groupName == "四、开发效率指标") ||
            (indicator.name == "2. 住宅可售比" && group.groupName == "四、开发效率指标") ||
            (indicator.name == "4. 户均建筑面积" && group.groupName == "四、开发效率指标") ||
            (indicator.name == "6. 小户型面积比" && group.groupName == "四、开发效率指标") ||
            (indicator.name == "4. 户均车位数" && group.groupName == "五、停车指标") ||
            (indicator.name == "5. 地下室单车位指标" && group.groupName == "五、停车指标")
        )
    }
} 