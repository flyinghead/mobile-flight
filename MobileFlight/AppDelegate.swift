//
//  AppDelegate.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 02/12/15.
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

import Foundation
import UIKit
import SVProgressHUD
import CoreLocation
import Firebase
import Fabric
import Crashlytics

typealias LocationCallback = (GPSLocation) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UserLocationProvider, CrashlyticsDelegate {

    var window: UIWindow?
    var msp = MSPParser()
    
    fileprivate var statusTimer: Timer?
    fileprivate var statusSwitch = false        // Used to alternate between RAW_GPS and COMP_GPS during each status timer callback since GPS info is only updated at 5 Hz
    fileprivate var statusTimerInterval = 0.0
    fileprivate let statusTimerMinInterval = 0.1

    fileprivate var lastDataReceived: Date?
    fileprivate var noDataReceived = false
    fileprivate var armed = false
    fileprivate var _totalArmedTime = 0.0
    fileprivate var _lastArmedTime = 0.0
    fileprivate var lastArming: Date?
    
    fileprivate var stayAliveTimer: Timer!
    
    fileprivate var rcCommands: [Int]?
    var rcCommandsProvider: RcCommandsProvider?
    
    fileprivate var _locationManager: CLLocationManager?
    fileprivate var lastFollowMeUpdate: Date?
    fileprivate let followMeUpdatePeriod: TimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    fileprivate var currentLocationCallbacks = [LocationCallback]()
    fileprivate var updatingLocation = false
    
    fileprivate var mspCommandSenders = [MSPCommandSender]()
    
    fileprivate var logTimer: Timer?      // DEBUG
    
    var active = false                  // True if the app is active or recording telemetry in the background
    var showBtRssi = false
    var lastINavStatus = ""
    
    var usageReportingEnabled = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        usageReportingEnabled = userDefaultEnabled(.UsageReporting)
        
        FirebaseApp.configure()
        AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(usageReportingEnabled)
        
        Crashlytics.sharedInstance().delegate = self
        Fabric.with([Crashlytics.self])
        
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.black
        pageControl.backgroundColor = UIColor.white
        
        registerInitialUserDefaults()
        
        _ = msp.rssiEvent.addHandler(self, handler: AppDelegate.receivedRssiData)
        _ = msp.flightModeEvent.addHandler(self, handler: AppDelegate.checkArmedStatus)
        _ = msp.batteryEvent.addHandler(self, handler: AppDelegate.receivedBatteryData)
        _ = msp.gpsEvent.addHandler(self, handler: AppDelegate.receivedGpsData)
        _ = msp.communicationEvent.addHandler(self, handler: AppDelegate.communicationStatus)
        _ = msp.dataReceivedEvent.addHandler(self, handler: AppDelegate.dismissNoDataReceived)
        _ = msp.navigationEvent.addHandler(self, handler: AppDelegate.navigationEventReceived)
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(0.2)   // 0.25 less the roundtrip time
        
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.userDefaultsDidChange(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)

        active = true

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Keep the timers active if armed so we can continue to record telemetry
        if !armed || msp.replaying || !userDefaultEnabled(.RecordFlightlog) {
            stopTimer()
            active = false
        } else {
            // This one however is useless while in background
            stayAliveTimer?.invalidate()
            stayAliveTimer = nil
        }
        if !followMeActive {
            stopLocationManager()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        startTimer()
        startLocationManagerIfNeeded()
        active = true
    }
    
    func startTimer() {
        if msp.communicationEstablished {
            if statusTimer == nil {
                statusTimerDidFire(nil)
            }
        }
        if logTimer == nil {
            logTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(AppDelegate.logTimerDidFire(_:)), userInfo: nil, repeats: true)
        }
        if stayAliveTimer == nil {
            stayAliveTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(AppDelegate.stayAliveTimer(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        statusTimer?.invalidate()
        statusTimer = nil
        
        logTimer?.invalidate()
        logTimer = nil
        
        stayAliveTimer?.invalidate()
        stayAliveTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        
        lastDataReceived = nil
    }
    
    func statusTimerDidFire(_ timer: Timer?) {
        if rcCommandsProvider != nil {
            rcCommands = rcCommandsProvider!.rcCommands()
        }
        if rcCommands != nil {
            msp.sendRawRc(rcCommands!)
        }

        msp.sendMessage(.msp_STATUS_EX, data: nil, flush: false)
        statusSwitch = !statusSwitch
        if statusSwitch {
            msp.sendMessage(.msp_RAW_GPS, data: nil, flush: false)
        } else {
            msp.sendMessage(.msp_COMP_GPS, data: nil, flush: false)       // distance to home, direction to home
        }
        msp.sendMessage(.msp_ALTITUDE, data: nil, flush: false)
        msp.sendMessage(.msp_ATTITUDE, data: nil, flush: false)
        msp.sendMessage(.msp_ANALOG, data: nil, flush: false)
        // WP #0 = home, WP #16 (or 255 for INav) = poshold
        let config = Configuration.theConfig
        msp.sendMessage(.msp_WP, data: [ statusSwitch ? 0 : config.isINav ? 255 : 16  ], flush: false)   // Altitude hold, mag hold
        msp.sendMessage(.msp_RC, data: nil)
        if armed && config.isINav {
            msp.sendMessage(.msp_NAV_STATUS, data: nil)
        }

        for sender in mspCommandSenders {
            sender.sendMSPCommands()
        }
        
        msp.readBluetoothRssi()
        
        if lastDataReceived != nil && -lastDataReceived!.timeIntervalSinceNow > max(0.75, statusTimerInterval) && msp.communicationHealthy {
            // Display warning if no data received for 0.75 sec (or last status interval if bigger)
            noDataReceived = true
            if !SVProgressHUD.isVisible() {
                SVProgressHUD.show(withStatus: "No data received")
            }
        }
        
        statusTimerInterval = constrain(msp.latency * 1.33, min: statusTimerMinInterval, max: 1)
        statusTimer = Timer(timeInterval: statusTimerInterval, target: self, selector: #selector(AppDelegate.statusTimerDidFire(_:)), userInfo: nil, repeats: false)
        RunLoop.main.add(statusTimer!, forMode: RunLoopMode.commonModes)
    }

    func logTimerDidFire(_ sender: Any) {
        let bytesPerSesond = msp.incomingBytesPerSecond
        NSLog("Bandwidth in: %.01f kbps (%.0f%%), latency %.0f ms, statusTimer %.0f ms", Double(bytesPerSesond) * 8.0 / 1000.0, Double(bytesPerSesond) * 10.0 * 100 / 115200, msp.latency * 1000, statusTimerInterval * 1000)
        
        let config = Configuration.theConfig
        if config.sikRssi != 0 {
            NSLog("SIK RSSI: errors/fixed %d/%d - RSSI %d/%d - Remote %d/%d - Buffer %d", config.rxerrors, config.fixedErrors, config.sikRssi, config.noise, config.sikRemoteRssi, config.remoteNoise, config.txBuffer)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        active = false
        msp.closeCommChannel()
        
        NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
    }

    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        return true
    }
    
    // MARK: Event Handlers
    
    fileprivate func dismissNoDataReceived() {
        lastDataReceived = Date()
        if noDataReceived {
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
    }
    
    fileprivate func receivedBatteryData() {
        VoiceMessage.theVoice.checkAlarm(BatteryLowAlarm())
    }
    
    fileprivate func receivedRssiData() {
        VoiceMessage.theVoice.checkAlarm(RSSILowAlarm())
    }
    
    fileprivate func receivedGpsData() {
        VoiceMessage.theVoice.checkAlarm(GPSFixLostAlarm())
    }
    
    fileprivate func communicationStatus(_ status: Bool) {
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
            // If replaying, we won't get an event since craft is already armed so do it now
            checkArmedStatus()
        }
    }
    
    func checkArmedStatus() {
        if Settings.theSettings.armed && !armed {
            Analytics.logEvent("uav_armed", parameters: nil)
            armed = true
            lastArming = Date()
            if msp.communicationEstablished && !msp.replaying && userDefaultEnabled(.RecordFlightlog) {
                startFlightlogRecording()
            }
        }
        else if !Settings.theSettings.armed && armed {
            armed = false
            _lastArmedTime = -lastArming!.timeIntervalSinceNow
            _totalArmedTime += _lastArmedTime
            lastArming = nil
            Analytics.logEvent("uav_disarmed", parameters: [ "duration" : _lastArmedTime ])
            stopFlightlogRecording()
        }
    }
    
    func navigationEventReceived() {
        if Configuration.theConfig.isINav && userDefaultEnabled(.INavAlert) {
            if let (navStatus, spoken, _) = INavState.theINavState.navStateDescription, navStatus != lastINavStatus {
                self.lastINavStatus = navStatus
                VoiceMessage.theVoice.speak(spoken)
            }
        }
    }
    
    // MARK:
    
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
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(String(format: "record-%f.rec", Date.timeIntervalSinceReferenceDate))
        
        FlightLogFile.openForWriting(fileURL, msp: msp)
    }

    func stopFlightlogRecording() {
        FlightLogFile.close(msp)
    }

    func userDefaultsDidChange(_ sender: Any) {
        // This will start or stop the flight log as needed if the user setting changed
        if msp.communicationEstablished && !msp.replaying && armed {
            if userDefaultEnabled(.RecordFlightlog) && msp.datalog == nil {
                startFlightlogRecording()
            } else if !userDefaultEnabled(.RecordFlightlog) && msp.datalog != nil {
                stopFlightlogRecording()
            }
        }
        if usageReportingEnabled != userDefaultEnabled(.UsageReporting) {
            usageReportingEnabled = userDefaultEnabled(.UsageReporting)
            AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(usageReportingEnabled)
        }
    }

    func stayAliveTimer(_ timer: Timer) {
        // If connected to a live aircraft, disable screen saver
        UIApplication.shared.isIdleTimerDisabled = false
        if msp.communicationEstablished && !msp.replaying && userDefaultEnabled(.DisableIdleTimer) {
                UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    var followMeActive = false {
        didSet {
            if oldValue != followMeActive {
                Analytics.logEvent("follow_me", parameters: ["on" : followMeActive])
            }
            startLocationManagerIfNeeded()
            // else
            if !followMeActive && currentLocationCallbacks.isEmpty {
                stopLocationManager()
            }
        }
    }
    
    fileprivate func startLocationManagerIfNeeded() {
        if (followMeActive || !currentLocationCallbacks.isEmpty) && !msp.replaying {
            startLocationManager()
        }
    }
    
    fileprivate var locationManager: CLLocationManager {
        if _locationManager == nil {
            _locationManager = CLLocationManager()
            _locationManager!.delegate = self
            _locationManager!.desiredAccuracy = kCLLocationAccuracyBest      // kCLLocationAccuracyBestForNavigation?
            _locationManager!.requestAlwaysAuthorization()
        }
        return _locationManager!
    }
    
    fileprivate func startLocationManager() {
        if !updatingLocation {
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    fileprivate func stopLocationManager() {
        if _locationManager != nil {
            _locationManager!.stopUpdatingLocation()
        }
        updatingLocation = false
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if followMeActive && (lastFollowMeUpdate == nil || -lastFollowMeUpdate!.timeIntervalSinceNow >= followMeUpdatePeriod) {
                self.lastFollowMeUpdate = Date()
                let longitude = location.coordinate.longitude
                let latitude = location.coordinate.latitude
                NSLog("Sending follow me location %.4f / %.4f", latitude, longitude)
                msp.setGPSHoldPosition(latitude: latitude, longitude: longitude, altitude: 0) { success in
                    if !success {
                        self.lastFollowMeUpdate = nil
                    } else {
                        
                    }
                }
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let nserror = error as NSError
        if nserror.domain == kCLErrorDomain && nserror.code == CLError.Code.denied.rawValue {
            stopLocationManager()
            currentLocationCallbacks.removeAll()
            followMeActive = false      // FIXME Should deselect and disable UI
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startLocationManagerIfNeeded()
        }
    }
    
    // MARK: UserLocationProvider
    
    func currentLocation(_ callback: @escaping LocationCallback) {
        if !msp.replaying {
            currentLocationCallbacks.append(callback)
            startLocationManager()
        }
    }
    
    // MARK:
    
    func addMSPCommandSender(_ sender: MSPCommandSender) {
        mspCommandSenders.append(sender)
    }
    
    func removeMSPCommandSender(_ sender: MSPCommandSender) {
        if let index = mspCommandSenders.index(where: { $0 === sender }) {
            mspCommandSenders.remove(at: index)
        }
    }
    
    // MARK: CrashlyticsDelegate

    func crashlyticsDidDetectReport(forLastExecution report: CLSReport, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(userDefaultEnabled(.UsageReporting))
    }
}

extension UIViewController {
    var appDelegate: AppDelegate {
        get {
            return UIApplication.shared.delegate as! AppDelegate
        }
    }
    var msp: MSPParser {
        get {
            return appDelegate.msp
        }
    }
}

protocol RcCommandsProvider {
    func rcCommands() -> [Int]
}

protocol UserLocationProvider : class {
    func currentLocation(_ callback: @escaping LocationCallback)
}

protocol MSPCommandSender : class {
    func sendMSPCommands()
}
