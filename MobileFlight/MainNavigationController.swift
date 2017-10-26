//
//  MainNavigationController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 16/12/15.
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

import UIKit

class MainNavigationController: UITabBarController, UITabBarControllerDelegate {
    var myallViewControllers: [UIViewController]!       // allViewControllers conflicts silently with a var of the superclass !!
    var allViewControllersEnabled = true
    
    override func awakeFromNib() {
        self.delegate = self
        
        var storyboard = UIStoryboard(name: "Telemetry", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 0)
            selectedViewController = controller
        }
        storyboard = UIStoryboard(name: "Map", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 1)
        }
        storyboard = UIStoryboard(name: "Calibration", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 2)
        }
        storyboard = UIStoryboard(name: "Receiver", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 3)
        }
        storyboard = UIStoryboard(name: "Modes", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 4)
        }
        storyboard = UIStoryboard(name: "PIDTuning", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 5)
        }
        storyboard = UIStoryboard(name: "Configuration", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 8)
        }
        storyboard = UIStoryboard(name: "Sensors", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 10)
        }

        storyboard = UIStoryboard(name: "INav", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 9)
        }

        storyboard = UIStoryboard(name: "OSD", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, at: 9)
        }
        
        customizableViewControllers = viewControllers!.filter({
            return !($0 is Telemetry2ViewController)
        })
        
        // Restore the user-customized order of tabs if any
        // For resetting during development NSUserDefaults.standardUserDefaults().removeObjectForKey("MainTabBarOrder")
        if let tabOrder = UserDefaults.standard.object(forKey: "MainTabBarOrder") as? [Int] {
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
    
    fileprivate func isOfType<T: UIViewController>(_ viewController: UIViewController, type: T.Type) -> Bool {
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
            viewControllers = viewControllers?.filter({
                !self.isOfType($0, type: INavSettingsViewController.self)
            })
        }
        if !config.isINav && !config.isApiVersionAtLeast("1.31") {
            viewControllers = viewControllers?.filter({
                !self.isOfType($0, type: OSDViewController.self)
            })
        }
        setViewControllers(viewControllers, animated: false)
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didEndCustomizing viewControllers: [UIViewController], changed: Bool) {
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
            UserDefaults.standard.set(tabOrder, forKey: "MainTabBarOrder")
        }

    }
}
