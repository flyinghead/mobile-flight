//
//  SensorPagesViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 04/12/15.
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

class SensorPagesViewController: UIPageViewController, UIPageViewControllerDataSource {

    var accelerometerViewController: UIViewController!
    var gyroscopeViewController: UIViewController!
    var magnetometerViewController: UIViewController!
    var barometerViewController: UIViewController!
    var sonarViewController: UIViewController!
    var dataLinkViewController: UIViewController!
    
    var activeViewControllers: [UIViewController]!
    
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
        dataLinkViewController = storyboard!.instantiateViewControllerWithIdentifier("DataLinkViewController")

        self.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        activeViewControllers = [ accelerometerViewController, gyroscopeViewController ]
        
        let config = Configuration.theConfig
        if config.isMagnetometerActive() {
            activeViewControllers.append(magnetometerViewController)
        }
        if config.isBarometerActive() {
            activeViewControllers.append(barometerViewController)
        }
        if config.isSonarActive() {
            activeViewControllers.append(sonarViewController)
        }
        activeViewControllers.append(dataLinkViewController)

        let currentIndex = presentationIndexForPageViewController(self)

        self.setViewControllers([ activeViewControllers[currentIndex] ], direction: .Forward, animated: false, completion: nil)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        guard let index = activeViewControllers.indexOf(viewController) else {
            return nil
        }
        if index == activeViewControllers.startIndex {
            return nil
        }
        
        return activeViewControllers[index.predecessor()]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        guard let index = activeViewControllers.indexOf(viewController) else {
            return nil
        }
        if index == activeViewControllers.endIndex - 1 {
            return nil
        }

        return activeViewControllers[index.successor()]
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return activeViewControllers.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        guard let viewControllers = pageViewController.viewControllers where !viewControllers.isEmpty else {
            return 0
        }
        return activeViewControllers.indexOf(viewControllers[0]) ?? 0
    }
}
