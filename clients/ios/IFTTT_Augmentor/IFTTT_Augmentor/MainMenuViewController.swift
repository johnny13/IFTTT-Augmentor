//
//  MainMenuViewController.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/27/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit

class MainMenuViewController: UITableViewController {
	private var loadingView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func viewTrainingSchedule(_ schedule: TrainingSchedule) {
		DispatchQueue.main.async {
			let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
			let controller = storyboard.instantiateViewController(withIdentifier: "TrainingScheduleController") as! TrainingScheduleViewController
			controller.schedule = schedule
			self.navigationController?.pushViewController(controller, animated: true)
		}
	}
}
