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
    @IBOutlet weak var magnifGlasBtn: UIBarButtonItem!
    @IBOutlet weak var topHalf: UIView!
    @IBOutlet weak var bottomHalf: UIView!
    @IBOutlet weak var lbl1: UILabel!
    @IBOutlet weak var lbl2: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshUI()
    }
    
    @IBAction func btnPressed(_ sender: Any) {
        let timer = defaults.bool(forKey: "isRunning")
        if timer {
            let alert = UIAlertController(title: "Stop timer?", message: "Do you want to stop the timer and save the Sleeptime?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in self.checkDates()}))
            alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            defaults.set(true, forKey: "isRunning")
            var temp = getCurrentTime()
            defaults.set(compressor(hour: temp[0], minute: temp[1]), forKey: "startTime")
            temp = getCurrentDate()
            defaults.set(dateCompressor(year: temp[0], month: temp[1], day: temp[2]), forKey: "startDate")
            refreshUI()
        }
    }
    
    @IBAction func refreshBtnPressed(_ sender: Any) {
        refreshUI()
    }
    
    // MARK: - functions
    
    func refreshUI() {
        var average = decompress(timeNumber: Int(defaults.integer(forKey: "average")))
        
        actionBtn.layer.cornerRadius = 0.5 * actionBtn.bounds.size.width
        
        // checking if timer is running
        let timer = defaults.bool(forKey: "isRunning")
        if timer { //if running
            mainView.backgroundColor = UIColor.blue
            navigationBar.barTintColor = UIColor.blue
            magnifGlasBtn.tintColor = UIColor.white
            topHalf.backgroundColor = UIColor.blue
            bottomHalf.backgroundColor = UIColor.blue
            lbl1.textColor = UIColor.white
            lbl2.textColor = UIColor.white
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
            var timeSleeping = calculateTime(startTime: sleepStartTime, endTime: compressor(hour: hour, minute: minute), startDate: calendar.component(.day, from: date))
            if timeSleeping[0] == 24 {
                timeSleeping[0] = 0
            }
            if timeSleeping[1] == 60 {
                timeSleeping[1] = 0
            }
            lbl2.text = "sleeping for: \(timeSleeping[0])h \(timeSleeping[1])min"
            actionBtn.setTitle("End Timer", for: .normal)
            
        } else { //if not running
            mainView.backgroundColor = UIColor.cyan
            navigationBar.barTintColor = UIColor.cyan
            magnifGlasBtn.tintColor = UIColor.black
            topHalf.backgroundColor = UIColor.cyan
            bottomHalf.backgroundColor = UIColor.cyan
            lbl1.textColor = UIColor.black
            lbl2.textColor = UIColor.black
            var lastSleep : [Time] = []
            let request : NSFetchRequest<Time> = Time.fetchRequest()
            do {
                lastSleep = try context.fetch(request)
            } catch {
                print("Error fetching data from context \(error)")
            }
            
            saveItems()
            
            if lastSleep.count > 0 {
                
                let timeArray = decompress(timeNumber: Int(lastSleep[lastSleep.count - 1].totalSleepTime))
                
                lbl1.text = "Last sleep: \(timeArray[0])h, \(timeArray[1])min"
                
                
                
                lbl2.text = "average sleeptime: \(average[0])h \(average[1])min"
                
                actionBtn.setTitle("Start Timer", for: .normal)
            } else {
                lbl1.text = "No Sleeptime found"
                
                
                lbl2.text = ""
                actionBtn.setTitle("Start Timer", for: .normal)
            }
            
        }
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    }
    
    func checkDates() {
        // MARK: - insert funktion to save time
        var savedTimes: [Time] = []
        
        let request : NSFetchRequest<Time> = Time.fetchRequest()
        do {
            savedTimes = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        saveItems()
        
        let today = getCurrentDate()
        
        if savedTimes.count > 0 {
        
            if dateCompressor(year: today[0], month: today[1], day: today[2]) == savedTimes[0].endDate {
                let alert = UIAlertController(title: "Override Sleeptime", message: "You already have saved one Sleeptime today. Do you want to override it?",  preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "Keep old Time", style: .default, handler: { action in self.defaults.set(false, forKey: "isRunning")
                                                                                                            self.refreshUI()}))
                alert.addAction(UIAlertAction(title: "Override", style: .destructive, handler: { action in  self.adjustAverage(lastTime: Int(savedTimes[0].totalSleepTime))
                                                                                                            self.context.delete(savedTimes[0])
                                                                                                            self.saveItems()
                                                                                                            self.processTimer()}))
                alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            } else {
                processTimer()
            }
        } else {
            processTimer()
        }
    }
    
    func processTimer() {
        let newTime = Time(context: context)
        newTime.beginningDate = Int32(defaults.integer(forKey: "startDate"))
        newTime.beginningTime = Int16(defaults.integer(forKey: "startTime"))
        var endDate = getCurrentDate()
        newTime.endDate = Int32(dateCompressor(year: endDate[0], month: endDate[1], day: endDate[2]))
        var endTime = getCurrentTime()
        newTime.endTime = Int16(compressor(hour: endTime[0], minute: endTime[1]))
        
        var hour = 0
        var minute = 0
        var beginningTimes = decompress(timeNumber: defaults.integer(forKey: "startTime"))
        
        hour = endTime[0] - beginningTimes[0]
        if endTime[0] < beginningTimes[0] {
            hour += 24
        }
        minute = endTime[1] - beginningTimes[1]
        if endTime[1] < beginningTimes[1] {
            minute += 60
            hour -= 1
        }
        
        if endTime[0] == beginningTimes[0] && endTime[1] == beginningTimes[1] {
            hour = 0
            minute = 0
        }
        
        newTime.totalSleepTime = Int16(compressor(hour: hour, minute: minute))
        
        let average = decompress(timeNumber: Int(defaults.integer(forKey: "average")))
        
        let hourAverage = average[0] + 1/2 * (hour - average[0])
        let minuteAverage = average[1] + 1/2 * (minute - average[1])
        
        defaults.set(returnTimeFormat(hour: hourAverage, minute: minuteAverage), forKey: "average")
        
        saveItems()
        
        defaults.set(false, forKey: "isRunning")
        
        refreshUI()
    }
    
    func adjustAverage(lastTime: Int) {
        let average = decompress(timeNumber: defaults.integer(forKey: "average"))
        let lastTimes = decompress(timeNumber: lastTime)
        
        let hourAverage = 2 * average[0] - lastTimes[0]
        let minuteAverage = 2 * average[1] - lastTimes[1]
        
        defaults.set(compressor(hour: hourAverage, minute: minuteAverage), forKey: "average")
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving content \(error)")
        }
    }
    
    // MARK: - handle time
    
    func returnTimeFormat(hour: Int, minute: Int) -> Int {
        var trueHour = hour
        var trueMinute = minute
        
        if minute > 60 {
            trueHour += 1
            trueMinute -= 60
        } else if minute < 0 {
            trueHour -= 0
            trueMinute += 60
        }
        
        if trueHour < 0 {
            trueHour = 0
        }
        
        return compressor(hour: trueHour, minute: trueMinute)
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
        if endTimeArray[1] < startTimeArray[1] {
            minutes = 60 - startTimeArray[1] + endTimeArray[1]
            hours -= 1
        } else {
            minutes = endTimeArray[1] - startTimeArray[1]
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
