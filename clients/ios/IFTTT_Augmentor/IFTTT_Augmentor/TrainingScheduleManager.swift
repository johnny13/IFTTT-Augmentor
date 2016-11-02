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
				return lhs.start!.compare(rhs.start as! Date) == .orderedDescending
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
						schedule.imported = false
						
						instance.loadCount += 1
						URLSession.shared.dataTask(with: URL(string: "\(ServerManager.SERVER_ADDRESS)/schedules/\(sender)/\(file)")!) { data, response, err in
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
						return lhs.start!.compare(rhs.start as! Date) == .orderedDescending
					})
				}
			}
			if let e = err {
				print("Failed to connect to server: \(e)")
				//TODO: alert user
			}
			instance.loadCount -= 1
		}.resume()
	}
	
	class func importSchedule(schedule: TrainingSchedule, completion: (() -> Void)?) {
		if !schedule.imported {
			if let army = EventManager.armyCalendar {
				for item in schedule.items?.allObjects as! Array<TrainingScheduleItem> {
					let event = EKEvent(eventStore: EventManager.eventStore)
					event.calendar = army
					event.title = item.title!
					event.startDate = item.start as! Date
					event.endDate = item.end as! Date
					event.availability = .busy
					event.isAllDay = false
					event.location = item.location
					event.notes = item.calendarNotes
					
					do {
						try EventManager.eventStore.save(event, span: .thisEvent)
					} catch {
						print("Failed to save \(item.title): \(error)")
						//TODO: alert user
					}
				}
				schedule.imported = true
				(UIApplication.shared.delegate as! AppDelegate).saveContext()
			}
		}
		completion?()
	}
	
	class var schedules: Array<TrainingSchedule> {
		get {
			return instance._schedules
		}
	}
}
