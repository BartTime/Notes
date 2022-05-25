//
//  Task.swift
//  zametki
//
//  Created by Alex on 30.04.2022.
//

import Foundation

// тип задачи
enum TaskPriority{
    case normal
    case important
}

//статус задачи
enum TaskStatus: Int{
    case planned
    case completed
}

//требования
protocol TaskProtocol{
    var title: String { get set }
    var type: TaskPriority  { get set }
    var status: TaskStatus { get set }
}

struct Task: TaskProtocol{
    var title: String
    var type: TaskPriority
    var status: TaskStatus
}

protocol TaskStorageProtocol{
    func loadTasks() -> [TaskProtocol]
    func saveTasks(_ tasks: [TaskProtocol])
}

class TaskStorage: TaskStorageProtocol{
    
    private var storage = UserDefaults.standard
    var storageKey: String = "tasks"
    private enum TaskKey: String{
        case title
        case type
        case status
    }
    
    func loadTasks() -> [TaskProtocol] {
        
        var resultTasks: [TaskProtocol] = []
        let tasksFromStorage = storage.array(forKey: storageKey) as? [[String:String]] ?? []
        
        for task in tasksFromStorage{
            guard let title = task[TaskKey.title.rawValue],
                  let typeRaw = task[TaskKey.type.rawValue],
                  let statusRaw = task[TaskKey.status.rawValue] else {
                      continue
                  }
            let type: TaskPriority = typeRaw == "important" ? .important : .normal
            let status: TaskStatus = statusRaw == "planned" ? .planned : .completed
            
            resultTasks.append(Task(title: title, type: type, status: status))
        }
    
        return resultTasks
    }
    
    func saveTasks(_ tasks: [TaskProtocol]) {
        var arrayForStorage: [[String: String]] = []
        
        tasks.forEach { task in
            var newElementForStorage: Dictionary<String, String> = [:]
            newElementForStorage[TaskKey.title.rawValue] = task.title
            newElementForStorage[TaskKey.type.rawValue] = (task.type == .important) ? "important" : "normal"
            newElementForStorage[TaskKey.status.rawValue] = (task.status == .planned) ? "planned" : "completed"
            arrayForStorage.append(newElementForStorage)
        }
        storage.set(arrayForStorage, forKey: storageKey)
        
        return
    }
    
    
}
