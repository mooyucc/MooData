import Foundation

struct ProjectData: Codable {
    let projects: [Project]
    let groups: [ProjectGroup]
    var designIndicatorTabs: [DesignIndicatorTab]?
    
    struct Project: Codable {
        let id: UUID
        let name: String
        let color: String
        let groupId: UUID?
        let notes: String?
        let tasks: [Task]
        let order: Int
        
        struct Task: Codable {
            let id: UUID
            let title: String
            let dueDate: Date
            let importance: TaskImportance
            let isCompleted: Bool
            
            init(id: UUID, title: String, dueDate: Date, importance: TaskImportance, isCompleted: Bool) {
                self.id = id
                self.title = title
                self.dueDate = dueDate
                self.importance = importance
                self.isCompleted = isCompleted
            }
        }
        
        init(id: UUID, name: String, color: String, groupId: UUID?, notes: String?, tasks: [Task], order: Int) {
            self.id = id
            self.name = name
            self.color = color
            self.groupId = groupId
            self.notes = notes
            self.tasks = tasks
            self.order = order
        }
        
        // 静态工厂方法
        static func from(project: MooData.Project) -> ProjectData.Project {
            return ProjectData.Project(
                id: project.id,
                name: project.name,
                color: project.color,
                groupId: project.groupId,
                notes: project.notes,
                tasks: project.tasks.map { task in
                    Task(
                        id: task.id,
                        title: task.title,
                        dueDate: task.dueDate,
                        importance: task.importance,
                        isCompleted: task.isCompleted
                    )
                },
                order: project.order
            )
        }
        
        // 自定义解码逻辑
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // 解码必需字段
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            color = try container.decode(String.self, forKey: .color)
            groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            tasks = try container.decode([Task].self, forKey: .tasks)
            
            // 尝试解码 order 字段，如果不存在则使用默认值 0
            order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        }
    }
    
    struct ProjectGroup: Codable {
        let id: UUID
        let name: String
    }
} 
