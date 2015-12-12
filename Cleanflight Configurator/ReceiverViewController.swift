//
//  ReceiverViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ReceiverViewController: UIViewController, FlightDataListener {

    var timer: NSTimer?

    @IBOutlet weak var rollChannel: ReceiverChannel!
    @IBOutlet weak var pitchChannel: ReceiverChannel!
    @IBOutlet weak var yawChannel: ReceiverChannel!
    @IBOutlet weak var throttleChannel: ReceiverChannel!
    @IBOutlet weak var aux1Channel: ReceiverChannel!
    @IBOutlet weak var aux2Channel: ReceiverChannel!
    @IBOutlet weak var aux3Channel: ReceiverChannel!
    @IBOutlet weak var aux4Channel: ReceiverChannel!
    @IBOutlet weak var aux5Channel: ReceiverChannel!
    @IBOutlet weak var aux6Channel: ReceiverChannel!
    @IBOutlet weak var aux7Channel: ReceiverChannel!
    @IBOutlet weak var aux8Channel: ReceiverChannel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        msp.addDataListener(self)
    }

    func receivedReceiverData() {
        let controls = [rollChannel, pitchChannel, yawChannel, throttleChannel, aux1Channel, aux2Channel, aux3Channel, aux4Channel, aux5Channel, aux6Channel, aux7Channel, aux8Channel]
        let receiver = Receiver.theReceiver
        
        for (i,control) in controls.enumerate() {
            if (i < receiver.activeChannels) {
                control.setValue(receiver.channels[i])
            } else {
                control.setValue(1000)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if (timer == nil) {
            // Cleanflight/chrome uses configurable interval (default 50ms)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "timerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
        timer = nil
    }
    
    func timerDidFire(sender: AnyObject) {
//        msp.sendMessage(.MSP_MISC, data: nil)
        msp.sendMessage(.MSP_RC, data: nil)
        msp.sendMessage(.MSP_RX_MAP, data: nil)
    }
}
