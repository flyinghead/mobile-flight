//
//  MainNavigationController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MainNavigationController: UITabBarController, UITabBarControllerDelegate {
    var myallViewControllers: [UIViewController]!       // allViewControllers conflicts silently with a var of the superclass !!
    var allViewControllersEnabled = true
    
    override func awakeFromNib() {
        self.delegate = self
        
        var storyboard = UIStoryboard(name: "Telemetry", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 0)
            selectedViewController = controller
        }
        storyboard = UIStoryboard(name: "Map", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 1)
        }
        storyboard = UIStoryboard(name: "Calibration", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 2)
        }
        storyboard = UIStoryboard(name: "Receiver", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 3)
        }
        storyboard = UIStoryboard(name: "Modes", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 4)
        }
        storyboard = UIStoryboard(name: "PIDTuning", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 5)
        }
        storyboard = UIStoryboard(name: "Configuration", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 8)
        }
        storyboard = UIStoryboard(name: "Sensors", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 10)
        }

        storyboard = UIStoryboard(name: "INav", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 9)
        }

        storyboard = UIStoryboard(name: "OSD", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 9)
        }
        
        customizableViewControllers = viewControllers!.filter({
            return !($0 is Telemetry2ViewController)
        })
        
        // Restore the user-customized order of tabs if any
        // For resetting during development NSUserDefaults.standardUserDefaults().removeObjectForKey("MainTabBarOrder")
        if let tabOrder = NSUserDefaults.standardUserDefaults().objectForKey("MainTabBarOrder") as? [Int] {
            if tabOrder.count == viewControllers?.count {
                var tagIndexes = [Int : Int]()
                for i in 0 ..< viewControllers!.count {
                    tagIndexes[viewControllers![i].tabBarItem.tag] = i
                }
                var newOrder = [UIViewController]()
                for tag in tabOrder {
                    newOrder.append(viewControllers![tagIndexes[tag]!])
                }
                viewControllers = newOrder
            }
        }

        myallViewControllers = viewControllers
    }
    
    private func isOfType<T: UIViewController>(viewController: UIViewController, type: T.Type) -> Bool {
        if viewController is T {
            return true
        }
        if let navVC = viewController as? UINavigationController {
            return navVC.topViewController is T
        } else {
            return false
        }
    }
    
    func removeViewControllersForReplay() {
        allViewControllersEnabled = false
        let filteredVC = viewControllers?.filter({
            self.isOfType($0, type: Telemetry2ViewController.self)
                || self.isOfType($0, type: MapViewController.self)
                || self.isOfType($0, type: GPSViewController.self)
                || self.isOfType($0, type: SensorPagesViewController.self)
                || self.isOfType($0, type: AppSettingsViewController.self)
        })
        setViewControllers(filteredVC, animated: false)
    }
    
    func enableAllViewControllers() {
        allViewControllersEnabled = true
        var viewControllers = myallViewControllers
        let config = Configuration.theConfig
        if !config.isINav {
            viewControllers = viewControllers.filter({
                !self.isOfType($0, type: INavSettingsViewController.self)
            })
        }
        if !config.isINav && !config.isApiVersionAtLeast("1.31") {
            viewControllers = viewControllers.filter({
                !self.isOfType($0, type: OSDViewController.self)
            })
        }
        setViewControllers(viewControllers, animated: false)
    }
    
    func tabBarController(tabBarController: UITabBarController, didEndCustomizingViewControllers viewControllers: [UIViewController], changed: Bool) {
        let config = Configuration.theConfig
        
        if allViewControllersEnabled {
            var tabOrder = [Int]()
            for vc in self.viewControllers! {
                tabOrder.append(vc.tabBarItem.tag)
            }
            if !config.isINav {
                let inavVC = myallViewControllers.filter({
                    self.isOfType($0, type: INavSettingsViewController.self)
                }).first!
                tabOrder.append(inavVC.tabBarItem.tag)
            }
            if !config.isINav && !config.isApiVersionAtLeast("1.31") {
                let osdVC = myallViewControllers.filter({
                    self.isOfType($0, type: OSDViewController.self)
                }).first!
                tabOrder.append(osdVC.tabBarItem.tag)
            }
            NSUserDefaults.standardUserDefaults().setObject(tabOrder, forKey: "MainTabBarOrder")
        }

    }
}
