//
//  TrainingScheduleItemDetailCell.swift
//  IFTTT_Augmentor
//
//  Created by Douglas Wurtele on 10/28/16.
//  Copyright © 2016 Douglas Wurtele. All rights reserved.
//

import UIKit

class TrainingScheduleItemDetailCell: UITableViewCell {
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var uniformLabel: UILabel!
	@IBOutlet weak var groupLabel: UILabel!
	@IBOutlet weak var instructorLabel: UILabel!
	@IBOutlet weak var notesTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
	
	private var _item: TrainingScheduleItem?
	var item: TrainingScheduleItem? {
		get {
			return _item
		}
		
		set {
			self._item = newValue
			if let item = newValue {
				titleLabel.text = item.title
				dateLabel.text = item.dateRange
				locationLabel.text = item.location
				uniformLabel.text = item.uniform
				groupLabel.text = item.group
				instructorLabel.text = item.instructor
				notesTextView.text = item.notes
			} else {
				titleLabel.text = nil
				dateLabel.text = nil
				locationLabel.text = nil
				uniformLabel.text = nil
				groupLabel.text = nil
				instructorLabel.text = nil
				notesTextView.text = ""
			}
		}
	}

}
