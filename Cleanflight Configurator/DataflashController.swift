//
//  DataflashController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 18/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import SVProgressHUD

class DataflashController: UIViewController {
    @IBOutlet weak var gauge: LinearGauge!
    @IBOutlet weak var usedLabel: UILabel!
    @IBOutlet weak var freeLabel: UILabel!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        eraseButton.layer.borderColor = eraseButton.tintColor.CGColor
        downloadButton.layer.borderColor = downloadButton.tintColor.CGColor
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateSummary()
    }
    
    private func updateSummary() {
        msp.sendMessage(.MSP_DATAFLASH_SUMMARY, data: nil, retry: 2, callback: { success in
            dispatch_async(dispatch_get_main_queue(), {
                let dataflash = Dataflash.theDataflash
                
                self.gauge.maximumValue = Double(dataflash.totalSize)
                self.gauge.value = Double(dataflash.usedSize)
                
                if  dataflash.totalSize == 0 {
                    self.usedLabel.text = "This flight controller doesn't have dataflash memory."
                    self.freeLabel.text = ""
                    self.eraseButton.enabled = false
                    self.downloadButton.enabled = false
                } else {
                    self.usedLabel.text = String(format: "Used: %@", NSByteCountFormatter().stringFromByteCount(Int64(dataflash.usedSize)))
                    self.freeLabel.text = String(format: "Free: %@", NSByteCountFormatter().stringFromByteCount(Int64(dataflash.totalSize - dataflash.usedSize)))
                    self.eraseButton.enabled = true
                    self.downloadButton.enabled = true
                }
            })
        })
    }
    
    @IBAction func downloadAction(sender: AnyObject) {
        downloadAddress(0)
    }
    
    func downloadAddress(address: Int) {
        NSLog("Reading address %d", address)
        msp.sendDataflashRead(address, callback: { data in
            if data == nil {
                NSLog("Error!")
            } else if data!.count == 0 {
                NSLog("Done. Success!")
            } else {
                NSLog("Received address %d size %d", readUInt32(data!, index: 0), data!.count - 4)
                let nextAddress = address + data!.count - 4
                if (nextAddress > Dataflash.theDataflash.usedSize) {
                    NSLog("Done (> usedSize). Success!")
                } else {
                    self.downloadAddress(nextAddress)
                }
            }
        })
    }

    func eraseTimer(timer: NSTimer) {
        msp.sendMessage(.MSP_DATAFLASH_SUMMARY, data: nil, retry: 0, callback: { success in
            if success && Dataflash.theDataflash.ready != 0 {
                dispatch_async(dispatch_get_main_queue(), {
                    timer.invalidate()
                    self.updateSummary()
                    SVProgressHUD.dismiss()
                })
            }
        })
    }
    
    @IBAction func eraseAction(sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: "This will erase all data contained in the dataflash and will take about 20 seconds. Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { alertController in
            SVProgressHUD.showWithStatus("Erasing dataflash. Please wait.", maskType: .Black)
            self.msp.sendMessage(.MSP_DATAFLASH_ERASE, data: nil, retry: 0, callback: { success in
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "eraseTimer:", userInfo: nil, repeats: true)
                    } else {
                        SVProgressHUD.showErrorWithStatus("Erase failed");
                        self.updateSummary()
                    }
                })
            })
        }))
        alertController.popoverPresentationController?.sourceView = (sender as! UIView)
        presentViewController(alertController, animated: true, completion: nil)

    }
}
