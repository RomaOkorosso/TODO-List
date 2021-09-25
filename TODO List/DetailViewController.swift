//
//  DetailViewController.swift
//  TODO List
//
//  Created by Roma Okoroosso on 18.09.2021.
//

import UIKit

protocol TbvUpdateDelegate: AnyObject {
    func updateTbv()
}

protocol DeleteTaskDelegate: AnyObject {
    func deleteTaskFromArray(task: TaskModel)
}

class DetailViewController: UIViewController {

    weak var updateDeligate: TbvUpdateDelegate?
    weak var deleteTaskDelegate: DeleteTaskDelegate?

    @IBOutlet weak var createEditButton: UIButton!
    @IBOutlet weak var descriptioonTextView: UITextView!
    @IBOutlet weak var taskNmaeTextField: UITextField!
    @IBOutlet weak var taskStatusSeklector: UIPickerView!
    @IBOutlet weak var expirationDatePicker: UIDatePicker!
    @IBOutlet weak var deleteButton: UIButton!

    weak var task: TaskModel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        deleteButton.setTitle("", for: .normal)
        taskNmaeTextField.text = task?.text
        taskStatusSeklector.delegate = self
        taskStatusSeklector.dataSource = self

        expirationDatePicker.minimumDate = Date()
        expirationDatePicker.timeZone = TimeZone.current
        expirationDatePicker.date = task?.expirationDate ?? Date()

        taskStatusSeklector.selectRow(task?.status.rawValue ?? 0, inComponent: 0, animated: false)
        let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: 0, height: 44))
        let doneButtno = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hideKeyboard))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.items = [flex, doneButtno]
        toolbar.setItems([flex, doneButtno], animated: true)

        taskNmaeTextField.inputAccessoryView = toolbar

        descriptioonTextView.text = task?.description
        descriptioonTextView.inputAccessoryView = toolbar
    }

    @objc
    func hideKeyboard() {
        taskNmaeTextField.endEditing(true)
        descriptioonTextView.endEditing(true)
    }

    @IBAction func editTaskAction(_ sender: Any) {
        if taskNmaeTextField?.text != ""{
            print("DATE:", expirationDatePicker.date)
            if task == nil{
                
                let newTask = TaskModel(text: taskNmaeTextField.text ?? "mockup",
                                        description: descriptioonTextView.text ?? "mockup",
                                        expirationDate: expirationDatePicker.date
                                        )
                if let error = newTask.save(){
                    print(error)
                }
            }
            if let error = task?.update(newText: taskNmaeTextField?.text, newStatus: TaskModel.TaskStatus.allCases[taskStatusSeklector.selectedRow(inComponent: 0)], newDescription: descriptioonTextView?.text, newExpirationDate: expirationDatePicker.date){
                print(error)
            }
            self.dismiss(animated: true, completion: nil)
            self.updateDeligate?.updateTbv()
        } else {
            let alert = UIAlertController(title: "Alert", message: "Task name can not be empty", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.present(alert, animated: true, completion: nil)
        }

    }

    @IBAction func deleteButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "Delete it?", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "No", style: .destructive, handler: { _ in
                        alert.dismiss(animated: true)
                    }))

        alert.addAction(UIAlertAction(title: "YES", style: .destructive, handler: { _ in
            guard let tTask = self.task else {
                alert.dismiss(animated: true)
                return
            }
            self.deleteTaskDelegate?.deleteTaskFromArray(task: tTask)
            alert.dismiss(animated: true)
            self.dismiss(animated: true, completion: nil)
            self.updateDeligate?.updateTbv()
        }))
        self.present(alert, animated: true, completion: nil)

    }
}

extension DetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        TaskModel.TaskStatus.allCases.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch TaskModel.TaskStatus.allCases[row] {
        case .open:
            return "Open"
        case .inProgress:
            return "In progress"
        case .close:
            return "Close"
        }
    }
}
