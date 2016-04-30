//
//  MainConnectionViewController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 27/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MainConnectionViewController: UIViewController {

    @IBOutlet weak var connectionTypeSelector: UISegmentedControl!
    @IBOutlet weak var containerView: UIView!
    
    var viewControllers = [UIViewController]()
    var previousIndex = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        viewControllers.append(storyboard!.instantiateViewControllerWithIdentifier("BluetoothViewController"))
        viewControllers.append(storyboard!.instantiateViewControllerWithIdentifier("WifiViewController"))
        viewControllers.append(storyboard!.instantiateViewControllerWithIdentifier("ReplayViewController"))
        
        for vc in viewControllers {
            addChildViewController(vc)
            vc.didMoveToParentViewController(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controller = viewControllers[0]
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(controller.view)
        
        addConstraints(controller.view, offset: 0)
    }

    private func addConstraints(view: UIView, offset: CGFloat) {
        let left = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: offset)
        containerView.addConstraint(left)
        let right = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: offset)
        containerView.addConstraint(right)
        let top = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)
        containerView.addConstraint(top)
        let bottom = NSLayoutConstraint(item: view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        containerView.addConstraint(bottom)
    }
    
    @IBAction func connectionTypeChanged(sender: AnyObject) {
        let currentIdx = (sender as! UISegmentedControl).selectedSegmentIndex

        let oldVC = viewControllers[previousIndex]
        let newVC = viewControllers[currentIdx]

        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.containerView.addSubview(newVC.view)
        
        let width = containerView.bounds.size.width
        addConstraints(newVC.view, offset: currentIdx < previousIndex ? -width : width)

        self.containerView.layoutIfNeeded()
        
        UIView.animateWithDuration(0.25, delay: 0, options: .LayoutSubviews, animations: {
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
        }

        presentViewController(viewController, animated: true, completion: nil)
    }
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        
        coder.encodeObject(connectionTypeSelector.selectedSegmentIndex, forKey: "ConnectionTypeSelector")
        
        for vc in viewControllers {
            if vc.restorationIdentifier != nil {
                coder.encodeObject(vc, forKey: vc.restorationIdentifier!)
            }
        }
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        
        connectionTypeSelector.selectedSegmentIndex = coder.decodeObjectForKey("ConnectionTypeSelector") as? Int ?? 0
        
        for vc in viewControllers {
            if vc.restorationIdentifier != nil {
                coder.decodeObjectForKey(vc.restorationIdentifier!)
            }
        }
        
        if connectionTypeSelector.selectedSegmentIndex != previousIndex {
            connectionTypeChanged(connectionTypeSelector)
        }
    }
}
