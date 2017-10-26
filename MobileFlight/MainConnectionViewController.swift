//
//  MainConnectionViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 27/12/15.
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

class MainConnectionViewController: UIViewController {

    @IBOutlet weak var connectionTypeSelector: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    
    var viewControllers = [UIViewController]()
    var previousIndex = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "BluetoothViewController"))
        viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "WifiViewController"))
        viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "ReplayViewController"))
        viewControllers.append(storyboard!.instantiateViewController(withIdentifier: "SimulatorViewController"))
        
        for vc in viewControllers {
            addChildViewController(vc)
            vc.didMove(toParentViewController: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controller = viewControllers[0]
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(controller.view)
        
        addConstraints(controller.view, offset: 0)
        
        // For KIF tests
        for i in 0 ..< connectionTypeSelector.numberOfSegments {
            connectionTypeSelector.subviews[i].accessibilityLabel = connectionTypeSelector.titleForSegment(at: connectionTypeSelector.numberOfSegments - i - 1)
        }
    }

    fileprivate func addConstraints(_ view: UIView, offset: CGFloat) {
        let left = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.left, multiplier: 1, constant: offset)
        containerView.addConstraint(left)
        let right = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.right, multiplier: 1, constant: offset)
        containerView.addConstraint(right)
        let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
        containerView.addConstraint(top)
        let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: 0)
        containerView.addConstraint(bottom)
    }
    
    @IBAction func connectionTypeChanged(_ sender: Any) {
        let currentIdx = (sender as! UISegmentedControl).selectedSegmentIndex

        let oldVC = viewControllers[previousIndex]
        let newVC = viewControllers[currentIdx]

        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerView.addSubview(newVC.view)
        
        let width = containerView.bounds.size.width
        addConstraints(newVC.view, offset: currentIdx < previousIndex ? -width : width)

        self.containerView.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.25, delay: 0, options: .layoutSubviews, animations: {
            self.containerView.removeConstraints(self.containerView.constraints.filter({
                return $0.firstItem === newVC.view
            }))
            self.addConstraints(newVC.view, offset: 0)

            self.containerView.removeConstraints(self.containerView.constraints.filter({
                return $0.firstItem === oldVC.view
            }))
            self.addConstraints(oldVC.view, offset: currentIdx < self.previousIndex ? width : -width)

            self.containerView.layoutIfNeeded()
        }, completion: { _ in
            oldVC.view.removeFromSuperview()
            self.previousIndex = currentIdx
            
        })
    }

    func presentNextViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateInitialViewController() as! MainNavigationController
        
        if msp.replaying {
            // Remove not available tabs
            viewController.removeViewControllersForReplay()
        } else {
            viewController.enableAllViewControllers()
            appDelegate.startTimer()
        }

        present(viewController, animated: true, completion: nil)
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        coder.encode(connectionTypeSelector.selectedSegmentIndex, forKey: "ConnectionTypeSelector")
        
        for vc in viewControllers {
            if vc.restorationIdentifier != nil {
                coder.encode(vc, forKey: vc.restorationIdentifier!)
            }
        }
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        connectionTypeSelector.selectedSegmentIndex = coder.decodeObject(forKey: "ConnectionTypeSelector") as? Int ?? 0
        
        for vc in viewControllers {
            if vc.restorationIdentifier != nil {
                coder.decodeObject(forKey: vc.restorationIdentifier!)
            }
        }
        
        if connectionTypeSelector.selectedSegmentIndex != previousIndex {
            connectionTypeChanged(connectionTypeSelector)
        }
    }
}
