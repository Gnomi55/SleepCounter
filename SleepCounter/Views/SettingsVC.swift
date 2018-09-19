//
//  SettingsVC.swift
//  SleepCounter
//
//  Created by Florian Schweizer on 17.06.18.
//  Copyright © 2018 Florian Schweizer. All rights reserved.
//

import UIKit

class SettingsVC: UIViewController {

    @IBOutlet weak var goalLbl: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    let defaults = UserDefaults()
    var goal: Int = 0
    var difference: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        goal = defaults.integer(forKey: "goal")
        goalLbl.text = "\(goal)"
        difference = goal - Int(stepper.value)
        goal = Int(stepper.value)
        
        stepper.minimumValue = Double(goal - difference)
    }
    
    
    @IBAction func doneBtnPressed(_ sender: Any) {
        save()
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    @IBAction func saveBtnPressed(_ sender: Any) {
        save()
    }
    
    @IBAction func sleepingGoalChanged(_ sender: Any) {
        goal = Int(stepper.value)
        goalLbl.text = "\(goal + difference)"
    }
    
    func save() {
        goal += difference
        defaults.set(goal, forKey: "goal")
    }
    
}
