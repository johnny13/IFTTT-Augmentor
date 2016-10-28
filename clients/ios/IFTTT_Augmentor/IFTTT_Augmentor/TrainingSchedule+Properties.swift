//
//  TrainingSchedule+Properties.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/28/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import Foundation

extension TrainingSchedule {
	
	var startDate: Date? {
		return self.start as? Date
	}
	
	var endDate: Date? {
		return self.end as? Date
	}
	
	var dateRange: String? {
		get {
			let formatter = DateFormatter()
			formatter.dateFormat = "MMM d, yyyy"
			if let s = self.startDate, let e = self.endDate {
				if s < e {
					return "\(formatter.string(from: s)) - \(formatter.string(from: e))"
				} else {
					return "\(formatter.string(from: s))"
				}
			} else {
				return nil
			}
		}
	}
}
