//
//  RootNavigationViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 11/1/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import EventKit

class RootNavigationViewController: UINavigationController {

    override func viewDidLoad() {
		super.viewDidLoad()
		
		switch EKEventStore.authorizationStatus(for: .event) {
		case .notDetermined:
			EventManager.eventStore.requestAccess(to: .event, completion: { granted, error in
				if !granted || error != nil {
					DispatchQueue.main.async {
						self.accessFailed()
					}
				}
			})
		case .restricted, .denied:
			self.accessFailed()
		default:
			break
		}
		
		switch EKEventStore.authorizationStatus(for: .reminder) {
		case .notDetermined:
			EventManager.eventStore.requestAccess(to: .reminder, completion: { granted, error in
				if !granted || error != nil {
					DispatchQueue.main.async {
						self.accessFailed()
					}
				}
			})
		case .restricted, .denied:
			self.accessFailed()
		default:
			break
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
	}
	
	private func accessFailed() {
		let alert = UIAlertController(title: "Calendar & Reminder Access Required", message: "This app cannot function without access to the calendar and reminders", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
			UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
		}))
		self.present(alert, animated: true, completion: nil)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
