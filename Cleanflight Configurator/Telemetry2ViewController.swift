//
//  Telemetry2ViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 19/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

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
    var actingRC = false        // When RC sticks are visible and used to control the aircraft
    
    var hideNavBarTimer: NSTimer?
    var viewDisappeared = false
    var stopwatchTimer: NSTimer?
    
    @IBOutlet weak var containerView: UIView!
    var mavlinkTelemetryViewController: UIViewController!
    var mspTelemetryViewController: UIViewController!
    
    override func awakeFromNib() {
        mavlinkTelemetryViewController = storyboard!.instantiateViewControllerWithIdentifier("MAVLinkTelemetry")
        mspTelemetryViewController = storyboard!.instantiateViewControllerWithIdentifier("MSPTelemetry")
    }
    
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
        
        let specificViewController: UIViewController
        if vehicle is MAVLinkVehicle {
            specificViewController = mavlinkTelemetryViewController
        } else {
            specificViewController = mspTelemetryViewController
        }
        
        addChildViewController(specificViewController)
        specificViewController.didMoveToParentViewController(self)
        
        let subView = specificViewController.view
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(subView)
        
        let viewDict = ["view" : subView]
        
        //Horizontal constraints
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: .AlignAllTop, metrics: nil, views: viewDict)
        NSLayoutConstraint.activateConstraints(horizontalConstraints)
        
        //Vertical constraints
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: .AlignAllTop, metrics: nil, views: viewDict)
        NSLayoutConstraint.activateConstraints(verticalConstraints)
    }
    
    override func viewDidLayoutSubviews() {
        self.containerView.layoutMargins.left = self.speedScale.frame.maxX
        self.containerView.layoutMargins.right = self.attitudeIndicator.bounds.width - self.altitudeScale.frame.minX
        self.containerView.layoutMargins.top = self.headingStrip.frame.maxY
        self.containerView.layoutMargins.bottom = 0
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
        
        vehicle.armed.addObserver(self, listener: { newValue in
            self.armedLabel.armed = newValue
            if newValue {
                self.stopwatchTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "stopwatchTimer:", userInfo: nil, repeats: true)
            } else {
                self.stopwatchTimer?.invalidate()
                self.stopwatchTimer = nil
            }
        })
        
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
        
        vehicle.speed.addObserver(self, listener: { newValue in
            self.speedScale.currentValue = newValue
        })
        
        vehicle.batteryVolts.addObserver(self, listener: { newValue in
            self.voltsGauge.value = newValue
            self.voltsValueLabel.voltage = newValue
        })
        
        vehicle.batteryAmps.addObserver(self) { newValue in
            self.ampsGauge.value = newValue
            self.ampsValueLabel.text = formatWithUnit(newValue, unit: "")
        }
        
        vehicle.batteryConsumedMAh.addObserver(self, listener: { newValue in
            self.mAhGauge.value = Double(newValue)
            self.mAHValueLabel.text = String(format: "%d", locale: NSLocale.currentLocale(), newValue)

        })
        
        vehicle.gpsFix.addObserver(self, listener: { newValue in
            if newValue == nil {
                // No GPS present
                self.gpsLabel.blinks = false
                self.gpsLabel.text = ""
                self.followMeButton.enabled = false
            } else {
                self.gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), self.vehicle.gpsNumSats.value)
                if newValue! {
                    // GPS Fix
                    self.gpsLabel.blinks = false
                    self.gpsLabel.textColor = UIColor.whiteColor()
                    self.followMeButton.enabled = !self.vehicle.replaying.value
                } else {
                    self.gpsLabel.blinks = true
                    self.gpsLabel.textColor = UIColor.redColor()
                    self.followMeButton.enabled = false
                }
            }
        })
        
        vehicle.gpsNumSats.addObserver(self, listener: { newValue in
            let gpsFix = self.vehicle.gpsFix.value
            if gpsFix != nil {
                self.gpsLabel.text = String(format:"%d", locale: NSLocale.currentLocale(), newValue)
                if newValue >= 5 {      // FIXME This is an arbitrary value and this should be done at the same time as gpsFix
                    self.gpsLabel.textColor = UIColor.whiteColor()
                } else if gpsFix! {
                    self.gpsLabel.textColor = UIColor.yellowColor()
                }
            }
        })
        
        vehicle.distanceToHome.addObserver(self, listener: { newValue in
            if self.vehicle.gpsFix.value != nil {
                self.dthLabel.text = formatDistance(newValue)
            }
        })
        
        vehicle.altitudeHold.addObserver(self, listener: { newValue in
            self.altitudeScale.bugs.removeAll()
            if newValue != nil {
                self.altitudeScale.bugs.append((value: newValue!, color: UIColor.cyanColor()))
                self.altHoldIndicator.text = formatAltitude(newValue!, appendUnit: false)
            } else {
                self.altHoldIndicator.text = ""
            }
        })
        
        vehicle.navigationHeading.addObserver(self, listener: { newValue in
            self.headingStrip.bugs.removeAll()
            if newValue != nil {
                self.headingStrip.bugs.append((value: newValue!, UIColor.cyanColor()))
            }
        })
        
        vehicle.batteryVoltsCritical.addObserver(self, listener: { newValue in
            if newValue != nil {
                self.voltsGauge.minimum = newValue! * 0.9
                self.voltsGauge.maximum = newValue! * 1.29
                self.voltsGauge.ranges.append((min: self.voltsGauge.minimum, max: newValue!, UIColor.redColor()))
                let warningLevel = self.vehicle.batteryVoltsWarning.value ?? newValue! * 1.03
                self.voltsGauge.ranges.append((min: newValue!, max: warningLevel, UIColor.yellowColor()))
                self.voltsGauge.ranges.append((min: warningLevel, max: self.voltsGauge.maximum, UIColor.greenColor()))
            } else {
                self.voltsGauge.ranges.removeAll()
            }
        })
        
        vehicle.rssi.addObserver(self, listener: { newValue in
            if newValue == nil {
                self.rssiLabel.text = "?"
            } else {
                self.rssiLabel.rssi = newValue!
            }
        })
        
        vehicle.sikRssi.addObserver(self, listener: { newValue in
            if newValue != nil {
                self.rssiLabel.sikRssi = newValue!
            }
        })

        startNavBarTimer()
        
        if let tabBarController = parentViewController as? UITabBarController {
            tabBarController.tabBar.hidden = false
        }
        if showRCSticksButton.selected {
            if actingRC {
                vehicle.rcCommandsProvider = self
            } else {
                listenToRcChannels()
            }
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
        
        vehicle.armed.removeObserver(self)
        vehicle.pitchAngle.removeObserver(self)
        vehicle.rollAngle.removeObserver(self)
        vehicle.heading.removeObserver(self)
        vehicle.turnRate.removeObserver(self)
        vehicle.altitude.removeObserver(self)
        vehicle.verticalSpeed.removeObserver(self)
        vehicle.batteryVolts.removeObserver(self)
        vehicle.batteryAmps.removeObserver(self)
        vehicle.batteryConsumedMAh.removeObserver(self)
        vehicle.gpsFix.removeObserver(self)
        vehicle.gpsNumSats.removeObserver(self)
        vehicle.distanceToHome.removeObserver(self)
        vehicle.altitudeHold.removeObserver(self)
        vehicle.navigationHeading.removeObserver(self)
        vehicle.batteryVoltsCritical.removeObserver(self)
        vehicle.rssi.removeObserver(self)
        vehicle.sikRssi.removeObserver(self)
        vehicle.rcChannels.removeObserver(self)
        
        vehicle.rcCommandsProvider = nil
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    }
    
    @objc
    private func stopwatchTimer(timer: NSTimer) {
        let armedTime = Int(round(vehicle.totalArmedTime))
        timeLabel.text = String(format: "%02d:%02d", armedTime / 60, armedTime % 60)
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
        if !vehicle.replaying.value {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.followMeActive = !appDelegate.followMeActive
        }
    }
    
    @IBAction func showRCSticksAction(sender: AnyObject) {
        actionsView.hidden = true

        leftStick.hidden = !leftStick.hidden
        rightStick.hidden = !rightStick.hidden
        showRCSticksButton.selected = !showRCSticksButton.selected
        if !vehicle.replaying.value && vehicle is MSPVehicle && mspvehicle.settings.features.contains(.RxMsp) {
            actingRC = showRCSticksButton.selected
            vehicle.rcCommandsProvider = actingRC ? self : nil
            leftStick.userInteractionEnabled = true
            rightStick.userInteractionEnabled = true
        } else {
            if showRCSticksButton.selected {
                leftStick.userInteractionEnabled = false
                rightStick.userInteractionEnabled = false
                listenToRcChannels()
            } else {
                vehicle.rcChannels.removeObserver(self)
            }
        }
    }
    
    private func listenToRcChannels() {
        vehicle.rcChannels.addObserver(self, listener: { newValue in
            if newValue != nil {
                self.leftStick.verticalValue = (Double(newValue![2]) - 1500) / 500
                self.leftStick.horizontalValue = (Double(newValue![3]) - 1500) / 500
                self.rightStick.verticalValue = (Double(newValue![1]) - 1500) / 500
                self.rightStick.horizontalValue = (Double(newValue![0]) - 1500) / 500
            }
        })
    }
    
    @IBAction func disconnectAction(sender: AnyObject) {
        actionsView.hidden = true
        protocolHandler.closeCommChannel()
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

    func rcCommands() -> [Int] {
        return [ Int(round(rightStick.horizontalValue * 500 + 1500)), Int(round(rightStick.verticalValue * 500 + 1500)), Int(round(leftStick.verticalValue * 500 + 1500)), Int(round(leftStick.horizontalValue * 500 + 1500)) ]
    }
}
