//
//  FinaliseVC.swift
//  SleepCounter
//
//  Created by Florian Schweizer on 21.06.18.
//  Copyright © 2018 Florian Schweizer. All rights reserved.
//

import UIKit
import CoreData

class FinaliseVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var wheel: UIActivityIndicatorView!
    @IBOutlet weak var confirmBtn: UIButton!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let defaults = UserDefaults()
    let calendar = NSCalendar.current
    let date = Date()
    var choisesArray: [Int] = []
    var isSmallerArray: [Bool] = []
    var selectedChoice: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker.delegate = self
        picker.dataSource = self
        confirmBtn.layer.cornerRadius = 0.5 * confirmBtn.bounds.size.width
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    
    @IBAction func trashBtnPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Really want to delete this?", message: "Do you want to delete your sleeptime or continue sleeping?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "continue", style: .default, handler: { action in self.dismiss(animated: true, completion: nil)}))
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "delete", style: .destructive, handler: { action in
            self.defaults.set(false, forKey: "isRunning")
            self.performSegue(withIdentifier: "toHome", sender: nil)
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func confirmBtnPressed(_ sender: Any) {
        wheel.startAnimating()
        let newTime = Time(context: context)
        newTime.beginningDate = Int32(defaults.integer(forKey: "startDate"))
        newTime.beginningTime = Int16(defaults.integer(forKey: "startTime"))
        
        let dateNow = getCurrentDate()
        var yeartoUse = dateNow[2]
        var monthtoUse = dateNow[1]
        var daytoUse = dateNow[0]
        
        if isSmallerArray[selectedChoice] {
            daytoUse -= 1
            if daytoUse < 1 {
                monthtoUse -= 1
                if monthtoUse < 1{
                    yeartoUse -= 1
                    monthtoUse = 12
                    daytoUse = 31
                } else {
                    if monthtoUse == 1 || monthtoUse == 3 || monthtoUse == 5 || monthtoUse == 7 || monthtoUse == 8 || monthtoUse == 10{
                        daytoUse = 31
                    } else {
                        daytoUse = 30
                    }
                }
            }
        }
        
        let endingDate = Int32(dateCompressor(year: yeartoUse, month: monthtoUse, day: daytoUse))
        newTime.endDate = endingDate
        
        let timesToUse = decompress(timeNumber: choisesArray[selectedChoice])
        newTime.endTime = Int16(compressor(hour: timesToUse[0], minute: timesToUse[1]))
        
        let startTimes = decompress(timeNumber: defaults.integer(forKey: "startTime"))
        
        var hours: Int = 0
        var minutes: Int = 0
        let beginningDate = decompressDate(comprDate: defaults.integer(forKey: "startDate"))
        if  beginningDate[0] == dateNow[0]{
            hours = timesToUse[0] - startTimes[0]
        } else {
            hours = 24 - startTimes[0] + timesToUse[0]
        }
        if timesToUse[1] > startTimes[1] {
            minutes = timesToUse[1] - startTimes[1]
        } else {
            minutes = 60 - startTimes[1] + timesToUse[1]
            hours -= 1
        }
        
        let newSleepTime = Int16(compressor(hour: hours, minute: minutes))
        newTime.totalSleepTime = newSleepTime
        
        
        print(newSleepTime)
        
        saveItems()
        
        if newSleepTime < 0 {
            var lastSave: [Time] = []
            let request1 : NSFetchRequest<Time> = Time.fetchRequest()
            do {
                lastSave = try context.fetch(request1)
            } catch {
                print("Error fetching data from context \(error)")
            }
            print(lastSave[lastSave.count].totalSleepTime)
            context.delete(lastSave[lastSave.count])
            saveItems()
        }
        
        defaults.set(false, forKey: "isRunning")
        wheel.stopAnimating()
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 30
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedChoice = row
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return createTitle(row: row)
    }
    
    func decompress(timeNumber: Int) ->[Int]{
        let minute = timeNumber % 100
        let hour = (timeNumber - minute) / 100
        let timeArray = [hour, minute]
        return timeArray
    }
    
    func calculateTime(startTime: Int, endTime: Int, startDate: Int) -> [Int] {
        let startTimeArray = decompress(timeNumber: startTime)
        let endTimeArray = decompress(timeNumber: endTime)
        
        let dayNow = calendar.component(.day, from: date)
        var hours: Int = 0
        var minutes: Int = 0
        let beginningDate = decompressDate(comprDate: defaults.integer(forKey: "startDate"))
        if  beginningDate[0] == dayNow{
            hours = endTimeArray[0] - startTimeArray[0]
        } else {
            hours = 24 - startTimeArray[0] + endTimeArray[0]
        }
        if endTimeArray[1] > startTimeArray[1] {
            minutes = endTimeArray[1] - startTimeArray[1]
        } else {
            minutes = 60 - startTimeArray[1] + endTimeArray[1]
            hours -= 1
        }
        
        let finalArray = [hours, minutes]
        
        return finalArray
    }
    
    func compressor(hour: Int, minute: Int) -> Int {
        let compromisedNumber = hour * 100 + minute
        return compromisedNumber
    }
    
    func getCurrentTime() -> [Int] {
        let hourNow = calendar.component(.hour, from: date)
        let minuteNow = calendar.component(.minute, from: date)
        
        let currentTime = [hourNow, minuteNow]
        
        return currentTime
    }
    
    // MARK: - handle Date functions
    
    func getCurrentDate() -> [Int]{
        let dayNow = calendar.component(.day, from: date)
        let monthNow = calendar.component(.month, from: date)
        let yearNow = calendar.component(.year, from: date)
        
        let dateNow = [dayNow, monthNow, yearNow]
        
        return dateNow
    }
    
    func dateCompressor(year: Int, month: Int, day: Int) -> Int {
        let comprDate = day * 1000000 + month * 10000 + year
        return comprDate
    }
    
    func decompressDate(comprDate: Int) -> [Int] {
        let year = comprDate % 10000
        let month = ((comprDate - year) / 10000) % 100
        let day = (comprDate - (comprDate % 1000000)) / 1000000
        
        let dateArray = [day, month, year]
        
        return dateArray
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving content \(error)")
        }
    }
    
    
    func createTitle(row: Int) -> String {
        let hourNow = calendar.component(.hour, from: date)
        let minuteNow = calendar.component(.minute, from: date)
        
        var minute = minuteNow - 5 * row
        var hour = hourNow
        var minuteText = ""
        var isSmaller = false
        
        if minute < 0 {
            if minute < -60 {
                minute = 120 + minute
                hour = hourNow - 2
                
                if hour < 0 {
                    hour = 23
                    isSmaller = true
                }
            } else {
                minute = 60 + minute
                hour = hourNow - 1
            
                if hour < 0 {
                    hour = 23
                    isSmaller = true
                }
            }
        }
        
        choisesArray.append(compressor(hour: hour, minute: minute))
        isSmallerArray.append(isSmaller)
        
        if minute < 10 {
            minuteText = "0\(minute)"
        } else {
            minuteText = "\(minute)"
        }
        
        return "\(hour):\(minuteText)"
    }
    func checkGoal(sleepingTime: Int16) -> Bool{
        let goal = defaults.integer(forKey: "goal")
        let sleepTime = decompress(timeNumber: Int(sleepingTime))
        
        if goal - sleepTime[0] < 1 || (goal - sleepTime[0] == 1 && sleepTime[1] > 0) {
            return true
        } else {
            return false
        }
    }
    
}
