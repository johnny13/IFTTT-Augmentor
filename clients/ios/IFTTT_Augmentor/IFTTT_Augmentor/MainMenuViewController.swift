//
//  MainMenuViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/27/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit
import EventKit

class MainMenuViewController: UITableViewController {

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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	private func accessFailed() {
		let alert = UIAlertController(title: "Calendar Access Required", message: "This app cannot function without access to the calendar", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
			UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
		}))
		self.present(alert, animated: true, completion: nil)
	}
}
