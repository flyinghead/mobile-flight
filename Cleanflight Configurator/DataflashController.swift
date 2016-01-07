//
//  DataflashController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 18/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class DataflashController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        msp.sendMessage(.MSP_DATAFLASH_SUMMARY, data: nil, retry: 2, callback: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
