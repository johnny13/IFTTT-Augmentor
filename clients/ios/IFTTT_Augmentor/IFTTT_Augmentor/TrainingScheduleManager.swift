//
//  TrainingScheduleManager.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/31/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class TrainingScheduleManager {
	private static var _instance: TrainingScheduleManager?
	
	private var _schedules: Array<TrainingSchedule> = []
	private var _completion: ((_ schedules: Array<TrainingSchedule>) -> Void)?
	
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
				TrainingScheduleManager.instance._completion?(TrainingScheduleManager.instance._schedules)
			} else {
				UIApplication.shared.isNetworkActivityIndicatorVisible = true
			}
		}
	}
	
	private class var instance: TrainingScheduleManager {
		if _instance == nil {
			_instance = TrainingScheduleManager()
			
			let app = UIApplication.shared.delegate as! AppDelegate
			let context = app.context
			
			let fetchRequest: NSFetchRequest<TrainingSchedule> = TrainingSchedule.fetchRequest()
			_instance!._schedules = try! context.fetch(fetchRequest)
			_instance!._schedules.sort(by: { lhs, rhs in
				return lhs.start!.compare(rhs.start! as Date) == .orderedDescending
			})
		}
		return _instance!
	}
	
	class func loadTrainingSchedules(completion: ((_ schedules: Array<TrainingSchedule>) -> Void)?) {
		instance._completion = completion
		let app = UIApplication.shared.delegate as! AppDelegate
		let context = app.context
		
		instance.loadCount = 1
		URLSession.shared.dataTask(with: URL(string: "\(ServerManager.SERVER_ADDRESS)/schedules")!) { data, response, err in
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
						
						instance.loadCount += 1
						let encodedFile = file.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
						let urlString = "\(ServerManager.SERVER_ADDRESS)/schedules/\(sender)/\(encodedFile)"
						URLSession.shared.dataTask(with: URL(string: urlString)!) { data, response, err in
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
							instance.loadCount -= 1
						}.resume()
						
						instance._schedules.append(schedule)
					}
					instance._schedules.sort(by: { lhs, rhs in
						return lhs.start!.compare(rhs.start! as Date) == .orderedDescending
					})
				}
			}
			if let e = err {
				print("Failed to connect to server: \(e)")
				let alert = UIAlertController(title: "Error", message: "Failed to connect to the server", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				UIApplication.shared.delegate?.window!?.rootViewController?.present(alert, animated: true, completion: nil)
			}
			instance.loadCount -= 1
		}.resume()
	}
	
	class func importSchedule(schedule: TrainingSchedule, completion: ((_ imported: Bool) -> Void)?) {
		var imported = false
		if !schedule.imported {
			if let army = EventManager.armyCalendar {
				for item in schedule.items?.allObjects as! Array<TrainingScheduleItem> {
					let event = EKEvent(eventStore: EventManager.eventStore)
					event.calendar = army
					event.title = item.title!
					event.startDate = item.start! as Date
					event.endDate = item.end! as Date
					event.availability = .busy
					event.isAllDay = false
					event.location = item.location
					event.notes = item.calendarNotes
					
					do {
						try EventManager.eventStore.save(event, span: .thisEvent)
						item.event = event.eventIdentifier
					} catch {
						print("Failed to save \(String(describing: item.title)): \(error)")
						let alert = UIAlertController(title: "Error", message: "Failed to save \(String(describing: item.title))", preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
						UIApplication.shared.delegate?.window!?.rootViewController?.present(alert, animated: true, completion: nil)
					}
				}
				(UIApplication.shared.delegate as! AppDelegate).saveContext()
				imported = true
			}
		}
		completion?(imported)
	}
	
	class func removeSchedule(schedule: TrainingSchedule, completion: ((_ removed: Bool) -> Void)?) {
		var removed = false
		if schedule.imported {
			do {
				for item in schedule.items?.allObjects as! Array<TrainingScheduleItem> {
					if let identifier = item.event {
						if let event = EventManager.eventStore.event(withIdentifier: identifier) {
							try EventManager.eventStore.remove(event, span: .thisEvent)
							item.event = nil
						}
					}
				}
				try EventManager.eventStore.commit()
				(UIApplication.shared.delegate as! AppDelegate).saveContext()
				removed = true
			} catch {
				print("Failed to delete training schedule events: \(error)")
				let alert = UIAlertController(title: "Error", message: "Failed to delete training schedule events", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
				UIApplication.shared.delegate?.window!?.rootViewController?.present(alert, animated: true, completion: nil)
			}
		}
		completion?(removed)
	}
	
	class var schedules: Array<TrainingSchedule> {
		get {
			return instance._schedules
		}
	}
	
	class func getScheduleWithIdentifier(_ id: String!) -> TrainingSchedule? {
		for schedule in schedules {
			if schedule.file == id {
				return schedule
			}
		}
		return nil
	}
}
