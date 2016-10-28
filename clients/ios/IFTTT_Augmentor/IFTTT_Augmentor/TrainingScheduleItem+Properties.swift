//
//  TrainingScheduleItem+Properties.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/28/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import Foundation

extension TrainingScheduleItem {
	
	var dateRange: String? {
		get {
			let formatter = DateFormatter()
			formatter.dateFormat = "MMM d HH:mm"
			if let s = self.start as? Date, let e = self.end as? Date {
				return "\(formatter.string(from: s)) - \(formatter.string(from: e))"
			} else {
				return nil
			}
		}
	}
	
	var calendarNotes: String? {
		get {
			return "\(self.notes)\n\nGroup: \(self.group)\nUniform: \(self.uniform)\nInstructor: \(self.instructor)"
		}
	}
}
