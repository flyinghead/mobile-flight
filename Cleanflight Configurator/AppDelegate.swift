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

typealias LocationCallback = (GPSLocation) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FlightDataListener, CLLocationManagerDelegate, UserLocationProvider {

    var window: UIWindow?
    var msp = MSPParser()
    
    private var statusTimer: NSTimer?
    private var statusSwitch = false        // Used to alternate between RAW_GPS and COMP_GPS during each status timer callback since GPS info is only updated at 5 Hz
    private var statusTimerInterval = 0.0
    private let statusTimerMinInterval = 0.1

    private var lastDataReceived: NSDate?
    private var noDataReceived = false
    private var armed = false
    private var _totalArmedTime = 0.0
    private var _lastArmedTime = 0.0
    private var lastArming: NSDate?
    
    private var stayAliveTimer: NSTimer!
    
    private var rcCommands: [Int]?
    var rcCommandsProvider: RcCommandsProvider?
    
    private var _locationManager: CLLocationManager?
    private var lastFollowMeUpdate: NSDate?
    private let followMeUpdatePeriod: NSTimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    private var currentLocationCallbacks = [LocationCallback]()
    private var updatingLocation = false
    
    private var mspCommandSenders = [MSPCommandSender]()
    
    private var logTimer: NSTimer?      // DEBUG
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.backgroundColor = UIColor.whiteColor()
        
        registerInitialUserDefaults()
        
        msp.addDataListener(self)
        
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(0.2)   // 0.25 less the roundtrip time
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.userDefaultsDidChange(_:)), name: kIASKAppSettingChanged, object: nil)

        stayAliveTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(AppDelegate.stayAliveTimer(_:)), userInfo: nil, repeats: true)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Keep the status timer active if armed so we can continue to record telemetry
        if !armed || msp.replaying || !userDefaultEnabled(.RecordFlightlog) {
            stopTimer()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        startTimer()
    }
    
    func startTimer() {
        if msp.communicationEstablished {
            if statusTimer == nil {
                statusTimerDidFire(nil)
            }
        }
        if logTimer == nil {
            logTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(AppDelegate.logTimerDidFire(_:)), userInfo: nil, repeats: true)
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

        msp.sendMessage(.MSP_STATUS, data: nil, flush: false)
        statusSwitch = !statusSwitch
        if statusSwitch {
            msp.sendMessage(.MSP_RAW_GPS, data: nil, flush: false)
        } else {
            msp.sendMessage(.MSP_COMP_GPS, data: nil, flush: false)       // distance to home, direction to home
        }
        msp.sendMessage(.MSP_ALTITUDE, data: nil, flush: false)
        msp.sendMessage(.MSP_ATTITUDE, data: nil, flush: false)
        msp.sendMessage(.MSP_ANALOG, data: nil, flush: false)
        // WP #0 = home, WP #16 = poshold
        msp.sendMessage(.MSP_WP, data: [ statusSwitch ? 0 : 16  ])   // Altitude hold, mag hold
        
        for sender in mspCommandSenders {
            sender.sendMSPCommands()
        }
        //NSLog("Status Requested")
        
        if lastDataReceived != nil && -lastDataReceived!.timeIntervalSinceNow > max(0.75, statusTimerInterval) && msp.communicationHealthy {
            // Display warning if no data received for 0.75 sec (or last status interval if bigger)
            noDataReceived = true
            if !SVProgressHUD.isVisible() {
                SVProgressHUD.showWithStatus("No data received")
            }
        }
        
        statusTimerInterval = constrain(msp.latency * 1.33, min: statusTimerMinInterval, max: 1)
        statusTimer = NSTimer(timeInterval: statusTimerInterval, target: self, selector: #selector(AppDelegate.statusTimerDidFire(_:)), userInfo: nil, repeats: false)
        NSRunLoop.mainRunLoop().addTimer(statusTimer!, forMode: NSRunLoopCommonModes)
    }

    func logTimerDidFire(sender: AnyObject) {
        let bytesPerSesond = msp.incomingBytesPerSecond
        NSLog("Bandwidth in: %.01f kbps (%.0f%%), latency %.0f ms, statusTimer %.0f ms", Double(bytesPerSesond) * 8.0 / 1000.0, Double(bytesPerSesond) * 10.0 * 100 / 115200, msp.latency * 1000, statusTimerInterval * 1000)
        
        let config = Configuration.theConfig
        if config.sikRssi != 0 {
            NSLog("SIK RSSI: errors/fixed %d/%d - RSSI %d/%d - Remote %d/%d - Buffer %d", config.rxerrors, config.fixedErrors, config.sikRssi, config.noise, config.sikRemoteRssi, config.remoteNoise, config.txBuffer)
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        msp.closeCommChannel()
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kIASKAppSettingChanged, object: nil)
    }

    func application(application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    private func dismissNoDataReceived() {
        lastDataReceived = NSDate()
        if noDataReceived {
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
    }
    
    // MARK: FlightDataListener
    
    func receivedData() {
        dismissNoDataReceived()
        
        checkArmedStatus()
        
        VoiceMessage.theVoice.checkAlarm(BatteryLowAlarm())
        VoiceMessage.theVoice.checkAlarm(RSSILowAlarm())
    }
    
    func receivedSensorData() {
        dismissNoDataReceived()
    }
    
    func receivedAltitudeData() {
        dismissNoDataReceived()
    }
    
    func receivedGpsData() {
        dismissNoDataReceived()
        VoiceMessage.theVoice.checkAlarm(GPSFixLostAlarm())
    }
    
    func communicationStatus(status: Bool) {
        if !status {
            VoiceMessage.theVoice.stopAll()
            stopTimer()
            armed = false
            _totalArmedTime = 0.0
            _lastArmedTime = 0.0
            lastArming = nil
            
            followMeActive = false
            
            SVProgressHUD.dismiss()
            noDataReceived = false
        } else {
            // Update the weather reports
            MetarManager.instance.locationProvider = self
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
    
    var followMeActive = false {
        didSet {
            if followMeActive && !msp.replaying {
                startLocationManager()
            } else if currentLocationCallbacks.isEmpty {
                stopLocationManager()
            }
        }
    }
    
    private var locationManager: CLLocationManager {
        if _locationManager == nil {
            _locationManager = CLLocationManager()
            _locationManager!.delegate = self
            _locationManager!.desiredAccuracy = kCLLocationAccuracyBest      // kCLLocationAccuracyBestForNavigation?
            _locationManager!.requestAlwaysAuthorization()
        }
        return _locationManager!
    }
    
    private func startLocationManager() {
        if !updatingLocation {
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    private func stopLocationManager() {
        if _locationManager != nil {
            _locationManager!.stopUpdatingLocation()
        }
        updatingLocation = false
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if followMeActive && (lastFollowMeUpdate == nil || -lastFollowMeUpdate!.timeIntervalSinceNow >= followMeUpdatePeriod) {
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
            for callback in currentLocationCallbacks {
                callback(GPSLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            }
            currentLocationCallbacks.removeAll()
            if !followMeActive {
                stopLocationManager()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
            stopLocationManager()
            currentLocationCallbacks.removeAll()
            followMeActive = false      // FIXME Should deselect and disable UI
        }
    }
    
    func currentLocation(callback: LocationCallback) {
        if !msp.replaying {
            currentLocationCallbacks.append(callback)
            startLocationManager()
        }
    }
    
    func addMSPCommandSender(sender: MSPCommandSender) {
        mspCommandSenders.append(sender)
    }
    
    func removeMSPCommandSender(sender: MSPCommandSender) {
        if let index = mspCommandSenders.indexOf({ $0 === sender }) {
            mspCommandSenders.removeAtIndex(index)
        }
    }
}

extension UIViewController {
    var msp: MSPParser {
        get {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            return appDelegate.msp
        }
    }
}

protocol RcCommandsProvider {
    func rcCommands() -> [Int]
}

protocol UserLocationProvider {
    func currentLocation(callback: LocationCallback)
}

protocol MSPCommandSender : class {
    func sendMSPCommands()
}
