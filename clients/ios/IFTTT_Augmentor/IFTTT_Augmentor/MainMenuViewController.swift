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
		self.performSegue(withIdentifier: "TrainingScheduleSegue", sender: schedule)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let schedule = sender as? TrainingSchedule {
			if let dest = segue.destination as? TrainingSchedulesViewController {
				dest.forward(schedule)
			}
		}
		super.prepare(for: segue, sender: sender)
	}
	
	func showLoadingView() {
		self.loadingView = UIView(frame: CGRect(origin: CGPoint.zero, size: (self.view.window?.bounds.size)!))
		self.loadingView?.backgroundColor = UIColor.white
		//TODO: add content to loading view
		self.navigationController?.view.addSubview(self.loadingView!)
	}
	
	func hideLoadingView() {
		if let view = self.loadingView {
			view.removeFromSuperview()
		}
	}
}
