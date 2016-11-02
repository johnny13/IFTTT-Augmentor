//
//  TrainingSchedulesViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/26/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import CoreData

class TrainingSchedulesViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
	private let calendarInput = UITextField(frame: CGRect.zero)
	private var _forwardSchedule: TrainingSchedule?

    override func viewDidLoad() {
        super.viewDidLoad()
		
		let calendarPicker = UIPickerView(frame: CGRect.zero)
		calendarPicker.delegate = self
		calendarPicker.dataSource = self
		calendarInput.inputView = calendarPicker
		self.view.addSubview(calendarInput)
		
		if let schedule = self._forwardSchedule {
			print("List loaded and performing segue")
			self.performSegue(withIdentifier: "ScheduleViewSegue", sender: schedule)
		} else {
			TrainingScheduleManager.loadTrainingSchedules(completion: { _ in
				DispatchQueue.main.async {
					self.tableView.reloadData()
				}
			})
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func forward(_ schedule: TrainingSchedule) {
		print("List - forwarding")
		self._forwardSchedule = schedule
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? 1 : TrainingScheduleManager.schedules.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "CalendarSelectCell", for: indexPath)
			if let calendar = EventManager.armyCalendar {
				cell.detailTextLabel?.text = calendar.title
			} else {
				cell.detailTextLabel?.text = "Not Selected"
			}
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "TrainingScheduleCell", for: indexPath)
			let schedule = TrainingScheduleManager.schedules[indexPath.row]
			cell.textLabel?.text = schedule.dateRange
			cell.detailTextLabel?.text = schedule.file
			if let _ = EventManager.armyCalendar {
				if (schedule.imported) {
					cell.accessoryType = .checkmark
				} else {
					cell.accessoryType = .disclosureIndicator
				}
				cell.selectionStyle = .default
				cell.isUserInteractionEnabled = true
			} else {
				cell.accessoryType = .none
				cell.selectionStyle = .none
				cell.isUserInteractionEnabled = false
			}
			return cell
		}
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			if calendarInput.isFirstResponder {
				calendarInput.resignFirstResponder()
				tableView.deselectRow(at: indexPath, animated: true)
			} else {
				calendarInput.becomeFirstResponder()
				if EventManager.armyCalendar == nil {
					let picker = calendarInput.inputView as! UIPickerView
					picker.selectRow(0, inComponent: 0, animated: false)
					self.pickerView(picker, didSelectRow: 0, inComponent: 0)
				}
			}
		} else {
			self.calendarInput.resignFirstResponder()
		}
	}
	
	// MARK: - Calendar Picker
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return EventManager.calendars.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return EventManager.calendars[row].title
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		EventManager.armyCalendar = EventManager.calendars[row]
		self.tableView.reloadData()
		self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let dest = segue.destination as? TrainingScheduleViewController {
			if let schedule = sender as? TrainingSchedule {
				print("Setting schedule for detail view")
				dest.schedule = schedule
			} else if let selectedCell = sender as? UITableViewCell {
				dest.schedule = TrainingScheduleManager.schedules[self.tableView.indexPath(for: selectedCell)!.row]
			}
		}
		super.prepare(for: segue, sender: sender)
    }

}
