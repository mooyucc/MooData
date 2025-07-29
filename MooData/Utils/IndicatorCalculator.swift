import Foundation
import SwiftUI

// 统一指标数据结构
struct IndicatorValue {
    let tabName: String
    let groupName: String
    let indicatorName: String
    var value: String
}

// 唯一键结构
struct IndicatorKey: Hashable {
    let tab: String
    let group: String
    let name: String
}

// 公式操作类型
enum FormulaOp {
    case add, sub, mul, div, custom(([Double]) -> Double)
}

// 公式结构
struct Formula {
    let output: IndicatorKey
    let inputs: [IndicatorKey]
    let op: FormulaOp
    let postProcess: ((Double) -> String)? // 比如乘100转百分比
}

struct IndicatorCalculator {
    // 将 [IndicatorValue] 转为 [IndicatorKey: String]
    static func toDict(_ indicators: [IndicatorValue]) -> [IndicatorKey: String] {
        var dict = [IndicatorKey: String]()
        for v in indicators {
            dict[IndicatorKey(tab: v.tabName, group: v.groupName, name: v.indicatorName)] = v.value
        }
        return dict
    }
    // 统一计算函数
    static func calculateAll(indicators: inout [IndicatorValue], tab: String, formulas: [Formula]) {
        var dict = toDict(indicators)
        for formula in formulas {
            // 只计算当前 tab
            let inputKeys = formula.inputs.map { IndicatorKey(tab: tab, group: $0.group, name: $0.name) }
            let values: [Double]
            switch formula.op {
            case .add:
                // 加法时，未填写的项按0处理
                values = inputKeys.map { Double(dict[$0] ?? "0") ?? 0 }
            default:
                // 其它操作仍然要求全部输入项都填写
                let tmp = inputKeys.compactMap { dict[$0] }.compactMap { Double($0) }
                guard tmp.count == formula.inputs.count else {
                    // 输入不全，清空结果
                    if let idx = indicators.firstIndex(where: { $0.tabName == tab && $0.groupName == formula.output.group && $0.indicatorName == formula.output.name }) {
                        indicators[idx].value = ""
                    }
                    continue
                }
                values = tmp
            }
            let result: Double
            switch formula.op {
            case .add: result = values.reduce(0, +)
            case .sub: result = values.dropFirst().reduce(values.first ?? 0, -)
            case .mul: result = values.reduce(1, *)
            case .div: result = values.dropFirst().reduce(values.first ?? 0, /)
            case .custom(let f): result = f(values)
            }
            let outputValue = formula.postProcess?(result) ?? String(format: "%.2f", result)
            if let idx = indicators.firstIndex(where: { $0.tabName == tab && $0.groupName == formula.output.group && $0.indicatorName == formula.output.name }) {
                indicators[idx].value = outputValue
            }
        }
    }
    // 公式配置示例
    static func defaultFormulas(tab: String) -> [Formula] {
        return [
            // 开发效率 = 计容面积 / 总建筑面积 * 100
            Formula(
                output: IndicatorKey(tab: tab, group: "四、开发效率指标", name: "1. 开发效率"),
                inputs: [
                    IndicatorKey(tab: tab, group: "一、规划指标", name: "2. 计容建筑面积"),
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: "1. 总建筑面积")
                ],
                op: .div,
                postProcess: { String(format: "%.2f", $0 * 100) }
            ),
            // 住宅可售比 = 住宅建筑面积 / 总建筑面积 * 100
            Formula(
                output: IndicatorKey(tab: tab, group: "四、开发效率指标", name: "2. 住宅可售比"),
                inputs: [
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: " 住宅建筑面积"),
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: "1. 总建筑面积")
                ],
                op: .div,
                postProcess: { String(format: "%.2f", $0 * 100) }
            ),
            // 户均建筑面积 = 住宅建筑面积 / 总户数
            Formula(
                output: IndicatorKey(tab: tab, group: "四、开发效率指标", name: "4. 户均建筑面积"),
                inputs: [
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: " 住宅建筑面积"),
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: "3. 总户数")
                ],
                op: .div,
                postProcess: nil
            ),
            // 小户型面积比 = 小户型面积 / 住宅建筑面积 * 100
            Formula(
                output: IndicatorKey(tab: tab, group: "四、开发效率指标", name: "6. 小户型面积比"),
                inputs: [
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: "5. 小户型面积"),
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: " 住宅建筑面积")
                ],
                op: .div,
                postProcess: { String(format: "%.2f", $0 * 100) }
            ),
            // 户均车位数 = 机动车位数量（报批）/ 总户数
            Formula(
                output: IndicatorKey(tab: tab, group: "五、停车指标", name: "4. 户均车位数"),
                inputs: [
                    IndicatorKey(tab: tab, group: "五、停车指标", name: "1. 机动车位数量（报批）"),
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: "3. 总户数")
                ],
                op: .div,
                postProcess: nil
            ),
            // 地下室单车位指标 = 地下建筑面积 / 地下车位数量
            Formula(
                output: IndicatorKey(tab: tab, group: "五、停车指标", name: "5. 地下室单车位指标"),
                inputs: [
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: " 地下建筑面积"),
                    IndicatorKey(tab: tab, group: "五、停车指标", name: " 地下车位数量")
                ],
                op: .div,
                postProcess: nil
            ),
            // 机动车位数量（报批）=地上车位数量+地下车位数量
            Formula(
                output: IndicatorKey(tab: tab, group: "五、停车指标", name: "1. 机动车位数量（报批）"),
                inputs: [
                    IndicatorKey(tab: tab, group: "五、停车指标", name: " 地上车位数量"),
                    IndicatorKey(tab: tab, group: "五、停车指标", name: " 地下车位数量")
                ],
                op: .add,
                postProcess: nil
            ),
            // 组内自动计算举例：计容建筑面积 = 用地红线面积 * 容积率
            Formula(
                output: IndicatorKey(tab: tab, group: "一、规划指标", name: "2. 计容建筑面积"),
                inputs: [
                    IndicatorKey(tab: tab, group: "一、规划指标", name: "1. 用地红线面积"),
                    IndicatorKey(tab: tab, group: "一、规划指标", name: "3. 容积率")
                ],
                op: .mul,
                postProcess: nil
            ),
            // 总建筑面积 = 地上建筑面积 + 地下建筑面积
            Formula(
                output: IndicatorKey(tab: tab, group: "二、建设面积指标", name: "1. 总建筑面积"),
                inputs: [
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: " 地上建筑面积"),
                    IndicatorKey(tab: tab, group: "二、建设面积指标", name: " 地下建筑面积")
                ],
                op: .add,
                postProcess: nil
            ),
            // 住宅计容面积 = 高层+洋房+低层住宅（别墅）+低层住宅（平层）+保障房
            Formula(
                output: IndicatorKey(tab: tab, group: "三、住宅面积指标", name: "2. 住宅计容面积"),
                inputs: [
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 高层"),
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 洋房"),
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 低层住宅（别墅）"),
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 低层住宅（平层）"),
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 保障房")
                ],
                op: .add,
                postProcess: nil
            ),
            // 住宅不计容面积（地上）=政策奖励面积（不计容）+其他
            Formula(
                output: IndicatorKey(tab: tab, group: "三、住宅面积指标", name: "3. 住宅不计容面积（地上）"),
                inputs: [
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 政策奖励面积"),
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 其他")
                ],
                op: .add,
                postProcess: nil
            ),
            // 住宅不计容面积（地下）=住宅 共有部位+住宅 独用面积
            Formula(
                output: IndicatorKey(tab: tab, group: "三、住宅面积指标", name: "4. 住宅不计容面积（地下）"),
                inputs: [
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 住宅共有部位"),
                    IndicatorKey(tab: tab, group: "三、住宅面积指标", name: " 住宅独用面积")
                ],
                op: .add,
                postProcess: nil
            ),
            // 总户数=高层户数+多层户数+低层户数+保障房户数
            Formula(
                output: IndicatorKey(tab: tab, group: "四、开发效率指标", name: "3. 总户数"),
                inputs: [
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: " 高层户数"),
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: " 洋房户数"),
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: " 低层住宅（别墅）户数"),
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: " 低层住宅（平层）户数"),
                    IndicatorKey(tab: tab, group: "四、开发效率指标", name: " 保障房户数")
                ],
                op: .add,
                postProcess: nil
            ),
            // 可销售车位数（按自然数统计）=普通车位+无障碍车位+子母车位
            Formula(
                output: IndicatorKey(tab: tab, group: "五、停车指标", name: "2. 可销售车位数（按自然数统计）"),
                inputs: [
                    IndicatorKey(tab: tab, group: "五、停车指标", name: " 普通车位"),
                    IndicatorKey(tab: tab, group: "五、停车指标", name: " 无障碍车位"),
                    IndicatorKey(tab: tab, group: "五、停车指标", name: " 子母车位")
                ],
                op: .add,
                postProcess: nil
            ),
            // 配套建筑面积= 开发商产权配套面积+ 政府产权配套面积
            Formula(
                output: IndicatorKey(tab: tab, group: "六、配套指标", name: "1. 配套建筑面积"),
                inputs: [
                    IndicatorKey(tab: tab, group: "六、配套指标", name: " 开发商产权配套面积"),
                    IndicatorKey(tab: tab, group: "六、配套指标", name: " 政府产权配套面积")
                ],
                op: .add,
                postProcess: nil
            ),
            // ... 其它公式可继续补充
        ]
    }
} 
