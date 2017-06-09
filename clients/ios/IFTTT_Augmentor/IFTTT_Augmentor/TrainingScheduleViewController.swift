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
	private var selectedCell: IndexPath?
	
	@IBOutlet weak var addButton: UIBarButtonItem!
	@IBOutlet weak var deleteButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.navigationItem.title = self.schedule.dateRange
		if self.schedule.imported {
			self.navigationItem.rightBarButtonItems?.removeFirst()
		} else {
			self.navigationItem.rightBarButtonItems?.removeLast()
		}
		
		self.items = self.schedule.items?.allObjects as! Array<TrainingScheduleItem>
		self.items.sort(by: { lhs, rhs in
			if let lstart = lhs.start as Date?, let rstart = rhs.start as Date?, let lend = rhs.end as Date?, let rend = rhs.end as Date? {
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
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return tableView.indexPathForSelectedRow == indexPath ? 205.0 : 44.0
	}

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if selectedCell != nil && selectedCell! == indexPath {
			let cell = tableView.dequeueReusableCell(withIdentifier: "EventCellDetail", for: indexPath) as! TrainingScheduleItemDetailCell
			cell.item = self.items[indexPath.row]
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
			let item = self.items[indexPath.row]
			cell.textLabel?.text = item.title
			cell.detailTextLabel?.text = item.dateRange
			return cell
		}
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if selectedCell != nil && selectedCell! == indexPath {
			tableView.deselectRow(at: indexPath, animated: true)
			selectedCell = nil
			tableView.reloadRows(at: [indexPath], with: .automatic)
		} else if selectedCell != nil && selectedCell! != indexPath {
			let deselected = IndexPath(row: selectedCell!.row, section: selectedCell!.section)
			selectedCell = indexPath
			tableView.deselectRow(at: deselected, animated: true)
			tableView.reloadRows(at: [deselected, indexPath], with: .automatic)
			tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		} else {
			selectedCell = indexPath
			tableView.reloadRows(at: [indexPath], with: .automatic)
			tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
		}
		tableView.beginUpdates()
		tableView.endUpdates()
	}

	@IBAction func addToCalendar(_ sender: UIBarButtonItem) {
		self.navigationItem.title = "Loading..."
		self.navigationController?.view.isUserInteractionEnabled = false
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		TrainingScheduleManager.importSchedule(schedule: self.schedule, completion: { imported in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			self.navigationController?.view.isUserInteractionEnabled = true
			self.navigationItem.title = self.schedule.dateRange
			let _ = self.navigationController?.popViewController(animated: true)
		})
	}
	
	@IBAction func removeFromCalendar(_ sender: UIBarButtonItem) {
		self.navigationItem.title = "Loading..."
		self.navigationController?.view.isUserInteractionEnabled = false
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		
		TrainingScheduleManager.removeSchedule(schedule: self.schedule, completion: { removed in
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			self.navigationController?.view.isUserInteractionEnabled = true
			self.navigationItem.title = self.schedule.dateRange
			let _ = self.navigationController?.popViewController(animated: true)
		})
	}
}
