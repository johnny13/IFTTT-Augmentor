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
			let n = self.notes != nil ? self.notes! : " "
			let g = self.group != nil ? self.group! : " "
			let u = self.uniform != nil ? self.uniform! : " "
			let i = self.instructor != nil ? self.instructor! : " "
			return "NOTES: \(n)\n\nUniform: \(u)\nGroup: \(g)\nInstructor: \(i)"
		}
	}
}
