//
//  timerSetupVC.swift
//  SleepCounter
//
//  Created by Florian Schweizer on 17.06.18.
//  Copyright © 2018 Florian Schweizer. All rights reserved.
//

import UIKit

class timerSetupVC: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let defaults = UserDefaults.standard
    let calendar = NSCalendar.current
    let date = Date()
    let offsetOptions = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
    var selected = 0
    
    @IBOutlet weak var offsetPicker: UIPickerView!
    @IBOutlet weak var wheel: UIActivityIndicatorView!
    @IBOutlet weak var confirmBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        offsetPicker.delegate = self
        offsetPicker.dataSource = self
        confirmBtn.layer.cornerRadius = 0.5 * confirmBtn.bounds.size.width
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let option = "\(offsetOptions[row])min"
        return option
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return offsetOptions.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selected = row
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmBtnPressed(_ sender: Any) {
        defaults.set(true, forKey: "isRunning")
        wheel.startAnimating()
        
        var dayNow = calendar.component(.day, from: date)
        var monthNow = calendar.component(.month, from: date)
        var yearNow = calendar.component(.year, from: date)
        
        var hourNow = calendar.component(.hour, from: date)
        var minuteNow = calendar.component(.minute, from: date) + offsetOptions[selected]
        
        if minuteNow > 60 {
            minuteNow -= 60
            hourNow += 1
            
            if hourNow > 24 {
                hourNow -= 24
                dayNow += 1
                
                if dayNow == 29 && monthNow == 2 && yearNow % 4 != 0{
                    dayNow = 1
                    monthNow = 3
                } else if dayNow == 30 && monthNow == 2 && yearNow % 4 == 0{
                    dayNow = 1
                    monthNow = 3
                } else if dayNow == 31 && (monthNow == 2 || monthNow == 4 || monthNow == 6 || monthNow == 9 || monthNow == 11){
                    dayNow = 1
                    monthNow += 1
                } else if dayNow == 32 && (monthNow == 1 || monthNow == 3 || monthNow == 5 || monthNow == 7 || monthNow == 8 || monthNow == 10 || monthNow == 12){
                    dayNow = 1
                    monthNow += 1
                    if monthNow > 12 {
                        monthNow = 1
                        yearNow += 1
                    }
                }
            }
        }
        
        defaults.set(dateCompressor(year: yearNow, month: monthNow, day: dayNow), forKey: "startDate")
        defaults.set(compressor(hour: hourNow, minute: minuteNow), forKey: "startTime")
        
        wheel.stopAnimating()
        
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    
    func compressor(hour: Int, minute: Int) -> Int {
        let compromisedNumber = hour * 100 + minute
        return compromisedNumber
    }
    
    func dateCompressor(year: Int, month: Int, day: Int) -> Int {
        let comprDate = day * 1000000 + month * 10000 + year
        return comprDate
    }
    
}
