//
//  AppDelegate.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//
import Foundation
import UIKit
import SVProgressHUD
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FlightDataListener, CLLocationManagerDelegate {

    var window: UIWindow?
    var msp = MSPParser()
    var vehicle = Vehicle()
    
    var statusTimer: NSTimer?
    var statusSwitch = false        // Used to alternate between RAW_GPS and COMP_GPS during each status timer callback since GPS info is only updated at 5 Hz
    var lastDataReceived: NSDate?
    var noDataReceived = false
    var armed = false
    var _totalArmedTime = 0.0
    var _lastArmedTime = 0.0
    var lastArming: NSDate?
    
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?

    var stayAliveTimer: NSTimer!
    
    var rcCommands: [Int]?
    var rcCommandsProvider: RcCommandsProvider?
    
    var locationManager: CLLocationManager?
    var lastFollowMeUpdate: NSDate?
    let followMeUpdatePeriod: NSTimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    
    var logTimer: NSTimer?      // DEBUG
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.backgroundColor = UIColor.whiteColor()
        
        registerInitialUserDefaults()
        
        msp.addDataListener(self)
        
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(0.2)   // 0.25 less the roundtrip time
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: nil)

        stayAliveTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "stayAliveTimer:", userInfo: nil, repeats: true)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        stopTimer()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        startTimer()
    }
    
    func startTimer() {
        if msp.communicationEstablished && statusTimer == nil {
            // FIXME In this configuration: Naze32 - RPi - 3DR(64kbps) - 3DR - Macbook - Wifi - iPhone, the latency is a bit less then 200ms so 10Hz update is too much.
            // We should design an adaptative algorithm to find the optimal update frequency.
            // In this config: Naze32 - 3DR(64kbps) - 3DR - Macbook - Wifi - iPhone, the latency is around 130-140ms
            // With bluetooth, the latency is a bit less than 100ms (70-90). Sometimes two requests are sent before a response is received but this doesn't cause any problem.
            statusTimer = NSTimer(timeInterval:0.15, target: self, selector: "statusTimerDidFire:", userInfo: nil, repeats: true)
            NSRunLoop.mainRunLoop().addTimer(statusTimer!, forMode: NSRunLoopCommonModes)
        }
        if logTimer == nil {
            logTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "logTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
        
        logTimer?.invalidate()
        logTimer = nil
        
        lastDataReceived = nil
    }
    
    func statusTimerDidFire(timer: NSTimer?) {
        if rcCommandsProvider != nil {
            rcCommands = rcCommandsProvider!.rcCommands()
        }
        if rcCommands != nil {
            msp.sendRawRc(rcCommands!)
        }

        msp.sendMessage(.MSP_STATUS, data: nil)
        statusSwitch = !statusSwitch
        if statusSwitch {
            msp.sendMessage(.MSP_RAW_GPS, data: nil)
        } else {
            msp.sendMessage(.MSP_COMP_GPS, data: nil)       // distance to home, direction to home
        }
        msp.sendMessage(.MSP_ALTITUDE, data: nil)
        msp.sendMessage(.MSP_ATTITUDE, data: nil)
        msp.sendMessage(.MSP_ANALOG, data: nil)
        msp.sendMessage(.MSP_WP, data: [ 16  ])             // Altitude hold, mag hold
        //NSLog("Status Requested")
        
        if lastDataReceived != nil && -lastDataReceived!.timeIntervalSinceNow > 0.75 && msp.communicationHealthy {
            // Display warning if no data received for 0.75 sec
            noDataReceived = true
            if !SVProgressHUD.isVisible() {
                SVProgressHUD.showWithStatus("No data received")
            }
        }
    }
    
    func logTimerDidFire(sender: AnyObject) {
        let bytesPerSesond = msp.incomingBytesPerSecond
        NSLog("Bandwidth in: %.01f kbps (%.0f%%)", Double(bytesPerSesond) * 8.0 / 1000.0, Double(bytesPerSesond) * 10.0 * 100 / 115200)
        let config = Configuration.theConfig
        if config.sikRssi != 0 {
            NSLog("SIK RSSI: errors/fixed %d/%d - RSSI %d/%d - Remote %d/%d - Buffer %d", config.rxerrors, config.fixedErrors, config.sikRssi, config.noise, config.sikRemoteRssi, config.remoteNoise, config.txBuffer)
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
         NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
    }

    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    // MARK: FlightDataListener
    
    func receivedData() {
        lastDataReceived = NSDate()
        if noDataReceived {
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
        
        checkArmedStatus()
        
        VoiceMessage.theVoice.checkAlarm(BatteryLowAlarm())
        VoiceMessage.theVoice.checkAlarm(RSSILowAlarm())
        
        if completionHandler != nil {
            completionHandler!(.NewData)
            completionHandler = nil
        }
    }
    
    func receivedGpsData() {
        lastDataReceived = NSDate()
        if noDataReceived {
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
        VoiceMessage.theVoice.checkAlarm(GPSFixLostAlarm())
    }
    
    func communicationStatus(status: Bool) {
        if !status {
            stopTimer()
            armed = false
            _totalArmedTime = 0.0
            _lastArmedTime = 0.0
            lastArming = nil
            
            followMeActive = false
            
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
    }
    
    // MARK:

    func checkArmedStatus() {
        if Settings.theSettings.isModeOn(.ARM, forStatus: Configuration.theConfig.mode) && !armed {
            armed = true
            lastArming = NSDate()
            if msp.communicationEstablished && !msp.replaying && userDefaultEnabled(.RecordFlightlog) {
                startFlightlogRecording()
            }
        }
        else if !Settings.theSettings.isModeOn(.ARM, forStatus: Configuration.theConfig.mode) && armed {
            armed = false
            _lastArmedTime = -lastArming!.timeIntervalSinceNow
            _totalArmedTime += _lastArmedTime
            lastArming = nil
            stopFlightlogRecording()
        }
    }
    
    var totalArmedTime: Double {
        return _totalArmedTime - (lastArming?.timeIntervalSinceNow ?? 0.0)
    }
    
    var lastArmedTime: Double {
        if lastArming == nil {
            // Disarmed
            return _lastArmedTime
        } else {
            // Armed
            return -(lastArming?.timeIntervalSinceNow ?? 0.0)
        }
    }
    
    func startFlightlogRecording() {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent(String(format: "record-%f.rec", NSDate.timeIntervalSinceReferenceDate()))
        
        FlightLogFile.openForWriting(fileURL, msp: msp)
    }

    func stopFlightlogRecording() {
        FlightLogFile.close(msp)
    }

    func userDefaultsDidChange(sender: AnyObject) {
        // This will start or stop the flight log as needed if the user setting changed
        if msp.communicationEstablished && !msp.replaying && armed {
            if userDefaultEnabled(.RecordFlightlog) && msp.datalog == nil {
                startFlightlogRecording()
            } else if !userDefaultEnabled(.RecordFlightlog) && msp.datalog != nil {
                stopFlightlogRecording()
            }
        }
    }

    func stayAliveTimer(timer: NSTimer) {
        // If connected to a live aircraft, disable screen saver
        UIApplication.sharedApplication().idleTimerDisabled = false
        if msp.communicationEstablished && !msp.replaying && userDefaultEnabled(.DisableIdleTimer) {
                UIApplication.sharedApplication().idleTimerDisabled = true
        }
    }
    
    // FIXME Doesn't seem to be ever called. Actually being called very very very unfrequently (hours?)
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if !userDefaultEnabled(.RecordFlightlog) || !armed {
            completionHandler(.NoData)
            return
        }
        self.completionHandler = completionHandler
        statusTimerDidFire(statusTimer)
    }
    
    var followMeActive = false {
        didSet {
            if followMeActive && !msp.replaying {
                if locationManager == nil {
                    locationManager = CLLocationManager()
                }
                locationManager!.delegate = self
                locationManager!.desiredAccuracy = kCLLocationAccuracyBest      // kCLLocationAccuracyBestForNavigation?
                locationManager!.requestAlwaysAuthorization()
                locationManager!.startUpdatingLocation()
                
            } else {
                locationManager?.stopUpdatingLocation()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if lastFollowMeUpdate == nil || -lastFollowMeUpdate!.timeIntervalSinceNow >= followMeUpdatePeriod {
                self.lastFollowMeUpdate = NSDate()
                let longitude = location.coordinate.longitude
                let latitude = location.coordinate.latitude
                NSLog("Sending follow me location %.4f / %.4f", latitude, longitude)
                msp.sendWaypoint(16, latitude: latitude, longitude: longitude, altitude: 0, callback: { success in
                    if !success {
                        self.lastFollowMeUpdate = nil
                    } else {
                        
                    }
                })
            }
        }
    }
}

extension UIViewController {
    var msp: MSPParser {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.msp
    }
    
    var vehicle: Vehicle {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.vehicle
    }
}

protocol RcCommandsProvider {
    func rcCommands() -> [Int]
}
