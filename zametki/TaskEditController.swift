//
//  TaskEditController.swift
//  zametki
//
//  Created by Alex on 30.04.2022.
//

import UIKit

class TaskEditController: UITableViewController {

    var taskText: String = ""
    var taskType: TaskPriority = .normal
    var taskStatus: TaskStatus = .planned
    
    var doAfterEdit: ((String, TaskPriority, TaskStatus) -> Void)?
    
    
    @IBOutlet var taskTitle: UITextField!
    @IBOutlet var taskTypeLabel: UILabel!
    @IBOutlet var taskStatusSwitch: UISwitch!
    
    
    private var taskTitles: [TaskPriority: String] = [
        .important: "Важная",
        .normal: "Текущая"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskTitle?.text = taskText
        taskTypeLabel?.text = taskTitles[taskType]
        
        if taskStatus == .completed{
            taskStatusSwitch.isOn = true
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
       
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return 3
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTaskTypeScreen"{
            let destination = segue.destination as! TaskTypeController
            
            destination.selectedType = taskType
            
            destination.doAfterTypeSelected = { [self] selectedType in
                self.taskType = selectedType
                // обновляем метку с текущим типом
                taskTypeLabel?.text = self.taskTitles[taskType]
            }
        }
    }
 
    @IBAction func saveTask(_ sender: UIBarButtonItem) {
        let title = taskTitle?.text ?? ""
        let type = taskType
        let status: TaskStatus = taskStatusSwitch.isOn ? .completed : .planned
        
        doAfterEdit?(title, type, status)
        navigationController?.popViewController(animated: true)
    }
    
}
