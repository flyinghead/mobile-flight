//
//  MainNavigationController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MainNavigationController: UITabBarController {
    var myallViewControllers: [UIViewController]?       // allViewControllers conflicts silently with a var of the superclass !!
    
    override func awakeFromNib() {
        
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
        
        myallViewControllers = viewControllers
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func removeViewControllersForReplay() {
        let filteredVC = viewControllers?.filter({
            var viewController = $0
            if let navigationController = viewController as? UINavigationController {
                viewController = navigationController.topViewController ?? viewController
            }
            return viewController is TelemetryViewController
                || viewController is MapViewController
                || viewController is GPSViewController
                || viewController is SensorPagesViewController
        })
        setViewControllers(filteredVC, animated: false)
    }
    
    func enableAllViewControllers() {
        setViewControllers(myallViewControllers, animated: false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
