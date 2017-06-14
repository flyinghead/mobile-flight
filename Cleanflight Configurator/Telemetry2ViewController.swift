//
//  Telemetry2ViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit
import Firebase

class Telemetry2ViewController: UIViewController, RcCommandsProvider {
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
    @IBOutlet weak var rssiImg: UIImageView!
    @IBOutlet weak var rssiLabel: RssiLabel!
    @IBOutlet weak var timeLabel: ArmedTimer!
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
    @IBOutlet weak var navStatusLabel: UILabel!

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
    
    var altitudeEventHandler: Disposable?
    var rssiEventHandler: Disposable?
    var attitudeEventHandler: Disposable?
    var navigationEventHandler: Disposable?
    var flightModeEventHandler: Disposable?
    var batteryEventHandler: Disposable?
    var gpsEventHandler: Disposable?
    var receiverEventHandler: Disposable?
    var sensorStatusEventHandler: Disposable?

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
        dthLabel.text = ""
        
        voltsValueLabel.displayUnit = false
    }
    
    func setInstrumentsUnitSystem() {
        switch selectedUnitSystem() {
        case .Aviation:
            speedScale.scale = SpeedScale * METER_PER_NM / 1000
            speedUnitLabel.text = "kn"
        case .Imperial:
            speedScale.scale = SpeedScale * METER_PER_MILE / 1000
            speedUnitLabel.text = "mph"
        default:
            speedScale.scale = SpeedScale
            speedUnitLabel.text = "km/h"
        }

        let metricUnits = selectedUnitSystem() == .Metric
        altitudeScale.scale = !metricUnits ? AltScale / FEET_PER_METER : AltScale
        if !metricUnits {
            altitudeScale.mainTicksInterval = 10
            altitudeScale.subTicksInterval = 5
            altitudeScale.subSubTicksInterval = 1
            
            variometerScale.mainTicksInterval = 1
            variometerScale.subTicksInterval = 0
            variometerScale.subSubTicksInterval = 0.2
            
            altitudeUnitLabel.text = "ft"
        } else {
            altitudeScale.mainTicksInterval = 1
            altitudeScale.subTicksInterval = 0.5
            altitudeScale.subSubTicksInterval = 0
            
            variometerScale.mainTicksInterval = 1
            variometerScale.subTicksInterval = 0.5
            variometerScale.subSubTicksInterval = 0.1
            
            altitudeUnitLabel.text = "m"
        }
        variometerScale.scale = !metricUnits ? VarioScale / FEET_PER_METER : VarioScale
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        timeLabel.appear()
        
        altitudeEventHandler = msp.altitudeEvent.addHandler(self, handler: Telemetry2ViewController.receivedAltitudeData)
        rssiEventHandler = msp.rssiEvent.addHandler(self, handler: Telemetry2ViewController.receivedRssiData)
        attitudeEventHandler = msp.attitudeEvent.addHandler(self, handler: Telemetry2ViewController.receivedAttitudeData)
        navigationEventHandler = msp.navigationEvent.addHandler(self, handler: Telemetry2ViewController.receivedPosHoldData)
        flightModeEventHandler = msp.flightModeEvent.addHandler(self, handler: Telemetry2ViewController.flightModeChanged)
        batteryEventHandler = msp.batteryEvent.addHandler(self, handler: Telemetry2ViewController.receivedBatteryData)
        gpsEventHandler = msp.gpsEvent.addHandler(self, handler: Telemetry2ViewController.receivedGpsData)
        receiverEventHandler = msp.receiverEvent.addHandler(self, handler: Telemetry2ViewController.receivedReceiverData)
        sensorStatusEventHandler = msp.sensorStatusEvent.addHandler(self, handler: Telemetry2ViewController.receivedSensorStatus)
        
        // For enabled features
        msp.sendMessage(.MSP_FEATURE, data: nil, retry: 2, callback: nil)
        
        receivedBatteryData()
        receivedAltitudeData()
        receivedAttitudeData()
        receivedRssiData()
        receivedPosHoldData()
        flightModeChanged()
        receivedGpsData()
        receivedReceiverData()
        receivedSensorStatus()
        
        startNavBarTimer()
        
        if let tabBarController = parentViewController as? UITabBarController {
            tabBarController.tabBar.hidden = false
        }
        if showRCSticksButton.selected && actingRC {
            appDelegate.rcCommandsProvider = self
        }
        viewDisappeared = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Telemetry2ViewController.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Telemetry2ViewController.userDefaultsDidChange(_:)), name: kIASKAppSettingChanged, object: nil)
        setInstrumentsUnitSystem()
        
        followMeButton.enabled = false
        
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssiw" : "signalw")
    }
    
    func userDefaultsDidChange(sender: AnyObject) {
        setInstrumentsUnitSystem()
    }
    
    private func startNavBarTimer() {
        if let tabBarController = parentViewController as? UITabBarController {
            if !tabBarController.tabBar.hidden {
                hideNavBarTimer?.invalidate()
                hideNavBarTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(Telemetry2ViewController.hideNavBar(_:)), userInfo: nil, repeats: false)
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
        
        timeLabel.disappear()
        
        altitudeEventHandler?.dispose()
        rssiEventHandler?.dispose()
        attitudeEventHandler?.dispose()
        navigationEventHandler?.dispose()
        flightModeEventHandler?.dispose()
        batteryEventHandler?.dispose()
        gpsEventHandler?.dispose()
        receiverEventHandler?.dispose()
        sensorStatusEventHandler?.dispose()
        
        appDelegate.rcCommandsProvider = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kIASKAppSettingChanged, object: nil)
    }
    
    private func convertAltitude(value: Double) -> Double {
        if selectedUnitSystem() == .Metric {
            return value
        } else {
            return value * FEET_PER_METER
        }
    }
    
    private func convertSpeed(value: Double) -> Double {
        switch selectedUnitSystem() {
        case .Aviation:
            return value * 1000 / METER_PER_NM
        case .Imperial:
            return value * 1000 / METER_PER_MILE
        default:
            return value
        }
    }
    
    // MARK: Event Handlers
    
    func receivedAttitudeData() {
        let sensorData = SensorData.theSensorData
        attitudeIndicator.roll = sensorData.rollAngle
        attitudeIndicator.pitch = sensorData.pitchAngle
        
        headingStrip.heading = sensorData.heading
        turnRateIndicator.value = sensorData.turnRate
    }

    func receivedPosHoldData() {
        let sensorData = SensorData.theSensorData
        let settings = Settings.theSettings

        altitudeScale.bugs.removeAll()
        // Unfortunately no way to get the altitude hold value with INav
        if settings.altitudeHoldMode && !Configuration.theConfig.isINav {
            altitudeScale.bugs.append((value: convertAltitude(sensorData.altitudeHold), UIColor.cyanColor()))
            altHoldIndicator.text = formatAltitude(sensorData.altitudeHold, appendUnit: false)
        } else {
            altHoldIndicator.text = ""
        }

        headingStrip.bugs.removeAll()
        if settings.headingHoldMode {
            headingStrip.bugs.append((value: sensorData.headingHold, UIColor.cyanColor()))
        }

        if let (label, _, emergency) = INavState.theINavState.navStateDescription {
            navStatusLabel.text = label
            navStatusLabel.textColor = emergency ? UIColor.redColor() : UIColor.greenColor()
        }
    }
    
    func receivedAltitudeData() {
        let sensorData = SensorData.theSensorData
        // Use baro/sonar altitude if present, otherwise use GPS altitude
        let config = Configuration.theConfig
        if config.isBarometerActive() || config.isSonarActive() {
            altitudeScale.currentValue = convertAltitude(sensorData.altitude)
        }
        variometerScale.currentValue = convertAltitude(sensorData.variometer)   // m -> ft <=> m/s -> ft/s
    }
    
    func receivedBatteryData() {
        let config = Configuration.theConfig
        let settings = Settings.theSettings

        if voltsGauge.ranges.isEmpty && config.batteryCells != 0 {
            voltsGauge.minimum = settings.vbatMinCellVoltage * Double(config.batteryCells) * 0.9
            voltsGauge.maximum = settings.vbatMaxCellVoltage * Double(config.batteryCells)
            voltsGauge.ranges.append((min: voltsGauge.minimum, max: settings.vbatMinCellVoltage * Double(config.batteryCells), UIColor.redColor()))
            voltsGauge.ranges.append((min: settings.vbatMinCellVoltage * Double(config.batteryCells), max: settings.vbatWarningCellVoltage * Double(config.batteryCells), UIColor.yellowColor()))
            voltsGauge.ranges.append((min: settings.vbatWarningCellVoltage * Double(config.batteryCells), max: voltsGauge.maximum, UIColor.greenColor()))
        }

        voltsValueLabel.voltage = config.voltage
        voltsGauge.value = config.voltage
        
        ampsGauge.value = config.amperage
        ampsValueLabel.text = formatWithUnit(config.amperage, unit: "")
        
        if mAhGauge.ranges.isEmpty && settings.batteryCapacity != 0 {
            mAhGauge.maximum = Double(settings.batteryCapacity) * 1.2
            mAhGauge.ranges.append((min: 0, max: Double(settings.batteryCapacity) * 0.8, UIColor.greenColor()))
            mAhGauge.ranges.append((min: Double(settings.batteryCapacity) * 0.8, max: Double(settings.batteryCapacity), UIColor.yellowColor()))
            mAhGauge.ranges.append((min: Double(settings.batteryCapacity), max: mAhGauge.maximum, UIColor.redColor()))
        }
        mAhGauge.value = Double(config.mAhDrawn)
        mAHValueLabel.text = String(format: "%d", config.mAhDrawn)
        
    }
    
    func flightModeChanged() {
        let config = Configuration.theConfig
        let settings = Settings.theSettings
        
        armedLabel.armed = settings.armed
        
        if settings.isModeOn(Mode.GCS_NAV, forStatus: config.mode) {
            accroModeLabel.text = "GCS"
            accroModeLabel.hidden = false
        } else if settings.isModeOn(Mode.ANGLE, forStatus: config.mode) {
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
        if settings.altitudeHoldMode {
            altModeLabel.hidden = false
        } else {
            altModeLabel.hidden = true
        }
        if settings.headingHoldMode {
            headingModeLabel.hidden = false
        } else {
            headingModeLabel.hidden = true
        }
        if settings.returnToHomeMode {
            posModeLabel.text = "RTH"
            posModeLabel.hidden = false
        } else if settings.positionHoldMode {
            posModeLabel.text = "POS"
            posModeLabel.hidden = false
        } else if settings.isModeOn(Mode.NAV_WP, forStatus: config.mode) {
            posModeLabel.text = "WP"
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
        autotuneMode.tintColor = settings.isModeOn(Mode.GTUNE, forStatus: config.mode) ? UIColor.greenColor() : UIColor.blackColor()
        
        // If BARO, SONAR or MAG modes changed, we have to update UI
        receivedPosHoldData()
    }
    
    func receivedRssiData() {
        let config = Configuration.theConfig
        
        rssiLabel.rssi = appDelegate.showBtRssi ? config.btRssi : config.rssi
        rssiLabel.sikRssi = config.sikQuality
    }
    
    func receivedGpsData() {
        let gpsData = GPSData.theGPSData

        gpsLabel.text = String(format:"%d", gpsData.numSat)
        if gpsData.fix && gpsData.numSat >= 5 {
            gpsLabel.blinks = false
            if gpsData.numSat >= 5 {
                gpsLabel.textColor = UIColor.whiteColor()
            } else {
                gpsLabel.textColor = UIColor.yellowColor()
            }
            dthLabel.text = formatDistance(Double(gpsData.distanceToHome))
            speedScale.currentValue = convertSpeed(gpsData.speed)
            
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
            altitudeScale.currentValue = convertAltitude(Double(gpsData.altitude))
        }
    }

    func receivedReceiverData() {
        if !actingRC {
            let receiver = Receiver.theReceiver
            leftStick.horizontalValue = constrain((Double(receiver.channels[2]) - 1500) / 500, min: -1, max: 1)
            leftStick.verticalValue = constrain((Double(receiver.channels[3]) - 1500) / 500, min: -1, max: 1)
            rightStick.verticalValue = constrain((Double(receiver.channels[1]) - 1500) / 500, min: -1, max: 1)
            rightStick.horizontalValue = constrain((Double(receiver.channels[0]) - 1500 ) / 500, min: -1, max: 1)
        }
    }
    
    func receivedSensorStatus() {
        let config = Configuration.theConfig
        let settings = Settings.theSettings
        if config.isINav && !settings.armed {
            armedLabel.textColor = INavState.theINavState.armingFlags.contains(.OkToArm) ? UIColor.greenColor() : UIColor.redColor()
        }
    }
    
    // MARK: Actions
    
    @IBAction func menuAction(sender: AnyObject) {
        actionsView.hidden = !actionsView.hidden
        if !actionsView.hidden {
            followMeButton.selected = appDelegate.followMeActive
        }
    }
    
    @IBAction func followMeAction(sender: AnyObject) {
        actionsView.hidden = true
        if !msp.replaying {
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
            appDelegate.rcCommandsProvider = actingRC ? self : nil
            leftStick.userInteractionEnabled = true
            rightStick.userInteractionEnabled = true
            Analytics.logEvent("msp_rc_control", parameters: ["on" : actingRC])
        } else {
            if showRCSticksButton.selected {
                leftStick.userInteractionEnabled = false
                rightStick.userInteractionEnabled = false
            }
        }
    }
    
    @IBAction func disconnectAction(sender: AnyObject) {
        actionsView.hidden = true
        msp.closeCommChannel()
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
    
    @IBAction func rssiViewTapped(sender: AnyObject) {
        appDelegate.showBtRssi = !appDelegate.showBtRssi
        rssiImg.image = UIImage(named: appDelegate.showBtRssi ? "btrssiw" : "signalw")
        let config = Configuration.theConfig
        rssiLabel.rssi = appDelegate.showBtRssi ? config.btRssi : config.rssi
    }
    
    func rcCommands() -> [Int] {
        return [ Int(round(rightStick.horizontalValue * 500 + 1500)), Int(round(rightStick.verticalValue * 500 + 1500)), Int(round(leftStick.verticalValue * 500 + 1500)), Int(round(leftStick.horizontalValue * 500 + 1500)) ]
    }
}
