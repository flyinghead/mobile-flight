//
//  MainNavigationController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MainNavigationController: UITabBarController, UITabBarControllerDelegate {
    var myallViewControllers: [UIViewController]?       // allViewControllers conflicts silently with a var of the superclass !!
    var allViewControllersEnabled = true
    
    override func awakeFromNib() {
        self.delegate = self
        
        var storyboard = UIStoryboard(name: "Configuration", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 6)
        }
        storyboard = UIStoryboard(name: "Sensors", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 8)
        }
        storyboard = UIStoryboard(name: "Telemetry", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 0)
            selectedViewController = controller
        }
        let controller = storyboard.instantiateViewControllerWithIdentifier("MapViewController")
        viewControllers!.insert(controller, atIndex: 1)
        
        customizableViewControllers = viewControllers!.filter({
            return !($0 is Telemetry2ViewController)
        })
        
        // Restore the user-customized order of tabs if any
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
    
    func removeViewControllersForReplay() {
        allViewControllersEnabled = false
        let filteredVC = viewControllers?.filter({
            var viewController = $0
            if let navigationController = viewController as? UINavigationController {
                viewController = navigationController.topViewController ?? viewController
            }
            return viewController is Telemetry2ViewController
                || viewController is MapViewController
                || viewController is GPSViewController
                || viewController is SensorPagesViewController
                || viewController is AppSettingsViewController
        })
        setViewControllers(filteredVC, animated: false)
    }
    
    func enableAllViewControllers() {
        allViewControllersEnabled = true
        setViewControllers(myallViewControllers, animated: false)
    }
    
    func tabBarController(tabBarController: UITabBarController, didEndCustomizingViewControllers viewControllers: [UIViewController], changed: Bool) {
        if allViewControllersEnabled {
            var tabOrder = [Int]()
            for vc in self.viewControllers! {
                tabOrder.append(vc.tabBarItem.tag)
            }
            NSUserDefaults.standardUserDefaults().setObject(tabOrder, forKey: "MainTabBarOrder")
        }

    }
}
