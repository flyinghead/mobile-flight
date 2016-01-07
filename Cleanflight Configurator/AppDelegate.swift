//
//  AppDelegate.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//
import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FlightDataListener {

    var window: UIWindow?
    var msp = MSPParser()
    
    var statusTimer: NSTimer?
    var armed = false
    var _armedTime = 0.0
    var lastArming: NSDate?
    
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let pageControl = UIPageControl.appearance()
        pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.backgroundColor = UIColor.whiteColor()
        
        registerInitialUserDefaults()
        
        msp.addDataListener(self)
        
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(0.2)   // 0.25 less the roundtrip time
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDefaultsDidChange:", name: NSUserDefaultsDidChangeNotification, object: nil)

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
        if msp.communicationEstablished {
            //NSLog("AppDelegate starting statusTimer")
            statusTimer = NSTimer.scheduledTimerWithTimeInterval(0.25, target: self, selector: "statusTimerDidFire:", userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        if statusTimer != nil {
            //NSLog("AppDelegate stopping statusTimer")
            statusTimer!.invalidate()
            statusTimer = nil
        }
    }
    
    func statusTimerDidFire(timer: NSTimer) {
        msp.sendMessage(.MSP_STATUS, data: nil)
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
    
    func receivedData() {
        checkArmedStatus()

        if completionHandler != nil {
            completionHandler!(.NewData)
            completionHandler = nil
        }
    }
    
    func communicationStatus(status: Bool) {
        if !status {
            stopTimer()
            armed = false
            _armedTime = 0.0
            lastArming = nil
        }
    }
    
    func checkArmedStatus() {
        if Settings.theSettings.isModeOn(.ARM, forStatus: Configuration.theConfig.mode) && !armed {
            armed = true
            lastArming = NSDate()
            if !msp.replaying && userDefaultEnabled(.RecordFlightlog) {
                startFlightlogRecording()
            }
        }
        else if !Settings.theSettings.isModeOn(.ARM, forStatus: Configuration.theConfig.mode) && armed {
            armed = false
            _armedTime -= lastArming!.timeIntervalSinceNow
            lastArming = nil
            stopFlightlogRecording()
        }
    }
    
    var armedTime: Double {
        return _armedTime - (lastArming?.timeIntervalSinceNow ?? 0.0)
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
        if !msp.replaying && armed {
            if userDefaultEnabled(.RecordFlightlog) && msp.datalog == nil {
                startFlightlogRecording()
            } else if !userDefaultEnabled(.RecordFlightlog) && msp.datalog != nil {
                stopFlightlogRecording()
            }
        }
    }

    // FIXME Doesn't seem to be ever called. Actually being called very very very unfrequently (hours?)
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        if !userDefaultEnabled(.RecordFlightlog) {
            completionHandler(.NoData)
            return
        }
        self.completionHandler = completionHandler
        msp.sendMessage(.MSP_STATUS, data: nil)
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