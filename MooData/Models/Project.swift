import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ProjectIdentifier: Codable, Transferable {
    let id: UUID
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

extension UTType {
    static var projectIdentifier: UTType {
        UTType(exportedAs: "com.mc-pro.project-identifier")
    }
}

struct ProjectGroup: Identifiable, Codable {
    var id: UUID
    var name: String
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

struct Project: Identifiable, Codable {
    var id: UUID
    var name: String
    var groupId: UUID?  // 项目所属的组ID
    var tasks: [Task]
    var createdAt: Date
    var color: String // 项目颜色，存储为十六进制字符串
    var order: Int // 项目在组内的排序顺序
    var notes: String? // 项目备注
    
    init(id: UUID = UUID(), name: String, groupId: UUID? = nil, tasks: [Task] = [], createdAt: Date = Date(), color: String = "#007AFF", order: Int = 0, notes: String? = nil) {
        self.id = id
        self.name = name
        self.groupId = groupId
        self.tasks = tasks
        self.createdAt = createdAt
        self.color = color
        self.order = order
        self.notes = notes
    }
}

struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var dueDate: Date
    var importance: TaskImportance
    var isCompleted: Bool
    var taskNumber: Int {
        if let numberEndIndex = title.firstIndex(of: ".") {
            if let number = Int(title[..<numberEndIndex]) {
                return number
            }
        }
        return 0
    }
    
    init(id: UUID = UUID(), title: String, dueDate: Date, importance: TaskImportance, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.importance = importance
        self.isCompleted = isCompleted
    }
}

enum TaskImportance: String, Codable, CaseIterable {
    case important = "重要"
    case secondary = "次要"
    case normal = "一般"
    
    var localizedName: String {
        switch self {
        case .important: return "重要"
        case .secondary: return "次要"
        case .normal: return "一般"
        }
    }
} 