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

typealias LocationCallback = (Position) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FlightDataListener, CLLocationManagerDelegate, UserLocationProvider {

    var window: UIWindow?
    var protocolHandler: ProtocolHandler!
    var msp = MSPParser()
    var vehicle = Vehicle() {
        didSet {
            registerVehicleObservers()
        }
    }

    private var noDataReceived = false
    private var armed = false
    
    private var stayAliveTimer: NSTimer!
    
    private var _locationManager: CLLocationManager?
    private var lastFollowMeUpdate: NSDate?
    private let followMeUpdatePeriod: NSTimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    private var currentLocationCallbacks = [LocationCallback]()
    private var updatingLocation = false
    
    private var logTimer: NSTimer?      // DEBUG
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.backgroundColor = UIColor.whiteColor()
        
        registerInitialUserDefaults()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.userDefaultsDidChange(_:)), name: NSUserDefaultsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.userDefaultsDidChange(_:)), name: kIASKAppSettingChanged, object: nil)

        stayAliveTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(AppDelegate.stayAliveTimer(_:)), userInfo: nil, repeats: true)
        
        startTimer()
        registerVehicleObservers()

        return true
    }
    
    private func registerVehicleObservers() {
        vehicle.batteryVolts.addObserver(self, listener: { newValue in
            VoiceMessage.theVoice.checkAlarm(BatteryLowAlarm())
        })
        vehicle.rssi.addObserver(self, listener: { newValue in
            VoiceMessage.theVoice.checkAlarm(RSSILowAlarm())
        })
        vehicle.gpsFix.addObserver(self, listener: { newValue in
            VoiceMessage.theVoice.checkAlarm(GPSFixLostAlarm())
        })
        vehicle.connected.addObserver(self, listener: { newValue in
            if !newValue {
                VoiceMessage.theVoice.stopAll()
                self.stopTimer()
                self.armed = false
                self.followMeActive = false
                self.dismissNoDataReceived()
            } else {
                self.startTimer()
                // Update the weather reports
                MetarManager.instance.locationProvider = self
            }
        })
        vehicle.noDataReceived.addObserver(self, listener: { newValue in
            if newValue {
                self.noDataReceived = true
                if !SVProgressHUD.isVisible() {
                    SVProgressHUD.showWithStatus("No data received")
                }
            } else {
                self.dismissNoDataReceived()
            }
        })
        userDefaultsDidChange(self)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Keep the timers active if armed so we can continue to record telemetry
        if !armed || protocolHandler.replaying || !userDefaultEnabled(.RecordFlightlog) {
            stopTimer()
        } else {
            // This one however is useless while in background
            stayAliveTimer?.invalidate()
            stayAliveTimer = nil
        }
        if !followMeActive {
            stopLocationManager()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        startTimer()
        startLocationManagerIfNeeded()
    }
    
    private func startTimer() {
        if logTimer == nil {
            logTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(AppDelegate.logTimerDidFire(_:)), userInfo: nil, repeats: true)
        }
        if stayAliveTimer == nil {
            stayAliveTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: #selector(AppDelegate.stayAliveTimer(_:)), userInfo: nil, repeats: true)
        }
    }
    
    private func stopTimer() {
        logTimer?.invalidate()
        logTimer = nil
        
        stayAliveTimer?.invalidate()
        stayAliveTimer = nil
    }

    func logTimerDidFire(sender: AnyObject) {
        let bytesPerSesond = CommSpeedMeter.instance.bytesPerSecond
        var latency = 0.0
        if vehicle is MSPVehicle {
            latency = msp.latency
        }
        NSLog("Bandwidth in: %.01f kbps (%.0f%%), latency %.0f ms", Double(bytesPerSesond) * 8.0 / 1000.0, Double(bytesPerSesond) * 10.0 * 100 / 115200, latency * 1000 /* , statusTimerInterval * 1000 */)
        
        let config = Configuration.theConfig
        if config.sikRssi != 0 {
            NSLog("SIK RSSI: errors/fixed %d/%d - RSSI %d/%d - Remote %d/%d - Buffer %d", config.rxerrors, config.fixedErrors, config.sikRssi, config.noise, config.sikRemoteRssi, config.remoteNoise, config.txBuffer)
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        protocolHandler?.closeCommChannel()
        
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
        if noDataReceived {
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
    }

    func userDefaultsDidChange(sender: AnyObject) {
        // This will start or stop the flight log as needed if the user setting changed
        if userDefaultEnabled(.RecordFlightlog) {
            vehicle.enableFlightRecorder(NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0])
        } else {
            vehicle.disableFlightRecorder()
        }
    }

    func stayAliveTimer(timer: NSTimer) {
        UIApplication.sharedApplication().idleTimerDisabled = false
        guard let protocolHandler = self.protocolHandler else {
            return
        }
        // If connected to a live aircraft, disable screen saver
        if protocolHandler.communicationEstablished && !protocolHandler.replaying && userDefaultEnabled(.DisableIdleTimer) {
                UIApplication.sharedApplication().idleTimerDisabled = true
        }
    }
    
    var followMeActive = false {
        didSet {
            startLocationManagerIfNeeded()
            // else
            if !followMeActive && currentLocationCallbacks.isEmpty {
                stopLocationManager()
            }
        }
    }
    
    private func startLocationManagerIfNeeded() {
        if (followMeActive || !currentLocationCallbacks.isEmpty) && !protocolHandler.replaying {
            startLocationManager()
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
                callback(Position(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
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
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways || status == .AuthorizedWhenInUse {
            startLocationManagerIfNeeded()
        }
    }
    
    func currentLocation(callback: LocationCallback) {
        currentLocationCallbacks.append(callback)
        startLocationManager()
    }
}

extension UIViewController {
    var msp: MSPParser {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.msp
    }
    
    var protocolHandler: ProtocolHandler {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.protocolHandler
    }
    
    var vehicle: Vehicle {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.vehicle
    }
    
    var mspvehicle: MSPVehicle {
        return vehicle as! MSPVehicle
    }
}

protocol UserLocationProvider {
    func currentLocation(callback: LocationCallback)
}
