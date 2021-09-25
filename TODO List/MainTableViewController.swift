//
//  MainTableViewController.swift
//  TODO List
//
//  Created by Roma Okorossoo on 17.09.2021.
//

import UIKit
import CoreData

class TaskModel {
    init(id: String = UUID().uuidString, text: String, status: TaskModel.TaskStatus = .open, description: String,
         expirationDate: Date = Date()) {
        self.id = id
        self.text = text
        self.status = status
        self.description = description
        self.expirationDate = expirationDate
    }

    var id: String = UUID().uuidString
    var text: String
    var status: TaskStatus = .open
    var description: String
    var expirationDate: Date

    static let DBname = "TaskDB"

    enum TaskStatus: Int, CaseIterable {
        case open = 0, inProgress, close
    }

    static func getAll() -> [TaskModel] {
        let appDeligate = AppDelegate.appDelegate
        let managedContext = appDeligate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: TaskModel.DBname)
        var tasks: [TaskModel] = []

        do {
            let res = try managedContext.fetch(fetchRequest)
            for data in res as! [NSManagedObject]{
                tasks.append(TaskModel(id:data.value(forKey: "id") as! String, text: data.value(forKey: "text") as! String, status: TaskStatus(rawValue: data.value(forKey: "status") as! Int)!, description: data.value(forKey: "descript") as? String ??
                                       "", expirationDate: data.value(forKey: "expirationDate") as! Date))
            }
        } catch {
            return []
        }

        return tasks
    }

    public func save() -> Error? {
        let appDeligate = AppDelegate.appDelegate

        let managedContext = appDeligate.persistentContainer.viewContext
        let taskEntity = NSEntityDescription.entity(forEntityName: TaskModel.DBname, in: managedContext)

        let task = NSManagedObject(entity: taskEntity!, insertInto: managedContext)
        task.setValue(self.id, forKey: "id")
        task.setValue(self.text, forKey: "text")
        task.setValue(Int16(self.status.rawValue), forKey: "status")
        task.setValue(self.description, forKey: "descript")
        task.setValue(self.expirationDate, forKey: "expirationDate")

        do {
            try managedContext.save()
            return nil
        } catch {
            return error
        }
    }

    public func update(newText: String? = nil , newStatus: TaskStatus? = nil, newDescription: String? = nil, newExpirationDate: Date? = nil) -> Error? {
        let appDeligate = AppDelegate.appDelegate
        let managedContext = appDeligate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: TaskModel.DBname)
        fetchRequest.predicate = NSPredicate(format: "id = %@", self.id)

        do {
            let DBtask = try managedContext.fetch(fetchRequest)
            let task = DBtask[0] as! NSManagedObject

            if newStatus != nil {
                task.setValue(Int16(newStatus!.rawValue), forKey: "status")

            }

            if newDescription != nil {
                task.setValue(newDescription!, forKey: "descript")
            }

            if newText != nil {
                task.setValue(newText!, forKey: "text")
            }

            if newExpirationDate != nil {
                task.setValue(newExpirationDate, forKey: "expirationDate")
            }

            try managedContext.save()
            return nil
        } catch {
            return error
        }

    }

    public func delete() -> Error? {
        let appDeligate = AppDelegate.appDelegate
        let managedContext = appDeligate.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: TaskModel.DBname)
        fetchRequest.predicate = NSPredicate(format: "id = %@", self.id)

        do {
            let DBtask = try managedContext.fetch(fetchRequest)
            let task = DBtask[0] as! NSManagedObject
            managedContext.delete(task)
            try managedContext.save()
        } catch {
            return error
        }
        return nil
    }
}

class MainTableViewController: UITableViewController {
    var ourTasks: [TaskModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.ourTasks = TaskModel.getAll()
        self.navigationController?.navigationBar.prefersLargeTitles = true
    }

    @IBAction func addTask(_ sender: Any) {

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailViewVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        detailViewVC.updateDeligate = self
        detailViewVC.deleteTaskDelegate = self
        self.present(detailViewVC, animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return TaskModel.TaskStatus.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.ourTasks.filter { task in
            return task.status == TaskModel.TaskStatus(rawValue: section)!
        }.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let task = self.ourTasks.filter { task in
            return task.status == TaskModel.TaskStatus(rawValue: indexPath.section)!
        }[indexPath.row]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        cell.textLabel?.text = task.text
        cell.detailTextLabel?.text = dateFormatter.string(from: task.expirationDate)

        switch task.status{
        case .open:
            cell.backgroundColor = .secondarySystemBackground
        case .inProgress:
            cell.backgroundColor = .systemBlue
        case .close:
            cell.backgroundColor = .systemGreen

        }

        if task.expirationDate <= Date() && task.status != .close{
            cell.backgroundColor = .systemGray
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch TaskModel.TaskStatus(rawValue: section)!{
        case .open:
            return "Open"
        case .inProgress:
            return "In progress"
        case .close:
            return "Close"
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = self.ourTasks.filter { task in
            return task.status == TaskModel.TaskStatus(rawValue: indexPath.section)!
        }[indexPath.row]

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailViewVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController

        detailViewVC.updateDeligate = self
        detailViewVC.deleteTaskDelegate = self
        detailViewVC.task = task
        self.present(detailViewVC, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            // Delete shit
            let task = self.ourTasks.filter { task in
                return task.status == TaskModel.TaskStatus(rawValue: indexPath.section)!
            }[indexPath.row]

            if let error = task.delete(){
                print(error)
            }
            self.ourTasks.removeAll { taskFind in
                return task.id == taskFind.id
            }

            self.tableView.reloadData()

            completion(true)
        }

        let cnofig = UISwipeActionsConfiguration(actions: [
            action
        ])

        return cnofig
    }

}

extension MainTableViewController: TbvUpdateDelegate{
    func updateTbv() {
        self.ourTasks = TaskModel.getAll()
        self.tableView.reloadData()
    }
}

extension MainTableViewController: DeleteTaskDelegate{
    func deleteTaskFromArray(task: TaskModel) {
        if let error = task.delete(){
            print(error)
        }
        self.ourTasks.removeAll { taskFind in
            return task.id == taskFind.id
        }
    }

}
