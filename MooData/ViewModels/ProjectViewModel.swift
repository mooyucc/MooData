import Foundation
import SwiftUI
import AppKit

// NSColor扩展，用于转换颜色为十六进制字符串
extension NSColor {
    func toHexString() -> String? {
        guard let rgbColor = usingColorSpace(.sRGB) else {
            return nil
        }
        
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

class ProjectViewModel: ObservableObject {
    @Published var groups: [ProjectGroup] = []
    @Published var projects: [Project] = []
    
    init() {
        loadData()
    }
    
    //添加组
    func addGroup(name: String) {
        let group = ProjectGroup(name: name)
        groups.append(group)
        saveData()
    }
    
    //更新组名称
    func updateGroupName(_ group: ProjectGroup, newName: String) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index].name = newName
            saveData()
        }
    }
    
    //删除组
    func deleteGroup(_ group: ProjectGroup) {
        // 将该组中的项目移动到未分组
        for (index, project) in projects.enumerated() where project.groupId == group.id {
            projects[index].groupId = nil
        }
        
        // 删除组
        groups.removeAll { $0.id == group.id }
        saveData()
    }
    
    //添加项目
    func addProject(name: String, groupId: UUID? = nil, color: String? = nil) {
        // 如果没有指定颜色，则使用默认颜色集合中的颜色
        let projectColor: String
        if let color = color {
            projectColor = color
        } else {
            // 从颜色集合中获取下一个颜色
            projectColor = getNextProjectColor()
        }
        
        // 计算新项目的顺序
        var order = 0
        if let groupId = groupId {
            // 如果有分组，则新项目的顺序为该分组中最大顺序号+1
            let projectsInSameGroup = projectsInGroup(groupId)
            if !projectsInSameGroup.isEmpty {
                order = projectsInSameGroup.map { $0.order }.max() ?? 0
                order += 1
            }
        } else {
            // 如果没有分组，则顺序为未分组项目中最大顺序号+1
            let ungrouped = ungroupedProjects()
            if !ungrouped.isEmpty {
                order = ungrouped.map { $0.order }.max() ?? 0
                order += 1
            }
        }
        
        let project = Project(name: name, groupId: groupId, color: projectColor, order: order)
        projects.append(project)
        saveData()
    }
    
    // 获取下一个轮换的项目颜色
    private func getNextProjectColor() -> String {
        // 定义固定的颜色数组 (十六进制表示)
        let colors = [
            "#ffcdaa", // 橙色
            "#ee897f", // 天蓝色
            "#f24666", // 粉色
            "#9db898", // 浅绿色
            "#85C1E9"  // 浅紫色
        ]
        
        // 基于当前项目总数计算颜色索引
        // 不使用自增的colorIndex，而是根据项目数量来决定
        let totalProjects = projects.count
        let nextColorIndex = totalProjects % colors.count
        
        // 获取当前索引对应的颜色
        let colorHex = colors[nextColorIndex]
        
        return colorHex
    }
    
    // 预览下一个颜色（用于新建项目表单）
    func getNextProjectColorPreview() -> String {
        // 定义固定的颜色数组 (十六进制表示)
        let colors = [
            "#ffcdaa", // 橙色
            "#ee897f", // 天蓝色
            "#f24666", // 粉色
            "#9db898", // 浅绿色
            "#85C1E9"  // 浅紫色
        ]
        
        // 基于当前项目总数计算颜色索引
        let totalProjects = projects.count
        let nextColorIndex = totalProjects % colors.count
        
        // 获取当前索引对应的颜色
        return colors[nextColorIndex]
    }
    
    //更新项目名称
    func updateProjectName(_ project: Project, newName: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].name = newName
            saveData()
        }
    }
    
    //更新项目颜色
    func updateProjectColor(_ project: Project, newColor: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].color = newColor
            saveData()
        }
    }
    
    //更新项目备注
    func updateProjectNotes(_ project: Project, notes: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].notes = notes.isEmpty ? nil : notes
            saveData()
        }
    }
    
    //更新项目信息
    func updateProject(_ project: Project, newName: String, newColor: String) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].name = newName
            projects[index].color = newColor
            saveData()
        }
    }
    
    //移动项目到组
    func moveProject(_ project: Project, toGroup groupId: UUID?) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            // 保存原来的分组ID
            let oldGroupId = projects[index].groupId
            
            // 计算在新分组中的顺序
            var newOrder = 0
            if let groupId = groupId {
                let projectsInNewGroup = projectsInGroup(groupId)
                if !projectsInNewGroup.isEmpty {
                    newOrder = (projectsInNewGroup.map { $0.order }.max() ?? -1) + 1
                }
            } else {
                let ungrouped = ungroupedProjects()
                if !ungrouped.isEmpty {
                    newOrder = (ungrouped.map { $0.order }.max() ?? -1) + 1
                }
            }
            
            // 更新项目的分组和顺序
            projects[index].groupId = groupId
            projects[index].order = newOrder
            
            // 保存更改
            saveData()
        }
    }
    
    //删除项目
    func deleteProject(at indexSet: IndexSet) {
        // 检查是否越界
        let validIndices = indexSet.filter { $0 >= 0 && $0 < projects.count }
        guard !validIndices.isEmpty else { return }
        
        // 获取要删除的项目ID
        let projectIds = validIndices.map { projects[$0].id }
        
        // 从数组中移除这些项目
        projects.removeAll { projectIds.contains($0.id) }
        saveData()
    }
    
    //获取组内项目（按顺序）
    func projectsInGroup(_ groupId: UUID?) -> [Project] {
        return projects.filter { $0.groupId == groupId }
            .sorted { $0.order < $1.order }
    }
    
    //获取未分组项目（按顺序）
    func ungroupedProjects() -> [Project] {
        return projects.filter { $0.groupId == nil }
            .sorted { $0.order < $1.order }
    }
    
    // 更新所有项目的任务序号
    private func updateAllTaskNumbers() {
        for (projectIndex, project) in projects.enumerated() {
            // 获取所有任务并按日期排序
            var allTasks = projects[projectIndex].tasks
            allTasks.sort { $0.dueDate < $1.dueDate }
            
            // 更新所有任务的序号
            var updatedTasks: [Task] = []
            for (index, task) in allTasks.enumerated() {
                if let numberEndIndex = task.title.firstIndex(of: ".") {
                    let newTitle = "\(index + 1)." + task.title[task.title.index(after: numberEndIndex)...]
                    let updatedTask = Task(
                        id: task.id,
                        title: String(newTitle),
                        dueDate: task.dueDate,
                        importance: task.importance,
                        isCompleted: task.isCompleted
                    )
                    updatedTasks.append(updatedTask)
                } else {
                    // 如果任务标题没有序号标记，添加一个
                    let newTitle = "\(index + 1).\(task.title)"
                    let updatedTask = Task(
                        id: task.id,
                        title: newTitle,
                        dueDate: task.dueDate,
                        importance: task.importance,
                        isCompleted: task.isCompleted
                    )
                    updatedTasks.append(updatedTask)
                }
            }
            
            // 保存更新后的任务列表
            projects[projectIndex].tasks = updatedTasks
        }
        saveData()
    }
    
    //添加任务
    func addTask(to project: Project, title: String, dueDate: Date, importance: TaskImportance) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            // 创建新任务
            let task = Task(title: title, dueDate: dueDate, importance: importance)
            
            // 插入新任务
            projects[index].tasks.append(task)
            
            // 更新所有项目的任务序号
            updateAllTaskNumbers()
        }
    }
    
    //更新任务
    func updateTask(_ task: Task, title: String, dueDate: Date, importance: TaskImportance) {
        for (index, project) in projects.enumerated() {
            if let taskIndex = project.tasks.firstIndex(where: { $0.id == task.id }) {
                // 更新任务
                projects[index].tasks[taskIndex] = Task(
                    id: task.id,
                    title: title,
                    dueDate: dueDate,
                    importance: importance,
                    isCompleted: task.isCompleted
                )
                
                // 更新所有项目的任务序号
                updateAllTaskNumbers()
                break
            }
        }
    }
    
    //删除任务
    func deleteTask(_ task: Task) {
        let taskId = task.id
        
        // 在删除前再次确认任务存在于某个项目中
        let taskExists = projects.contains { project in
            project.tasks.contains { $0.id == taskId }
        }
        
        guard taskExists else { return }
        
        for (index, project) in projects.enumerated() {
            if let taskIndex = project.tasks.firstIndex(where: { $0.id == taskId }) {
                projects[index].tasks.remove(at: taskIndex)
                // 更新所有项目的任务序号
                updateAllTaskNumbers()
                break
            }
        }
    }
    
    //切换任务完成状态
    func toggleTaskCompletion(task: Task, in project: Project) {
        if let projectIndex = projects.firstIndex(where: { $0.id == project.id }),
           let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == task.id }) {
            projects[projectIndex].tasks[taskIndex].isCompleted.toggle()
            saveData()
        }
    }
    
    //重新排序任务
    func reorderTasks() {
        for (projectIndex, project) in projects.enumerated() {
            // 确保任务数组非空
            guard !project.tasks.isEmpty else { continue }
            
            // 获取所有任务并按日期排序
            var allTasks = projects[projectIndex].tasks
            
            // 按日期排序
            allTasks.sort { $0.dueDate < $1.dueDate }
            
            // 更新所有任务的序号
            var updatedTasks: [Task] = []
            for (index, task) in allTasks.enumerated() {
                if let numberEndIndex = task.title.firstIndex(of: ".") {
                    let newTitle = "\(index + 1)." + task.title[task.title.index(after: numberEndIndex)...]
                    let updatedTask = Task(
                        id: task.id,
                        title: String(newTitle),
                        dueDate: task.dueDate,
                        importance: task.importance,
                        isCompleted: task.isCompleted
                    )
                    updatedTasks.append(updatedTask)
                } else {
                    // 如果任务标题没有序号标记，添加一个
                    let newTitle = "\(index + 1).\(task.title)"
                    let updatedTask = Task(
                        id: task.id,
                        title: newTitle,
                        dueDate: task.dueDate,
                        importance: task.importance,
                        isCompleted: task.isCompleted
                    )
                    updatedTasks.append(updatedTask)
                }
            }
            
            // 保存更新后的任务列表
            projects[projectIndex].tasks = updatedTasks
        }
        // 保存更改
        saveData()
    }
    
    //保存数据
    private func saveData() {
        if let encodedGroups = try? JSONEncoder().encode(groups) {
            UserDefaults.standard.set(encodedGroups, forKey: "savedGroups")
        }
        if let encodedProjects = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encodedProjects, forKey: "savedProjects")
        }
    }
    
    //加载数据
    private func loadData() {
        if let groupsData = UserDefaults.standard.data(forKey: "savedGroups"),
           let decodedGroups = try? JSONDecoder().decode([ProjectGroup].self, from: groupsData) {
            groups = decodedGroups
        }
        
        if let projectsData = UserDefaults.standard.data(forKey: "savedProjects"),
           let decodedProjects = try? JSONDecoder().decode([Project].self, from: projectsData) {
            projects = decodedProjects
        }
    }
    
    //导出为CSV
    func exportToCSV() -> String {
        var csvString = "项目名称,任务名称,截止日期,重要性,完成状态\n"
        
        for project in projects {
            for task in project.tasks {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd"
                let dateString = dateFormatter.string(from: task.dueDate)
                
                let row = "\(project.name),\(task.title),\(dateString),\(task.importance.rawValue),\(task.isCompleted)\n"
                csvString += row
            }
        }
        
        return csvString
    }
    
    // 交换项目顺序
    func swapProjectOrder(projectId1: UUID, projectId2: UUID) {
        guard let index1 = projects.firstIndex(where: { $0.id == projectId1 }),
              let index2 = projects.firstIndex(where: { $0.id == projectId2 }) else {
            return
        }
        
        // 确保两个项目在同一个组中
        guard projects[index1].groupId == projects[index2].groupId else {
            return
        }
        
        // 交换顺序
        let tempOrder = projects[index1].order
        projects[index1].order = projects[index2].order
        projects[index2].order = tempOrder
        
        saveData()
    }
    
    // 移动项目到指定位置
    func moveProject(_ project: Project, toPosition position: Int) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else {
            return
        }
        
        // 获取同组中的项目
        let projectsInSameGroup: [Project]
        if let groupId = project.groupId {
            projectsInSameGroup = projects.filter { $0.groupId == groupId }
        } else {
            projectsInSameGroup = projects.filter { $0.groupId == nil }
        }
        
        // 确保位置有效
        let validPosition = max(0, min(position, projectsInSameGroup.count - 1))
        
        // 获取当前项目的顺序
        let currentOrder = projects[index].order
        
        // 获取目标位置的项目
        let sortedProjects = projectsInSameGroup.sorted { $0.order < $1.order }
        guard validPosition < sortedProjects.count else { return }
        
        let targetOrder = sortedProjects[validPosition].order
        
        // 如果当前顺序小于目标顺序（向后移动）
        if currentOrder < targetOrder {
            // 将所有在当前顺序和目标顺序之间的项目顺序减1
            for i in 0..<projects.count {
                if projects[i].groupId == project.groupId && 
                   projects[i].order > currentOrder && 
                   projects[i].order <= targetOrder {
                    projects[i].order -= 1
                }
            }
        } 
        // 如果当前顺序大于目标顺序（向前移动）
        else if currentOrder > targetOrder {
            // 将所有在目标顺序和当前顺序之间的项目顺序加1
            for i in 0..<projects.count {
                if projects[i].groupId == project.groupId && 
                   projects[i].order >= targetOrder && 
                   projects[i].order < currentOrder {
                    projects[i].order += 1
                }
            }
        }
        
        // 设置当前项目为目标顺序
        projects[index].order = targetOrder
        
        saveData()
    }
    
    // 插入项目到指定位置（在目标项目前面或后面）
    func insertProject(_ projectToMove: Project, beforeProject targetProject: Project) {
        // 确保两个项目在同一个分组
        guard projectToMove.groupId == targetProject.groupId else {
            return
        }
        
        // 获取同组中的所有项目并按顺序排序
        var projectsInSameGroup = self.projects.filter { $0.groupId == targetProject.groupId }
            .sorted { $0.order < $1.order }
        
        // 如果移动项目和目标项目相同，不执行任何操作
        if projectToMove.id == targetProject.id {
            return
        }
        
        // 从排序列表中移除要移动的项目
        projectsInSameGroup.removeAll { $0.id == projectToMove.id }
        
        // 找到目标项目在排序列表中的索引
        guard let targetIndex = projectsInSameGroup.firstIndex(where: { $0.id == targetProject.id }) else {
            return
        }
        
        // 计算新的插入位置（在目标项目之前）
        let newPosition = targetIndex
        
        // 插入项目到新位置
        projectsInSameGroup.insert(projectToMove, at: newPosition)
        
        // 重新计算所有项目的顺序
        for (index, project) in projectsInSameGroup.enumerated() {
            if let projectIndex = self.projects.firstIndex(where: { $0.id == project.id }) {
                self.projects[projectIndex].order = index
            }
        }
        
        saveData()
    }
    
    // 插入项目到指定位置（在目标项目后面）
    func insertProject(_ projectToMove: Project, afterProject targetProject: Project) {
        // 确保两个项目在同一个分组
        guard projectToMove.groupId == targetProject.groupId else {
            return
        }
        
        // 获取同组中的所有项目并按顺序排序
        var projectsInSameGroup = self.projects.filter { $0.groupId == targetProject.groupId }
            .sorted { $0.order < $1.order }
        
        // 如果移动项目和目标项目相同，不执行任何操作
        if projectToMove.id == targetProject.id {
            return
        }
        
        // 从排序列表中移除要移动的项目
        projectsInSameGroup.removeAll { $0.id == projectToMove.id }
        
        // 找到目标项目在排序列表中的索引
        guard let targetIndex = projectsInSameGroup.firstIndex(where: { $0.id == targetProject.id }) else {
            return
        }
        
        // 计算新的插入位置（在目标项目之后）
        let newPosition = targetIndex + 1
        
        // 如果新位置超出数组范围，则添加到末尾
        if newPosition >= projectsInSameGroup.count {
            projectsInSameGroup.append(projectToMove)
        } else {
            // 否则插入到指定位置
            projectsInSameGroup.insert(projectToMove, at: newPosition)
        }
        
        // 重新计算所有项目的顺序
        for (index, project) in projectsInSameGroup.enumerated() {
            if let projectIndex = self.projects.firstIndex(where: { $0.id == project.id }) {
                self.projects[projectIndex].order = index
            }
        }
        
        saveData()
    }
    
    func getProjectData() -> ProjectData {
        let projects = self.projects.map { project in
            ProjectData.Project.from(project: project)
        }
        
        let groups = self.groups.map { group in
            ProjectData.ProjectGroup(
                id: group.id,
                name: group.name
            )
        }
        
        return ProjectData(projects: projects, groups: groups)
    }
    
    func loadFromData(_ data: ProjectData) {
        // 清空现有数据
        self.projects.removeAll()
        self.groups.removeAll()
        
        // 加载项目组
        for group in data.groups {
            self.groups.append(ProjectGroup(id: group.id, name: group.name))
        }
        
        // 加载项目
        for project in data.projects {
            let tasks = project.tasks.map { task in
                Task(
                    id: task.id,
                    title: task.title,
                    dueDate: task.dueDate,
                    importance: task.importance,
                    isCompleted: task.isCompleted
                )
            }
            
            self.projects.append(Project(
                id: project.id,
                name: project.name,
                groupId: project.groupId,
                tasks: tasks,
                createdAt: Date(),
                color: project.color,
                order: project.order,
                notes: project.notes
            ))
        }
    }
    
    // 清除所有数据
    func clearAllData() {
        // 清空项目数组
        projects.removeAll()
        // 清空项目组数组
        groups.removeAll()
        // 保存更改
        saveData()
    }
    
    // 搜索任务
    func searchTasks(in project: Project, searchText: String) -> [Task] {
        if searchText.isEmpty {
            return project.tasks
        }
        return project.tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // 搜索项目
    func searchProjects(searchText: String) -> [Project] {
        if searchText.isEmpty {
            return projects
        }
        return projects.filter { project in
            // 搜索项目名称
            if project.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // 搜索项目组名称
            if let groupId = project.groupId,
               let group = groups.first(where: { $0.id == groupId }),
               group.name.localizedCaseInsensitiveContains(searchText) {
                return true
            }
            
            // 搜索任务
            return project.tasks.contains { task in
                task.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
} 
