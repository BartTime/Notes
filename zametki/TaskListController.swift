//
//  TaskListController.swift
//  zametki
//
//  Created by Alex on 30.04.2022.
//

import UIKit

class TaskListController: UITableViewController {
    
    // MARK: - Объявление
    
    var tasksStorage: TaskStorageProtocol = TaskStorage()
    
    var tasks: [TaskPriority: [TaskProtocol]] = [ : ]{
        didSet{
            for (tasksGroupPriority, tasksGroup) in tasks{
                tasks[tasksGroupPriority] = tasksGroup.sorted{ task1, task2 in
                    let task1position = tasksStatusPosition.firstIndex(of: task1.status) ?? 0
                    let task2position = tasksStatusPosition.firstIndex(of: task2.status) ?? 0
                    return task1position < task2position
                }
            }
            
            // сохранение задач
            
            var savingArray: [TaskProtocol] = []
            
            tasks.forEach{ _, value in
                savingArray += value
            }
            
            tasksStorage.saveTasks(savingArray)
            
        }
    }
    
    var sectionsTypesPosition: [TaskPriority] = [.important, .normal]
    
    var tasksStatusPosition: [TaskStatus] = [.planned, .completed]
    
    
    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadTasks()
        
        navigationItem.leftBarButtonItem = editButtonItem

    }

    // MARK: - Количество ячеек
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return tasks.count
    }

    // MARK: - Ячейки в секции
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //приоритет задач для текущей секции
        let taskType = sectionsTypesPosition[section]
        guard let currentTaskType = tasks[taskType] else {
            return 0
        }

        return currentTaskType.count
    }

    // MARK: - Заполнение ячеек
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        return getConfiguredTaskCell_constraints(for: indexPath)
        
    }
    
    // MARK: - Наименования Header
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let taskType = sectionsTypesPosition[section]
        
        if taskType == .important{
            title = "Важные"
        }else if taskType == .normal{
            title = "Текущие"
        }
        
        return title
    }
    
    // MARK: - Пометка задачи выполненной
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 1. Проверяем существование задачи
        let taskType = sectionsTypesPosition[indexPath.section]
        guard let _ = tasks[taskType]?[indexPath.row] else{
            return
        }
        // 2. Убеждаемся, что задача не является выполненной
        guard tasks[taskType]![indexPath.row].status == .planned else{
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        // 3. Отмечаем задачу как выполненную
        
        tasks[taskType]![indexPath.row].status = .completed
        
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }
    
    // MARK: - Свайп (Перевод в активную задачу)
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // получаем данные о задаче, которую необходимо перевести в статус "запланирована"
        let taskType = sectionsTypesPosition[indexPath.section]
        
        guard let _ = tasks[taskType]?[indexPath.row] else{
            return nil
        }
        
    
        //изменение статуса
        
        let actionSwipeInstance = UIContextualAction(style: .normal, title: "Не выполнена"){_, _, _ in
            self.tasks[taskType]![indexPath.row].status = .planned
            self.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        }
        
        // действие для перехода к экрану редактирования
        let actionEditInstance = UIContextualAction(style: .normal, title: "Изменить"){_, _, _ in
            
            let editScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaskEditController") as! TaskEditController
            editScreen.taskText = self.tasks[taskType]![indexPath.row].title
            editScreen.taskType = self.tasks[taskType]![indexPath.row].type
            editScreen.taskStatus = self.tasks[taskType]![indexPath.row].status
            
            editScreen.doAfterEdit = {[self] title, type, status in
                let editedTask = Task(title: title, type: type, status: status)
                tasks[taskType]![indexPath.row] = editedTask
                tableView.reloadData()
            }
            self.navigationController?.pushViewController(editScreen, animated: true)
        }
        
        actionEditInstance.backgroundColor = .darkGray
        let actionsConfiguration: UISwipeActionsConfiguration
        if tasks[taskType]![indexPath.row].status == .completed{
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionSwipeInstance, actionEditInstance])
        }else{
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionEditInstance])
        }
        
        return actionsConfiguration

    }
    
    // MARK: - Удаление
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let taskType = sectionsTypesPosition[indexPath.section]
        tasks[taskType]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    // MARK: - Перемещение задач
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // секция, из которой происходит перемещение
        let taskTypeFrom = sectionsTypesPosition[sourceIndexPath.section]
        // секция, в которую происходит перемещение
        let taskToType = sectionsTypesPosition[destinationIndexPath.section]
        
        guard let moveTask = tasks[taskTypeFrom]?[sourceIndexPath.row] else {
            return
        }
        
        tasks[taskTypeFrom]!.remove(at: sourceIndexPath.row)
        
        tasks[taskToType]!.insert(moveTask, at: destinationIndexPath.row)
        
        if taskTypeFrom != taskToType{
            tasks[taskToType]![destinationIndexPath.row].type = taskToType
        }
        
        tableView.reloadData()
    }
    
    // MARK: - передача данных
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreateScreen"{
            let destination = segue.destination as! TaskEditController
            
            destination.doAfterEdit = {[self] title, type, status in
                let newTask = Task(title: title, type: type, status: status)
                
                tasks[type]?.append(newTask)
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - func для заполнения ячеек
    
    private func getConfiguredTaskCell_constraints(for indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellConstraints", for: indexPath)
        // загружаем прототип ячейки по идентификатору
        let taskType = sectionsTypesPosition[indexPath.section]
        // получаем данные о задаче, которую необходимо вывести в ячейке
        guard let currentTask = tasks[taskType]?[indexPath.row] else{
            return cell
        }
        
        let symbolLabel = cell.viewWithTag(1) as? UILabel
        let textLabel = cell.viewWithTag(2) as? UILabel
        
        symbolLabel?.text = getSymbolForTask(with: currentTask.status)
        
        textLabel?.text = currentTask.title
        
        if currentTask.status == .planned{
            textLabel?.textColor = .black
            symbolLabel?.textColor = .black
        }else{
            textLabel?.textColor = .lightGray
            symbolLabel?.textColor = .lightGray
        }
        
        return cell
        
    }
    
    private func getConfiguredTaskCell_stack(for indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellStack", for: indexPath) as! TaskCell
        // загружаем прототип ячейки по идентификатору
        let taskType = sectionsTypesPosition[indexPath.section]
        
        guard let currentTask = tasks[taskType]?[indexPath.row] else{
            return cell
        }
        
        cell.title.text = currentTask.title
        cell.symbol.text = getSymbolForTask(with: currentTask.status)
        
        if currentTask.status == .planned{
            cell.title.textColor = .black
            cell.symbol.textColor = .black
        }else{
            cell.title.textColor = .lightGray
            cell.symbol.textColor = .lightGray
        }
        
        return cell
        
    }
    
    // возвращаем символ для соответствующего типа задачи
    private func getSymbolForTask(with status: TaskStatus) -> String{
        var resultSymbol: String
        
        if status == .planned{
            resultSymbol = "\u{25CB}"
        }else if status == .completed{
            resultSymbol = "\u{25C9}"
        }else{
            resultSymbol = ""
        }
        return resultSymbol
    }

    // MARK: - Закгрузка задач
    
    private func loadTasks(){
        
        sectionsTypesPosition.forEach{ taskType in
            tasks[taskType] = []
        }
        
        tasksStorage.loadTasks().forEach{ task in
            tasks[task.type]?.append(task)
        }
        
    }
    
    // MARK: - получение списка задач, их разбор и установка в свойство tasks
    
    func setTasks(_ tasksCollection: [TaskProtocol]){
        
        // подготовка коллекции с задачами
        sectionsTypesPosition.forEach{ taskType in
            tasks[taskType] = []
        }
        
        // загрузка и разбор задач из хранилища
        tasksCollection.forEach{ task in
            tasks[task.type]?.append(task)
        }
        
    }
 
}
