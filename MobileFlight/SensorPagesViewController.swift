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
                pageControl.pageIndicatorTintColor = UIColor.lightGray
                pageControl.currentPageIndicatorTintColor = UIColor.black
                pageControl.backgroundColor = UIColor.white
            }
        }

        accelerometerViewController = storyboard!.instantiateViewController(withIdentifier: "AccelerometerViewController")
        gyroscopeViewController = storyboard!.instantiateViewController(withIdentifier: "GyroscopeViewController")
        magnetometerViewController = storyboard!.instantiateViewController(withIdentifier: "MagnetometerViewController")
        barometerViewController = storyboard!.instantiateViewController(withIdentifier: "BarometerViewController")
        sonarViewController = storyboard!.instantiateViewController(withIdentifier: "SonarViewController")
        dataLinkViewController = storyboard!.instantiateViewController(withIdentifier: "DataLinkViewController")

        self.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
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

        let currentIndex = presentationIndex(for: self)

        self.setViewControllers([ activeViewControllers[currentIndex] ], direction: .forward, animated: false, completion: nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = activeViewControllers.index(of: viewController) else {
            return nil
        }
        if index == activeViewControllers.startIndex {
            return nil
        }
        
        return activeViewControllers[(index - 1)]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = activeViewControllers.index(of: viewController) else {
            return nil
        }
        if index == activeViewControllers.endIndex - 1 {
            return nil
        }

        return activeViewControllers[(index + 1)]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return activeViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let viewControllers = pageViewController.viewControllers, !viewControllers.isEmpty else {
            return 0
        }
        return activeViewControllers.index(of: viewControllers[0]) ?? 0
    }
}
