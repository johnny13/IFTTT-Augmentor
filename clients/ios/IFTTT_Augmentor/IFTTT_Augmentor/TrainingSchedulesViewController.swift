//
//  TrainingSchedulesViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/26/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import CoreData

class TrainingSchedulesViewController: UITableViewController {
	private var schedules: Array<TrainingSchedule> = []

    override func viewDidLoad() {
        super.viewDidLoad()
		
		let app = UIApplication.shared.delegate as! AppDelegate
		let context = app.context
		
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		var request = URLRequest(url: URL(string: "http://localhost:8080/IFTTT/api/schedules")!)
		request.httpMethod = "GET"
		URLSession.shared.dataTask(with: request) { data, response, err in
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
								self.schedules.append(results[0])
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
						self.schedules.append(schedule)
					}
					do {
						try context.save()
					} catch {
						print("Failed to save context: \(error)")
					}
					DispatchQueue.main.async {
						self.tableView.reloadData()
						UIApplication.shared.isNetworkActivityIndicatorVisible = false
					}
				}
			}
		}.resume()
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
        return schedules.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainingScheduleCell", for: indexPath)
		let schedule = schedules[indexPath.row]
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM dd, yyyy"
		if (schedule.start?.compare(schedule.end as! Date) == .orderedAscending) {
			cell.textLabel?.text = formatter.string(from: schedule.start as! Date) + " - " + formatter.string(from: schedule.end as! Date)
		} else {
			cell.textLabel?.text = formatter.string(from: schedule.start as! Date)
		}
		cell.detailTextLabel?.text = schedule.file
		if (schedule.imported) {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .disclosureIndicator
		}
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
