//
//  SleepTimes.swift
//  SleepCounter
//
//  Created by Florian Schweizer on 17.06.18.
//  Copyright © 2018 Florian Schweizer. All rights reserved.
//

import UIKit
import CoreData

class SleepTimes: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var table: UITableView!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let defaults = UserDefaults.standard
    var sleepData: [Time] = []
    var dayData: [Days] = []
    var tableData: [Times] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.delegate = self
        table.dataSource = self
        
        let request0 : NSFetchRequest<Time> = Time.fetchRequest()
        do {
            sleepData = try context.fetch(request0)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        let request1 : NSFetchRequest<Days> = Days.fetchRequest()
        do {
            dayData = try context.fetch(request1)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        if sleepData.count > 0 {
            saveItems()
            print(sleepData[0])
        
            for data in sleepData {
                var temp = decompressDate(comprDate: Int(data.beginningDate))
                var temp0 = decompressDate(comprDate: Int(data.endDate))
                let indicatorText = "\(temp[2])/\(temp[1]) - \(temp0[2])/\(temp0[1])"
                
                let sleeptime = decompress(timeNumber: Int(data.totalSleepTime))
                
                let sleepTimeText = "\(sleeptime[0])h \(sleeptime[1])min"
                
                tableData.append(Times(indicator: indicatorText, additionalData: sleepTimeText))
            }
        }
    }
    
    @IBAction func backBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = tableData[tableData.count - (indexPath.row + 1)]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeCell") as! TimeCell
        
        cell.getTime(time: data)
        
        if cell.additionalData.text == "Goal reached!" || cell.additionalData.text == "Goal not reached" {
            cell.backgroundColor = UIColor.lightGray
        }
        
        return cell
    }
    
    func saveItems() {
        do {
            try context.save()
        } catch {
            print("Error saving content \(error)")
        }
    }
    
    func decompressDate(comprDate: Int) -> [Int] {
        let year = comprDate % 10000
        let month = ((comprDate - year) / 10000) % 100
        let day = (comprDate - (comprDate % 1000000)) / 1000000
        
        let dateArray = [day, month, year]
        
        return dateArray
    }
    func decompress(timeNumber: Int) ->[Int]{
        let minute = timeNumber % 100
        let hour = (timeNumber - minute) / 100
        let timeArray = [hour, minute]
        return timeArray
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
    func getLblData(data: Time) -> [String] {
        let lastBeginning = decompress(timeNumber: Int(data.beginningTime))
        let lastEnding = decompress(timeNumber: Int(data.endTime))
        var minuteTexts: [String] = []
        var minuteText = ""
        
        if lastBeginning[1] < 10 {
            minuteText = "0\(lastBeginning[1])"
        } else {
            minuteText = "\(lastBeginning[1])"
        }
        minuteTexts.append(minuteText)
        if lastEnding[1] < 10 {
            minuteText = "0\(lastEnding[1])"
        } else {
            minuteText = "\(lastEnding[1])"
        }
        minuteTexts.append(minuteText)
        
        let indicatorText = "\(lastBeginning[0]):\(minuteTexts[0]) - \(lastEnding[0]):\(minuteTexts[1])"
        
        let lastTimes = decompress(timeNumber: Int(data.totalSleepTime))
        
        let additionalText = "\(lastTimes[0])h \(lastTimes[1])min"
        
        let finalArray = [indicatorText, additionalText]
        
        return finalArray
    }
}
