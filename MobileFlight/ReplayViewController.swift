//
//  ReplayViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 28/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import SVProgressHUD

class ReplayViewController: UITableViewController {
    var replayFiles: [URL]?
    var detailedRow = -1

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        detailedRow = -1
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Flight Sessions"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Tap any flight session to replay it."
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case 0:
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [URLResourceKey(rawValue: kCFURLNameKey as String as String)], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                replayFiles = urls
                return urls.count
            } catch {
                return 0
            }
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == detailedRow {
            return 94
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: indexPath.row == detailedRow ? "DetailedReplayCell" : "ReplayCell", for: indexPath) as! DetailedReplayCell
        
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
                    try TryCatch.try({
                        do {
                            let attrs = try FileManager.default.attributesOfItem(atPath: fileUrl.path)
                            let date = attrs[FileAttributeKey.creationDate] as! Date
                            let df = DateFormatter()
                            df.dateStyle = .short
                            df.timeStyle = .short
                            title = df.string(from: date)
                            
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
                                    title = df.string(from: stats!.armedDate)
                                }
                            }
                        } catch let error as NSError {
                            NSLog("Cannot get attributes of %@: %@", fileUrl.absoluteString, error.localizedDescription)
                        }
                    })
                } catch  {
                    // Objective-C exception
                }
                if title == nil {
                    title = fileUrl.lastPathComponent
                }
                cell.flyDate.text = title
                cell.flyTime.text = detail
            }
        default:
            break
        }
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        resetAircraftModel()
        
        switch indexPath.section {
        case  0:
            if replayFiles != nil && indexPath.row < replayFiles!.count {
                let fileUrl = replayFiles![indexPath.row]
                
                do {
                    try TryCatch.try({
                        do {
                            let (file, _) = try FlightLogFile.openForReading(fileUrl)
                            _ = ReplayComm(datalog: file, msp: self.msp)
                            (self.parent as! MainConnectionViewController).presentNextViewController()
                        } catch  {
                            // Swift error
                            SVProgressHUD.showError(withStatus: "Invalid flight session", maskType: .black)
                        }
                    })
                } catch  {
                    // Objective-C exception
                    SVProgressHUD.showError(withStatus: "Invalid flight session", maskType: .black)
                }
            }
            tableView.deselectRow(at: indexPath, animated: false)
            
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        var indexPaths = [IndexPath]()
        if detailedRow != -1 {
            indexPaths.append(IndexPath(row: detailedRow, section: 0))
        }
        if detailedRow == indexPath.row {
            detailedRow = -1
        } else {
            detailedRow = indexPath.row
            indexPaths.append(IndexPath(row: detailedRow, section: 0))
        }
        tableView.reloadRows(at: indexPaths, with: UITableViewRowAnimation.fade)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if replayFiles != nil && indexPath.row < replayFiles!.count {
                let fileUrl = replayFiles![indexPath.row]
                do {
                    try FileManager.default.removeItem(at: fileUrl)
                    // Delete the row from the data source
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    if detailedRow == indexPath.row {
                        detailedRow = -1
                    } else if detailedRow > indexPath.row {
                        detailedRow -= 1
                        tableView.reloadRows(at: [IndexPath(row: detailedRow, section: 0)], with: UITableViewRowAnimation.middle)
                    }
                } catch let error as NSError {
                    NSLog("Cannot delete %@: %@", fileUrl.absoluteString, error)
                    SVProgressHUD.showError(withStatus: "Cannot delete file")
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
