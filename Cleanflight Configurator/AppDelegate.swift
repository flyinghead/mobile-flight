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
    var protocolHandler: ProtocolHandler!
    var msp = MSPParser()
    var vehicle = Vehicle() {
        didSet {
            registerVehicleObservers()
        }
    }
    
    private var noDataReceived = false
    
    private var stayAliveTimer: NSTimer!
    
    private var locationManager: CLLocationManager?
    private var lastFollowMeUpdate: NSDate?
    private let followMeUpdatePeriod: NSTimeInterval = 2.0      // 2s in ArduPilot MissionPlanner
    
    private var logTimer: NSTimer?      // DEBUG
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.backgroundColor = UIColor.whiteColor()
        
        registerInitialUserDefaults()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: nil)

        stayAliveTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "stayAliveTimer:", userInfo: nil, repeats: true)
        
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
                self.stopTimer()
                
                self.followMeActive = false
                
                self.dismissNoDataReceived()
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
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        stopTimer()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        startTimer()
    }
    
    func startTimer() {
        if logTimer == nil {
            logTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "logTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        logTimer?.invalidate()
        logTimer = nil
    }

    func logTimerDidFire(sender: AnyObject) {
        let bytesPerSesond = CommSpeedMeter.instance.bytesPerSecond
        NSLog("Bandwidth in: %.01f kb/s (%.0f%%)", Double(bytesPerSesond) * 8.0 / 1000.0, Double(bytesPerSesond) * 10.0 * 100 / 115200)
        /*
        if vehicle.sikRssi.value != 0 {
            let config = Configuration.theConfig
            NSLog("SIK RSSI: errors/fixed %d/%d - RSSI %d/%d - Remote %d/%d - Buffer %d", config.rxerrors, config.fixedErrors, config.sikRssi, config.noise, config.sikRemoteRssi, config.remoteNoise, config.txBuffer)
        }
        */
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
    
    private func dismissNoDataReceived() {
        if noDataReceived {
            SVProgressHUD.dismiss()
            noDataReceived = false
        }
    }

    func userDefaultsDidChange(sender: AnyObject) {
        if userDefaultEnabled(.RecordFlightlog) {
            vehicle.enableFlightRecorder(NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0])
        } else {
            vehicle.disableFlightRecorder()
        }
    }

    func stayAliveTimer(timer: NSTimer) {
        guard let protocolHandler = self.protocolHandler else {
            return
        }
        // If connected to a live aircraft, disable screen saver
        UIApplication.sharedApplication().idleTimerDisabled = false
        if protocolHandler.communicationEstablished && !protocolHandler.replaying && userDefaultEnabled(.DisableIdleTimer) {
                UIApplication.sharedApplication().idleTimerDisabled = true
        }
    }
    
    var followMeActive = false {
        didSet {
            if followMeActive && !protocolHandler.replaying {
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
