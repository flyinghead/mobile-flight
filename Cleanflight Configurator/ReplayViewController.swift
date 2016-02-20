//
//  ReplayViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class ReplayViewController: UITableViewController {
    var replayFiles: [NSURL]?
    var detailedRow = -1

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        detailedRow = -1
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Flight Sessions"
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Tap any flight session to replay it."
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            do {
                guard let urls: [NSURL]? = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsURL, includingPropertiesForKeys: [kCFURLNameKey as String], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles) else {
                    return 0
                }
                replayFiles = urls!
                return urls!.count
            } catch {
                return 0
            }
        default:
            return 0
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == detailedRow {
            return 94
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(indexPath.row == detailedRow ? "DetailedReplayCell" : "ReplayCell", forIndexPath: indexPath) as! DetailedReplayCell
        
        cell.maxAltitudeLabel?.text = ""
        cell.maxSpeedLabel?.text = ""
        cell.maxDistanceLabel?.text = ""
        cell.maxAmpsLabel?.text = ""
        
        switch indexPath.section {
        case 0:
            var title: String?
            var detail = "?"
            if replayFiles != nil && replayFiles!.count > indexPath.row {
                let fileUrl = replayFiles![indexPath.row]
                do {
                    try TryCatch.tryBlock({
                        do {
                            let attrs = try NSFileManager.defaultManager().attributesOfItemAtPath(fileUrl.path!)
                            let date = attrs[NSFileCreationDate] as! NSDate
                            let df = NSDateFormatter()
                            df.dateStyle = .ShortStyle
                            df.timeStyle = .ShortStyle
                            title = df.stringFromDate(date)
                            
                            let (file, stats) = try FlightLogFile.openForReading(fileUrl)
                            file.closeFile()
                            if stats != nil {
                                detail = String(format: "%02d:%02d", Int(stats!.flightTime) / 60, Int(round(stats!.flightTime)) % 60)
                                
                                if indexPath.row == self.detailedRow {
                                    cell.maxAltitudeLabel.text = formatAltitude(stats!.maxAltitude)
                                    cell.maxSpeedLabel.text = formatSpeed(stats!.maxSpeed)
                                    cell.maxDistanceLabel.text = formatDistance(stats!.maxDistanceToHome)
                                    cell.maxAmpsLabel.text = formatWithUnit(stats!.maxAmps, unit: "A")
                                }
                                
                                if stats!.armedDate.timeIntervalSinceReferenceDate > 0 {
                                    title = df.stringFromDate(stats!.armedDate)
                                }
                            }
                        } catch let error as NSError {
                            NSLog("Cannot get attributes of %@: %@", fileUrl, error)
                        }
                    })
                } catch  {
                    // Objective-C exception
                }
                if title == nil {
                    title = fileUrl.lastPathComponent ?? "?"
                }
                cell.flyDate.text = title
                cell.flyTime.text = detail
            }
        default:
            break
        }
        
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        resetAircraftModel()
        
        switch indexPath.section {
        case  0:
            if replayFiles != nil && indexPath.row < replayFiles!.count {
                let fileUrl = replayFiles![indexPath.row]
                
                do {
                    try TryCatch.tryBlock({
                        do {
                            let (file, _) = try FlightLogFile.openForReading(fileUrl)
                            _ = ReplayComm(datalog: file, msp: self.msp)
                            (self.parentViewController as! MainConnectionViewController).presentNextViewController()
                        } catch  {
                            // Swift error
                            SVProgressHUD.showErrorWithStatus("Invalid flight session", maskType: .Black)
                        }
                    })
                } catch  {
                    // Objective-C exception
                    SVProgressHUD.showErrorWithStatus("Invalid flight session", maskType: .Black)
                }
            }
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
            
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        var indexPaths = [NSIndexPath]()
        if detailedRow != -1 {
            indexPaths.append(NSIndexPath(forRow: detailedRow, inSection: 0))
        }
        if detailedRow == indexPath.row {
            detailedRow = -1
        } else {
            detailedRow = indexPath.row
            indexPaths.append(NSIndexPath(forRow: detailedRow, inSection: 0))
        }
        tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Middle)
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if replayFiles != nil && indexPath.row < replayFiles!.count {
                let fileUrl = replayFiles![indexPath.row]
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(fileUrl)
                    // Delete the row from the data source
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    if detailedRow == indexPath.row {
                        detailedRow = -1
                    } else if detailedRow > indexPath.row {
                        detailedRow--
                        tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: detailedRow, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Middle)
                    }
                } catch let error as NSError {
                    NSLog("Cannot delete %@: %@", fileUrl, error)
                    SVProgressHUD.showErrorWithStatus("Cannot delete file")
                }
            }
            
        }
    }
}

class DetailedReplayCell : UITableViewCell {
    @IBOutlet weak var flyDate: UILabel!
    @IBOutlet weak var flyTime: UILabel!
    @IBOutlet weak var maxAltitudeLabel: UILabel!
    @IBOutlet weak var maxSpeedLabel: UILabel!
    @IBOutlet weak var maxDistanceLabel: UILabel!
    @IBOutlet weak var maxAmpsLabel: UILabel!
    
}
