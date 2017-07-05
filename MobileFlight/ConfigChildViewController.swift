//
//  ConfigChildViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class ConfigChildViewController: StaticDataTableViewController, UITextFieldDelegate {
    
    weak var configViewController: ConfigurationViewController!
    var settings: Settings!
    var misc: Misc!

    weak var activeField: UITextField?
    
    var savedContentInset: UIEdgeInsets?
    var savedScrollIndicatorInset: UIEdgeInsets?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideSectionsWithHiddenRows = true
    }
    
    func setReference(viewController: ConfigurationViewController, newSettings: Settings, newMisc: Misc) {
        self.configViewController = viewController
        self.settings = newSettings
        self.misc = newMisc
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConfigChildViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ConfigChildViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardDidShow(notification: NSNotification?) {
        let info = notification?.userInfo
        let kbSize = info![UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size
        let contentInsets = UIEdgeInsetsMake(0, 0, kbSize!.height, 0)
        
        if savedContentInset == nil {
            savedContentInset = tableView.contentInset
        }
        if savedScrollIndicatorInset == nil {
            savedScrollIndicatorInset = tableView.scrollIndicatorInsets
        }
        
        tableView.contentInset = contentInsets
        tableView.scrollIndicatorInsets = contentInsets
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your application might not need or want this behavior.
        if activeField == nil {
            return
        }
        var aRect = self.view.frame
        aRect.size.height -= kbSize!.height
        if !CGRectContainsPoint(aRect, activeField!.frame.origin) {
            let scrollPoint = CGPointMake(0.0, activeField!.frame.origin.y - kbSize!.height)
            tableView.setContentOffset(scrollPoint, animated:true)
        }
    }
    
    func keyboardWillHide(notification: NSNotification?) {
        if savedContentInset != nil {
            tableView.contentInset = savedContentInset!
        }
        if savedScrollIndicatorInset != nil {
            tableView.scrollIndicatorInsets = savedScrollIndicatorInset!
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        activeField = nil
    }
}