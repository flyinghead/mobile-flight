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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ReplayCell", forIndexPath: indexPath)
        
        switch indexPath.section {
        case 0:
            var title: String?
            var detail: String?
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
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = detail
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

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if replayFiles != nil && indexPath.row < replayFiles!.count {
                let fileUrl = replayFiles![indexPath.row]
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(fileUrl)
                    // Delete the row from the data source
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                } catch let error as NSError {
                    NSLog("Cannot delete %@: %@", fileUrl, error)
                    SVProgressHUD.showErrorWithStatus("Cannot delete file")
                }
            }
            
        }
    }
}
