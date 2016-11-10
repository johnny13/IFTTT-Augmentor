//
//  MainMenuViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/27/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit

class MainMenuViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	private let reminderInput = UITextField(frame: CGRect.zero)

    override func viewDidLoad() {
        super.viewDidLoad()
		
		let reminderPicker = UIPickerView(frame: CGRect.zero)
		reminderPicker.delegate = self
		reminderPicker.dataSource = self
		reminderInput.inputView = reminderPicker
		self.view.addSubview(reminderInput)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func viewTrainingSchedule(_ schedule: TrainingSchedule) {
		DispatchQueue.main.async {
			let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
			let controller = storyboard.instantiateViewController(withIdentifier: "TrainingScheduleController") as! TrainingScheduleViewController
			controller.schedule = schedule
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Army"
		case 1:
			return "Settings"
		default:
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			if indexPath.row == 0 {
				return tableView.dequeueReusableCell(withIdentifier: "TrainingSchedulesCell", for: indexPath)
			}
		} else if indexPath.section == 1 {
			if indexPath.row == 0 {
				let cell = tableView.dequeueReusableCell(withIdentifier: "RemindersCell", for: indexPath)
				if let reminders = EventManager.reminderCalendar {
					cell.detailTextLabel?.text = reminders.title
				} else {
					cell.detailTextLabel?.text = "Not Selected"
				}
				return cell
			}
		}
		fatalError("Invalid cell: \(indexPath)")
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 1 {
			if self.reminderInput.isFirstResponder {
				self.reminderInput.resignFirstResponder()
				self.tableView.deselectRow(at: indexPath, animated: true)
			} else {
				self.reminderInput.becomeFirstResponder()
				if EventManager.reminderCalendar == nil {
					let picker = reminderInput.inputView as! UIPickerView
					if EventManager.reminders.count > 0 {
						picker.selectRow(0, inComponent: 0, animated: false)
						self.pickerView(picker, didSelectRow: 0, inComponent: 0)
					}
				}
			}
		} else {
			self.reminderInput.resignFirstResponder()
		}
	}
	
	// MARK: - Reminder Picker
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return EventManager.reminders.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return EventManager.reminders[row].title
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		EventManager.reminderCalendar = EventManager.reminders[row]
		self.tableView.reloadData()
	}
}
