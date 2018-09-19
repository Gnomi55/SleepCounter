//
//  ViewController.swift
//  SleepCounter
//
//  Created by Florian Schweizer on 14.06.18.
//  Copyright © 2018 Florian Schweizer. All rights reserved.
//

import UIKit
import CoreData

class homeVC: UIViewController {
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let defaults = UserDefaults.standard
    var lastSleepTest : Int32 = 0
    var pressed = false
    
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var settingsBtn: UIBarButtonItem!
    @IBOutlet weak var magnifGlasBtn: UIBarButtonItem!
    @IBOutlet weak var topHalf: UIView!
    @IBOutlet weak var bottomHalf: UIView!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var refreshBtnOutlet: UIButton!
    @IBOutlet weak var actionBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI()
    }
    
    @IBAction func btnPressed(_ sender: Any) {
        let timer = defaults.bool(forKey: "isRunning")
        if timer {
            performSegue(withIdentifier: "toFinalize", sender: nil)
        } else {
            performSegue(withIdentifier: "toTimer", sender: nil)
        }
    }
    
    @IBAction func refreshBtn(_ sender: Any) {
        print("refresh pressed")
        refreshUI()
    }
    
    // MARK: - functions
    
    func refreshUI() {
        var goal = defaults.integer(forKey: "goal")
        if goal == 0 {
            goal = 6
        }
        
        actionBtn.layer.cornerRadius = 0.5 * actionBtn.bounds.size.width
        
        // checking if timer is running
        let timer = defaults.bool(forKey: "isRunning")
        if timer { //if running
            mainView.backgroundColor = UIColor.blue
            navigationBar.barTintColor = UIColor.blue
            settingsBtn.tintColor = UIColor.white
            magnifGlasBtn.tintColor = UIColor.white
            topHalf.backgroundColor = UIColor.blue
            bottomHalf.backgroundColor = UIColor.blue
            lbl1.textColor = UIColor.white
            lbl2.textColor = UIColor.white
            refreshBtnOutlet.isHidden = false
            refreshBtnOutlet.layer.cornerRadius = 0.02 * refreshBtnOutlet.bounds.size.width
            let sleepStartTime = defaults.integer(forKey: "startTime")
            var timeArray = decompress(timeNumber: sleepStartTime)
            var minuteText = ""
            if timeArray[1] < 10 {
                minuteText = "0\(timeArray[1])"
            } else {
                minuteText = "\(timeArray[1])"
            }
            lbl1.text = "Sleeping since: \(timeArray[0]):\(minuteText)"
            
            let calendar = NSCalendar.current
            let date = Date()
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            print("\(hour):\(minute)")
            let timeSleeping = calculateTime(startTime: sleepStartTime, endTime: compressor(hour: hour, minute: minute), startDate: calendar.component(.day, from: date))
            lbl2.text = "sleeping for: \(timeSleeping[0])h \(timeSleeping[1])min"
            actionBtn.setTitle("End Timer", for: .normal)
            
        } else { //if not running
            mainView.backgroundColor = UIColor.cyan
            navigationBar.barTintColor = UIColor.cyan
            settingsBtn.tintColor = UIColor.black
            magnifGlasBtn.tintColor = UIColor.black
            topHalf.backgroundColor = UIColor.cyan
            bottomHalf.backgroundColor = UIColor.cyan
            lbl1.textColor = UIColor.black
            lbl2.textColor = UIColor.black
            refreshBtnOutlet.isHidden = true
            var lastSleep : [Time] = []
            var lastDay : [Days] = []
            let request : NSFetchRequest<Time> = Time.fetchRequest()
            do {
                lastSleep = try context.fetch(request)
            } catch {
                print("Error fetching data from context \(error)")
            }
            let request1 : NSFetchRequest<Days> = Days.fetchRequest()
            do {
                lastDay = try context.fetch(request1)
            } catch {
                print("Error fetching data from context \(error)")
            }
            
            saveItems()
            
            if lastSleep.count > 0 {
                
                let timeArray = decompress(timeNumber: Int(lastSleep[lastSleep.count - 1].totalSleepTime))
                
                lbl1.text = "Last sleep: \(timeArray[0])h, \(timeArray[1])min"
                
                let lastDate = decompressDate(comprDate: Int(lastSleep[lastSleep.count - 1].endDate))
                print(lastDate)
                let calendar = NSCalendar.current
                let date = Date()
                let dateNow = calendar.component(.day, from: date)
                
                if lastDay.count > 0 {
                    let lastDaySleepTime = decompress(timeNumber: Int(lastDay[lastDay.count - 1].totalSleepTime))
                    
                    if dateNow == lastDate[0] {
                        if lastDay[lastDay.count - 1].goalReached{
                            lbl2.text = "daily goal reached!"
                        } else {
                            let hours = goal - lastDaySleepTime[0]
                            if lastDaySleepTime[1] > 0{
                                lbl2.text = "sleep \(hours - 1)h and \(60 - lastDaySleepTime[1])min for goal"
                            } else {
                                lbl2.text = "sleep \(hours)h for goal"
                            }
                        }
                    } else {
                        lbl2.text = "sleep \(goal)h for goal"
                    }
                }
                
                if dateNow == lastDate[0] {
                    if goal - timeArray[0] < 1 || (goal - timeArray[0] == 1 && timeArray[1] > 0){
                        lbl2.text = "daily goal reached!"
                    } else {
                        let hours = goal - timeArray[0]
                        if timeArray[1] > 0{
                            lbl2.text = "sleep \(hours - 1)h and \(60 - timeArray[1])min for goal"
                        } else {
                            lbl2.text = "sleep \(hours)h for goal"
                        }
                    }
                } else {
                    lbl2.text = "sleep \(goal)h for goal"
                }
                
                actionBtn.setTitle("Start Timer", for: .normal)
            } else {
                lbl1.text = "No Sleeptime found"
                
                
                lbl2.text = "sleep \(goal)h for goal"
                actionBtn.setTitle("Start Timer", for: .normal)
            }
            
        }
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving content \(error)")
        }
    }
    
    // MARK: - handle time
    
    func decompress(timeNumber: Int) ->[Int]{
        let minute = timeNumber % 100
        let hour = (timeNumber - minute) / 100
        let timeArray = [hour, minute]
        return timeArray
    }
    
    func calculateTime(startTime: Int, endTime: Int, startDate: Int) -> [Int] {
        let startTimeArray = decompress(timeNumber: startTime)
        let endTimeArray = decompress(timeNumber: endTime)
        
        let calendar = NSCalendar.current
        let date = Date()
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
        
        if hours < 0 {
            hours += 1
            minutes = (60 - minutes) * -1
        }
        
        let finalArray = [hours, minutes]
        
        return finalArray
    }
    
    func compressor(hour: Int, minute: Int) -> Int {
        let compromisedNumber = hour * 100 + minute
        return compromisedNumber
    }
    
    func getCurrentTime() -> [Int] {
        let calendar = NSCalendar.current
        let date = Date()
        let hourNow = calendar.component(.hour, from: date)
        let minuteNow = calendar.component(.minute, from: date)
        
        let currentTime = [hourNow, minuteNow]
        
        return currentTime
    }
    
    // MARK: - handle Date functions
    
    func getCurrentDate() -> [Int]{
        let calendar = NSCalendar.current
        let date = Date()
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
    
}
