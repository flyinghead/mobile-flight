//
//  WaypointPageViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class WaypointPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var waypointList: MKWaypointList! {
        didSet {
            waypointList.indexChangedEvent.addHandler(self, handler: WaypointPageViewController.indexChanged)
            waypointList.waypointDeletedEvent.addHandler(self, handler: WaypointPageViewController.waypointDeleted)
        }
    }
    
    private var waypointControllers = [UIViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        waypointControllers.removeAll()
        var rthSeen = false
        for (i, waypoint) in waypointList.enumerate() {
            let viewController: BaseWaypointDetailViewController
            if !waypoint.returnToHome {
                viewController = storyboard!.instantiateViewControllerWithIdentifier("WaypointDetail") as! BaseWaypointDetailViewController
            } else {
                viewController = storyboard!.instantiateViewControllerWithIdentifier("ReturnToHomeDetail") as! BaseWaypointDetailViewController
                rthSeen = true
            }
            viewController.waypointList = waypointList
            viewController.index = i
            waypointControllers.append(viewController)
        }
        if !rthSeen && waypointControllers.count < INavConfig.theINavConfig.maxWaypoints {
            let viewController = storyboard!.instantiateViewControllerWithIdentifier("ReturnToHomeDetail") as! BaseWaypointDetailViewController
            viewController.waypointList = waypointList
            viewController.index = waypointList.count
            waypointControllers.append(viewController)
        }
        setViewControllers([ waypointControllers[waypointList.index] ], direction: .Forward, animated: false, completion: nil)
    }
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let index = waypointControllers.indexOf(viewController) where index > 0 {
            return waypointControllers[index - 1]
        } else {
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let index = waypointControllers.indexOf(viewController) where index < waypointControllers.count - 1 {
            return waypointControllers[index + 1]
        } else {
            return nil
        }
    }
    
    func indexChanged(data: Int) {
        if data >= 0 && data < waypointControllers.count {
            var direction = UIPageViewControllerNavigationDirection.Reverse
            if let currentVC = viewControllers?.first {
                if let index = waypointControllers.indexOf(currentVC) where index < data {
                    direction = UIPageViewControllerNavigationDirection.Forward
                }
            }
            setViewControllers([waypointControllers[data]], direction: direction, animated: true, completion: nil)
        }
    }

    func waypointDeleted(data: MKWaypoint) {
        if data.returnToHome {
            return
        }
        if let index = waypointList.indexOf(data) {
            waypointControllers.removeAtIndex(index)
            for i in index ..< waypointControllers.count {
                (waypointControllers[i] as! BaseWaypointDetailViewController).index -= 1
            }
        }
    }
    
    // MARK: UIPageViewControllerDelegate
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            return
        }
        if let currentVC = viewControllers?.first {
            if let index = waypointControllers.indexOf(currentVC) {
                waypointList.index = index
            }
        }
    }
}
