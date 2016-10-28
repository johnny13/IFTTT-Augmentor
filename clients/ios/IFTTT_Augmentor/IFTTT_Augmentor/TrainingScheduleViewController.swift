//
//  TrainingScheduleViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/28/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import CoreData
import EventKit

class TrainingScheduleViewController: UITableViewController {
	var schedule: TrainingSchedule!
	private var items: Array<TrainingScheduleItem> = []
	
	@IBOutlet weak var addButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = self.schedule.dateRange
		if self.schedule.imported {
			self.addButton.isEnabled = false
		} else {
			self.addButton.isEnabled = true
		}
		
		self.items = self.schedule.items?.allObjects as! Array<TrainingScheduleItem>
		self.items.sort(by: { lhs, rhs in
			if let lstart = lhs.start as? Date, let rstart = rhs.start as? Date, let lend = rhs.end as? Date, let rend = rhs.end as? Date {
				if lstart == rstart {
					return lend < rend
				}
				return lstart < rstart
			}
			return false
		})
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
		let item = self.items[indexPath.row]
		cell.textLabel?.text = item.title
		cell.detailTextLabel?.text = item.dateRange
        return cell
    }

	@IBAction func addToCalendar(_ sender: UIBarButtonItem) {
		if let army = EventManager.armyCalendar {
			self.navigationItem.title = "Loading..."
			self.navigationController?.view.isUserInteractionEnabled = false
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
			
			for item in self.items {
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
			self.schedule.imported = true
			(UIApplication.shared.delegate as! AppDelegate).saveContext()
			
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			self.navigationController?.view.isUserInteractionEnabled = true
			self.navigationItem.title = self.schedule.dateRange
			let _ = self.navigationController?.popViewController(animated: true)
		} else {
			//TODO: alert with no calendar error
		}
	}
}
