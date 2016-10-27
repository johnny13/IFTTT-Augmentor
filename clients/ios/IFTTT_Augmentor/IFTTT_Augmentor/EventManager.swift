//
//  EventManager.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/27/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import EventKit
import CoreData

class EventManager {
	private static let ARMY_CALENDAR_KEY = "ARMY_CALENDAR"
	private static var _instance: EventManager?
	
	private class var instance: EventManager {
		if _instance == nil {
			_instance = EventManager()
		}
		return _instance!
	}
	
	private var _store: EKEventStore?
	class var eventStore: EKEventStore {
		if instance._store == nil {
			instance._store = EKEventStore()
		}
		return instance._store!
	}
	
	class var calendars: [EKCalendar] {
		return eventStore.calendars(for: .event)
	}
	
	class var armyCalendar: EKCalendar? {
		let fetchRequest: NSFetchRequest<UserOption> = UserOption.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "key = %@", ARMY_CALENDAR_KEY)
		let app = UIApplication.shared.delegate as! AppDelegate
		
		do {
			let results = try app.context.fetch(fetchRequest)
			if results.count == 1 {
				if let selected = results[0].value {
					for calendar in calendars {
						if calendar.calendarIdentifier == selected {
							return calendar
						}
					}
				}
			}
		} catch {
			print("Failed to load user option: \(error)")
		}
		return nil
	}
}
