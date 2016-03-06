//
//  Telemetry2ViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class Telemetry2ViewController: UIViewController, FlightDataListener, RcCommandsProvider {
    let SpeedScale = 30.0       // points per km/h
    let AltScale = 40.0         // points per m
    let VarioScale = 82.0       // points per m/s
    
    @IBOutlet weak var attitudeIndicator: AttitudeIndicator2!
    @IBOutlet weak var headingStrip: HeadingStrip!
    @IBOutlet weak var speedScale: VerticalScale!
    @IBOutlet weak var altitudeScale: VerticalScale!
    @IBOutlet weak var variometerScale: VerticalScale!
    @IBOutlet weak var turnRateIndicator: TurnRateIndicator!
    @IBOutlet weak var batteryLabel: BatteryVoltageLabel!
    @IBOutlet weak var rssiLabel: RssiLabel!
    @IBOutlet weak var timeLabel: BlinkingLabel!
    @IBOutlet weak var gpsLabel: BlinkingLabel!
    @IBOutlet weak var dthLabel: BlinkingLabel!
    @IBOutlet weak var actionsView: UIView!
    @IBOutlet weak var followMeButton: UIButton!
    @IBOutlet weak var showRCSticksButton: UIButton!
    @IBOutlet weak var accroModeLabel: UILabel!
    @IBOutlet weak var altModeLabel: UILabel!
    @IBOutlet weak var headingModeLabel: UILabel!
    @IBOutlet weak var posModeLabel: UILabel!
    @IBOutlet weak var airModeLabel: UILabel!
    @IBOutlet weak var rxFailView: UIView!
    @IBOutlet weak var armedLabel: ArmedLabel!
    @IBOutlet weak var voltsGauge: RoundGauge!
    @IBOutlet weak var voltsValueLabel: BatteryVoltageLabel!
    @IBOutlet weak var voltsLabel: BlinkingLabel!
    @IBOutlet weak var ampsGauge: RoundGauge!
    @IBOutlet weak var ampsValueLabel: BlinkingLabel!
    @IBOutlet weak var mAhGauge: RoundGauge!
    @IBOutlet weak var mAHValueLabel: BlinkingLabel!
    @IBOutlet weak var speedUnitLabel: UILabel!
    @IBOutlet weak var altitudeUnitLabel: UILabel!
    @IBOutlet weak var altHoldIndicator: UILabel!

    @IBOutlet weak var camStabMode: UIButton!
    @IBOutlet weak var calibrateMode: UIButton!
    @IBOutlet weak var telemetryMode: UIButton!
    @IBOutlet weak var sonarMode: UIButton!
    @IBOutlet weak var blackboxMode: UIButton!
    @IBOutlet weak var autotuneMode: UIButton!
    
    @IBOutlet weak var leftStick: RCStick!
    @IBOutlet weak var rightStick: RCStick!
    var actingRC = false        // When using feature RXMSP and RC sticks are visible
    
    var hideNavBarTimer: NSTimer?
    var viewDisappeared = false
    var rcTimer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var alpha: CGFloat = 0
        if speedScale.backgroundColor != nil {
            speedScale.backgroundColor!.getWhite(nil, alpha: &alpha)
            speedScale.layer.borderColor = UIColor(white: 0.666, alpha: alpha).CGColor
        }
        if speedUnitLabel.backgroundColor != nil {
            speedUnitLabel.backgroundColor!.getWhite(nil, alpha: &alpha)
            speedUnitLabel.layer.borderColor = UIColor(white: 0.666, alpha: alpha).CGColor
        }

        if altitudeScale.backgroundColor != nil {
            altitudeScale.backgroundColor!.getWhite(nil, alpha: &alpha)
            altitudeScale.layer.borderColor = UIColor(white: 0.666, alpha: alpha).CGColor
        }
        if altitudeUnitLabel.backgroundColor != nil {
            altitudeUnitLabel.backgroundColor!.getWhite(nil, alpha: &alpha)
            altitudeUnitLabel.layer.borderColor = UIColor(white: 0.666, alpha: alpha).CGColor
        }
        if let parent = altHoldIndicator.superview {
            if parent.backgroundColor != nil {
                parent.backgroundColor!.getWhite(nil, alpha: &alpha)
                parent.layer.borderColor = UIColor(white: 0.666, alpha: alpha).CGColor
            }
        }
        
        rssiLabel.text = "?"
        gpsLabel.text = "?"
        timeLabel.text = "00:00"
        dthLabel.text = ""
        
        voltsValueLabel.displayUnit = false
        
        setInstrumentsUnitSystem()
    }
    
    func setInstrumentsUnitSystem() {
        speedScale.scale = useImperialUnits() ? SpeedScale * 1.852 : SpeedScale
        altitudeScale.scale = useImperialUnits() ? AltScale * 2.54 * 12 / 100 : AltScale
        if useImperialUnits() {
            altitudeScale.mainTicksInterval = 10
            altitudeScale.subTicksInterval = 5
            altitudeScale.subSubTicksInterval = 1
            
            variometerScale.mainTicksInterval = 1
            variometerScale.subTicksInterval = 0
            variometerScale.subSubTicksInterval = 0.2
            
            speedUnitLabel.text = "kn"
            altitudeUnitLabel.text = "ft"
        } else {
            altitudeScale.mainTicksInterval = 1
            altitudeScale.subTicksInterval = 0.5
            altitudeScale.subSubTicksInterval = 0
            
            variometerScale.mainTicksInterval = 1
            variometerScale.subTicksInterval = 0.5
            variometerScale.subSubTicksInterval = 0.1
            
            speedUnitLabel.text = "km/h"
            altitudeUnitLabel.text = "m"
        }
        variometerScale.scale = useImperialUnits() ? VarioScale * 2.54 * 12 / 100 : VarioScale
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        msp.addDataListener(self)
        vehicle.pitchAngle.addObserver(self, listener: { newValue in
            self.attitudeIndicator.pitch = newValue
        })
        vehicle.rollAngle.addObserver(self, listener: { newValue in
            self.attitudeIndicator.roll = newValue
        })

        vehicle.heading.addObserver(self, listener: { newValue in
            self.headingStrip.heading = newValue
        })

        vehicle.turnRate.addObserver(self, listener: { newValue in
            self.turnRateIndicator.value = newValue
        })
        
        vehicle.altitude.addObserver(self, listener: { newValue in
            self.altitudeScale.currentValue = newValue
        })

        vehicle.verticalSpeed.addObserver(self, listener: { newValue in
            self.variometerScale.currentValue = newValue
        })
        
        vehicle.batteryVolts.addObserver(self, listener: { newValue in
            self.voltsGauge.value = newValue
            self.voltsValueLabel.voltage = newValue
        })
        
        vehicle.batteryAmps.addObserver(self) { newValue in
            self.ampsGauge.value = newValue
            self.ampsValueLabel.text = formatWithUnit(newValue, unit: "")
        }
        
        vehicle.gpsFix.addObserver(self, listener: { newValue in
            if newValue {
                self.gpsLabel.blinks = false
            } else {
                //let config = Configuration.theConfig  // FIXME
                //if config.isGPSActive() {
                    self.gpsLabel.blinks = true
                    self.gpsLabel.textColor = UIColor.redColor()
                //}
            }
        })
        
        vehicle.gpsNumSats.addObserver(self, listener: { newValue in
            self.gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), newValue)
            if newValue >= 5 {
                self.gpsLabel.textColor = UIColor.whiteColor()
            } else if self.vehicle.gpsFix.value {
                self.gpsLabel.textColor = UIColor.yellowColor()
            }
        })

        // For enabled features
        msp.sendMessage(.MSP_BF_CONFIG, data: nil, retry: 2, callback: { success in
            self.msp.sendMessage(.MSP_MISC, data: nil, retry: 2, callback: nil)
        })
        receivedData()
        receivedSensorData()
        receivedGpsData()
        
        startNavBarTimer()
        
        startRcTimerIfNeeded()
        
        if let tabBarController = parentViewController as? UITabBarController {
            tabBarController.tabBar.hidden = false
        }
        if showRCSticksButton.selected && actingRC {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.rcCommandsProvider = self
        }
        viewDisappeared = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: nil)
        
        followMeButton.enabled = false
    }
    
    func userDefaultsDidChange(sender: AnyObject) {
        setInstrumentsUnitSystem()
    }
    
    private func startNavBarTimer() {
        if let tabBarController = parentViewController as? UITabBarController {
            if !tabBarController.tabBar.hidden {
                hideNavBarTimer?.invalidate()
                hideNavBarTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "hideNavBar:", userInfo: nil, repeats: false)
            }
        }
    }
    
    func hideNavBar(timer: NSTimer?) {
        if let tabBarController = parentViewController as? UITabBarController {
            let offset = tabBarController.tabBar.frame.height
            UIView.animateWithDuration(0.3, animations: {
                    tabBarController.tabBar.frame.offsetInPlace(dx: 0, dy: offset)
                }, completion: { status in
                    if !self.viewDisappeared {
                        tabBarController.tabBar.hidden = true
                    }
                    tabBarController.tabBar.frame.offsetInPlace(dx: 0, dy: -offset)
                })
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewDisappeared = true
        hideNavBarTimer?.invalidate()
        hideNavBarTimer = nil
        
        msp.removeDataListener(self)
        vehicle.pitchAngle.removeObserver(self)
        vehicle.rollAngle.removeObserver(self)
        vehicle.heading.removeObserver(self)
        vehicle.turnRate.removeObserver(self)
        vehicle.altitude.removeObserver(self)
        vehicle.verticalSpeed.removeObserver(self)
        vehicle.batteryVolts.removeObserver(self)
        vehicle.batteryAmps.removeObserver(self)
        vehicle.gpsFix.removeObserver(self)
        vehicle.gpsNumSats.removeObserver(self)

        stopRcTimer()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.rcCommandsProvider = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    func receivedSensorData() {
        let sensorData = SensorData.theSensorData
        /*
        attitudeIndicator.roll = sensorData.rollAngle
        attitudeIndicator.pitch = sensorData.pitchAngle
        
        headingStrip.heading = sensorData.heading
        turnRateIndicator.value = sensorData.turnRate
        */
        let config = Configuration.theConfig
        let settings = Settings.theSettings
        altitudeScale.bugs.removeAll()
        if settings.isModeOn(Mode.BARO, forStatus: config.mode) || settings.isModeOn(Mode.SONAR, forStatus: config.mode) {
            altitudeScale.bugs.append((value: sensorData.altitudeHold, UIColor.cyanColor()))
            altHoldIndicator.text = formatAltitude(sensorData.altitudeHold, appendUnit: false)
        } else {
            altHoldIndicator.text = ""
        }

        headingStrip.bugs.removeAll()
        if settings.isModeOn(Mode.MAG, forStatus: config.mode) {
            headingStrip.bugs.append((value: sensorData.headingHold, UIColor.cyanColor()))
        }

    }
    
    func receivedAltitudeData() {
        let sensorData = SensorData.theSensorData
        // Use baro/sonar altitude if present, otherwise use GPS altitude
        let config = Configuration.theConfig
        if config.isBarometerActive() || config.isSonarActive() {
            //altitudeScale.currentValue = sensorData.altitude
        }
        //variometerScale.currentValue = sensorData.variometer
    }
    
    func receivedData() {
        let config = Configuration.theConfig
        let settings = Settings.theSettings

        if voltsGauge.ranges.isEmpty && config.batteryCells != 0 {
            let misc = Misc.theMisc
            voltsGauge.minimum = misc.vbatMinCellVoltage * Double(config.batteryCells) * 0.9
            voltsGauge.maximum = misc.vbatMaxCellVoltage * Double(config.batteryCells)
            voltsGauge.ranges.append((min: voltsGauge.minimum, max: misc.vbatMinCellVoltage * Double(config.batteryCells), UIColor.redColor()))
            voltsGauge.ranges.append((min: misc.vbatMinCellVoltage * Double(config.batteryCells), max: misc.vbatWarningCellVoltage * Double(config.batteryCells), UIColor.yellowColor()))
            voltsGauge.ranges.append((min: misc.vbatWarningCellVoltage * Double(config.batteryCells), max: voltsGauge.maximum, UIColor.greenColor()))
        }

        //voltsValueLabel.voltage = config.voltage
        //voltsGauge.value = config.voltage
        
        //ampsGauge.value = config.amperage
        //ampsValueLabel.text = formatWithUnit(config.amperage, unit: "")
        
        mAhGauge.value = Double(config.mAhDrawn)
        mAHValueLabel.text = String(format: "%d", locale: NSLocale.currentLocale(), config.mAhDrawn)
        
        rssiLabel.rssi = config.rssi
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let armedTime = Int(round(appDelegate.totalArmedTime))
        timeLabel.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
    
        armedLabel.armed = settings.isModeOn(Mode.ARM, forStatus: config.mode)
        
        if settings.isModeOn(Mode.ANGLE, forStatus: config.mode) {
            accroModeLabel.text = "ANGL"
            accroModeLabel.hidden = false
        } else if settings.isModeOn(Mode.HORIZON, forStatus: config.mode) {
            accroModeLabel.text = "HOZN"
            accroModeLabel.hidden = false
        } else {
            accroModeLabel.hidden = true
        }
        if settings.isModeOn(Mode.AIR, forStatus: config.mode) {
            airModeLabel.hidden = false
        } else {
            airModeLabel.hidden = true
        }
        if settings.isModeOn(Mode.BARO, forStatus: config.mode) || settings.isModeOn(Mode.SONAR, forStatus: config.mode) {
            altModeLabel.hidden = false
        } else {
            altModeLabel.hidden = true
        }
        if settings.isModeOn(Mode.MAG, forStatus: config.mode) {
            headingModeLabel.hidden = false
        } else {
            headingModeLabel.hidden = true
        }
        if settings.isModeOn(Mode.GPSHOME, forStatus: config.mode) {
            posModeLabel.text = "RTH"
            posModeLabel.hidden = false
        } else if settings.isModeOn(Mode.GPSHOLD, forStatus: config.mode) {
            posModeLabel.text = "POS"
            posModeLabel.hidden = false
        } else {
            posModeLabel.hidden = true
        }
        rxFailView.hidden = !settings.isModeOn(Mode.FAILSAFE, forStatus: config.mode)
        
        camStabMode.tintColor = settings.isModeOn(Mode.CAMSTAB, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
        calibrateMode.tintColor = settings.isModeOn(Mode.CALIB, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
        telemetryMode.tintColor = settings.isModeOn(Mode.TELEMETRY, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
        sonarMode.tintColor = settings.isModeOn(Mode.SONAR, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
        blackboxMode.tintColor = settings.isModeOn(Mode.BLACKBOX, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
        autotuneMode.tintColor = settings.isModeOn(Mode.GTUNE, forStatus: config.mode) || settings.isModeOn(Mode.AUTOTUNE, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
    }
    
    func received3drRssiData() {
        let config = Configuration.theConfig
        rssiLabel.sikRssi = config.sikQuality
    }
    
    func receivedGpsData() {
/*
        let gpsData = GPSData.theGPSData

        gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), gpsData.numSat)
        if gpsData.fix && gpsData.numSat >= 5 {
            gpsLabel.blinks = false
            if gpsData.numSat >= 5 {
                gpsLabel.textColor = UIColor.whiteColor()
            } else {
                gpsLabel.textColor = UIColor.yellowColor()
            }
            dthLabel.text = formatDistance(Double(gpsData.distanceToHome))
            speedScale.currentValue = gpsData.speed
            
            followMeButton.enabled = !msp.replaying
        } else {
            let config = Configuration.theConfig
            if config.isGPSActive() {
                gpsLabel.blinks = true
                gpsLabel.textColor = UIColor.redColor()
            }
            dthLabel.text = ""
            speedScale.currentValue = 0
            
            followMeButton.enabled = false
        }
        let config = Configuration.theConfig
        if !config.isBarometerActive() && !config.isSonarActive()  {
            altitudeScale.currentValue = Double(gpsData.altitude)
        }
*/
    }

    @IBAction func menuAction(sender: AnyObject) {
        actionsView.hidden = !actionsView.hidden
        if !actionsView.hidden {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            followMeButton.selected = appDelegate.followMeActive
        }
    }
    
    @IBAction func followMeAction(sender: AnyObject) {
        actionsView.hidden = true
        if !msp.replaying {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.followMeActive = !appDelegate.followMeActive
        }
    }
    
    @IBAction func showRCSticksAction(sender: AnyObject) {
        actionsView.hidden = true

        leftStick.hidden = !leftStick.hidden
        rightStick.hidden = !rightStick.hidden
        showRCSticksButton.selected = !showRCSticksButton.selected
        if !msp.replaying && Settings.theSettings.features.contains(.RxMsp) {
            actingRC = showRCSticksButton.selected
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.rcCommandsProvider = actingRC ? self : nil
            leftStick.userInteractionEnabled = true
            rightStick.userInteractionEnabled = true
        } else {
            if showRCSticksButton.selected {
                startRcTimerIfNeeded()
                leftStick.userInteractionEnabled = false
                rightStick.userInteractionEnabled = false
            } else {
                stopRcTimer()
            }
        }
    }
    
    @IBAction func disconnectAction(sender: AnyObject) {
        actionsView.hidden = true
        msp.closeCommChannel()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func viewTapped(sender: AnyObject) {
        if !actionsView.hidden {
            actionsView.hidden = true
        } else {
            if let tabBarController = parentViewController as? UITabBarController {
                if !tabBarController.tabBar.hidden {
                    hideNavBar(nil)
                } else {
                    tabBarController.tabBar.hidden = false
                    startNavBarTimer()
                }
            }
        }
    }
    func receivedReceiverData() {
        let receiver = Receiver.theReceiver
        leftStick.horizontalValue = constrain((Double(receiver.channels[2]) - 1500) / 500, min: -1, max: 1)
        leftStick.verticalValue = constrain((Double(receiver.channels[3]) - 1500) / 500, min: -1, max: 1)
        rightStick.verticalValue = constrain((Double(receiver.channels[1]) - 1500) / 500, min: -1, max: 1)
        rightStick.horizontalValue = constrain((Double(receiver.channels[0]) - 1500 ) / 500, min: -1, max: 1)
    }
    func startRcTimerIfNeeded() {
        if showRCSticksButton.selected && !actingRC {
            rcTimer = NSTimer.scheduledTimerWithTimeInterval(0.15, target: self, selector: "rcTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func stopRcTimer() {
        rcTimer?.invalidate()
        rcTimer = nil
    }
    
    func rcTimerDidFire(timer: NSTimer) {
        msp.sendMessage(.MSP_RC, data: nil)
    }
    
    func rcCommands() -> [Int] {
        return [ Int(round(rightStick.horizontalValue * 500 + 1500)), Int(round(rightStick.verticalValue * 500 + 1500)), Int(round(leftStick.verticalValue * 500 + 1500)), Int(round(leftStick.horizontalValue * 500 + 1500)) ]
    }
}
