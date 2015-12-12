//
//  SensorPagesViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 04/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class SensorPagesViewController: UIPageViewController, UIPageViewControllerDataSource {

    var accelerometerViewController: UIViewController?
    var gyroscopeViewController: UIViewController?
    var magnetometerViewController: UIViewController?
    var barometerViewController: UIViewController?
    var sonarViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for subview in view.subviews {
            if (subview is UIPageControl) {
                let pageControl = subview as! UIPageControl
                pageControl.pageIndicatorTintColor = UIColor.lightGrayColor()
                pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
                pageControl.backgroundColor = UIColor.whiteColor()
            }
        }

        accelerometerViewController = storyboard!.instantiateViewControllerWithIdentifier("AccelerometerViewController")
        gyroscopeViewController = storyboard!.instantiateViewControllerWithIdentifier("GyroscopeViewController")
        magnetometerViewController = storyboard!.instantiateViewControllerWithIdentifier("MagnetometerViewController")
        barometerViewController = storyboard!.instantiateViewControllerWithIdentifier("BarometerViewController")
        sonarViewController = storyboard!.instantiateViewControllerWithIdentifier("SonarViewController")

        self.dataSource = self
        self.setViewControllers([ accelerometerViewController! ], direction: .Forward, animated: false, completion: nil)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if (viewController === gyroscopeViewController) {
            return accelerometerViewController!
        } else if (viewController === magnetometerViewController) {
            return gyroscopeViewController
        } else if (viewController === barometerViewController) {
            if (Configuration.theConfig.isMagnetometerActive()) {
                return magnetometerViewController
            } else {
                return gyroscopeViewController
            }

        } else if (viewController === sonarViewController) {
            if (Configuration.theConfig.isBarometerActive()) {
                return barometerViewController
            } else if (Configuration.theConfig.isMagnetometerActive()) {
                return magnetometerViewController
            } else {
                return gyroscopeViewController
            }
        }

        return nil
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if (viewController === accelerometerViewController) {
            return gyroscopeViewController!
        } else if (viewController === gyroscopeViewController) {
            if (Configuration.theConfig.isMagnetometerActive()) {
                return magnetometerViewController
            } else if (Configuration.theConfig.isBarometerActive()) {
                return barometerViewController
            }else if (Configuration.theConfig.isSonarActive()) {
                return sonarViewController
            }
        } else if (viewController === magnetometerViewController) {
            if (Configuration.theConfig.isBarometerActive()) {
                return barometerViewController
            } else if (Configuration.theConfig.isSonarActive()) {
                return sonarViewController
            }

        } else if (viewController === barometerViewController) {
            if (Configuration.theConfig.isSonarActive()) {
                return sonarViewController
            }
            
        }
    
        return nil
    }
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 2 + (Configuration.theConfig.isMagnetometerActive() ? 1 : 0) + (Configuration.theConfig.isBarometerActive() ? 1 : 0) + (Configuration.theConfig.isSonarActive() ? 1 : 0);
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
