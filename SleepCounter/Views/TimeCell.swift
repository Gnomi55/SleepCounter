//
//  TimeCell.swift
//  SleepCounter
//
//  Created by Florian Schweizer on 11.07.18.
//  Copyright © 2018 Florian Schweizer. All rights reserved.
//

import UIKit

class TimeCell: UITableViewCell {
    
    @IBOutlet weak var indicatorLbl: UILabel!
    @IBOutlet weak var additionalData: UILabel!
    
    
    func getTime(time: Times) {
        indicatorLbl.text = time.indicator
        additionalData.text = time.additionalData
    }
    
}
