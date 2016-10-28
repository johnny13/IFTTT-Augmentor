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
	private var schedules: Array<TrainingSchedule> = []
	private let calendarInput = UITextField(frame: CGRect.zero)
	
	private var _loadCount: Int = 0
	private var loadCount: Int {
		get {
			return self._loadCount
		}
		
		set {
			self._loadCount = newValue
			if _loadCount == 0 {
				let app = UIApplication.shared.delegate as! AppDelegate
				app.saveContext()
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			} else {
				UIApplication.shared.isNetworkActivityIndicatorVisible = true
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		let calendarPicker = UIPickerView(frame: CGRect.zero)
		calendarPicker.delegate = self
		calendarPicker.dataSource = self
		calendarInput.inputView = calendarPicker
		self.view.addSubview(calendarInput)
		
		let app = UIApplication.shared.delegate as! AppDelegate
		let context = app.context
		
		let fetchRequest: NSFetchRequest<TrainingSchedule> = TrainingSchedule.fetchRequest()
		self.schedules = try! context.fetch(fetchRequest)
		self.schedules.sort(by: { lhs, rhs in
			return lhs.start!.compare(rhs.start as! Date) == .orderedDescending
		})
		
		loadCount = 1
		URLSession.shared.dataTask(with: URL(string: "http://wurtele.org:8080/IFTTT/api/schedules")!) { data, response, err in
			if let data = data {
				if let json = try? JSONSerialization.jsonObject(with: data) {
					for sched in json as? [AnyObject] ?? [] {
						let sender = sched["sender"] as! String
						let file = sched["file"] as! String
						
						let id = sender + "/" + file
						let fetchRequest: NSFetchRequest<TrainingSchedule> = TrainingSchedule.fetchRequest()
						fetchRequest.predicate = NSPredicate(format: "file = %@", id)
						do {
							let results = try context.fetch(fetchRequest)
							if results.count > 0 {
								continue
							}
						} catch { }
						let startMillis = sched["start"] as! TimeInterval
						let endMillis = sched["end"] as! TimeInterval
						
						let schedule = TrainingSchedule(context: context)
						schedule.file = id
						schedule.start = NSDate(timeIntervalSince1970: startMillis / 1000)
						schedule.end = NSDate(timeIntervalSince1970: endMillis / 1000)
						schedule.imported = false
						
						self.loadCount += 1
						URLSession.shared.dataTask(with: URL(string: "http://wurtele.org:8080/IFTTT/api/schedules/\(sender)/\(file)")!) { data, response, err in
							if let data = data {
								if let json = try? JSONSerialization.jsonObject(with: data) {
									for event in json as? [AnyObject] ?? [] {
										let item = TrainingScheduleItem(context: context)
										item.schedule = schedule
										item.start = NSDate(timeIntervalSince1970: event["start"] as! TimeInterval / 1000)
										item.end = NSDate(timeIntervalSince1970: event["end"] as! TimeInterval / 1000)
										item.group = event["group"] as? String
										item.title = event["title"] as? String
										item.notes = event["notes"] as? String
										item.instructor = event["instructor"] as? String
										item.uniform = event["uniform"] as? String
										item.location = event["location"] as? String
										schedule.addToItems(item)
									}
								}
							}
							self.loadCount -= 1
						}.resume()
						
						self.schedules.append(schedule)
					}
					self.schedules.sort(by: { lhs, rhs in
						return lhs.start!.compare(rhs.start as! Date) == .orderedDescending
					})
					DispatchQueue.main.async {
						self.tableView.reloadData()
					}
				}
			}
			if let e = err {
				print("Failed to connect to server: \(e)")
				//TODO: alert user
			}
			self.loadCount -= 1
		}.resume()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? 1 : schedules.count
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
			let schedule = schedules[indexPath.row]
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
			if let selectedCell = sender as? UITableViewCell {
				dest.schedule = self.schedules[self.tableView.indexPath(for: selectedCell)!.row]
			}
		}
		super.prepare(for: segue, sender: sender)
    }

}
