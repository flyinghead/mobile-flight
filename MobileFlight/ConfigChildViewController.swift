//
//  ConfigChildViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/12/15.
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
    
    func setReference(_ viewController: ConfigurationViewController, newSettings: Settings, newMisc: Misc) {
        self.configViewController = viewController
        self.settings = newSettings
        self.misc = newMisc
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ConfigChildViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ConfigChildViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardDidShow(_ notification: Notification?) {
        let info = notification?.userInfo
        let kbSize = (info![UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
        let contentInsets = UIEdgeInsetsMake(0, 0, kbSize.height, 0)
        
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
        aRect.size.height -= kbSize.height
        if !aRect.contains(activeField!.frame.origin) {
            let scrollPoint = CGPoint(x: 0.0, y: activeField!.frame.origin.y - kbSize.height)
            tableView.setContentOffset(scrollPoint, animated:true)
        }
    }
    
    func keyboardWillHide(_ notification: Notification?) {
        if savedContentInset != nil {
            tableView.contentInset = savedContentInset!
        }
        if savedScrollIndicatorInset != nil {
            tableView.scrollIndicatorInsets = savedScrollIndicatorInset!
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeField = nil
    }

    func showCells(_ cells: [UITableViewCell], show: Bool) {
        for c in cells {
            if let condCell = c as? ConditionalTableViewCell {
                cell(condCell, setHidden: !show || !condCell.visible)
            } else {
                cell(c, setHidden: !show)
            }
        }
    }
}
