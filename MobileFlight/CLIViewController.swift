//
//  CLIViewController.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 14/02/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
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
import SVProgressHUD

class CLIViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var commandField: UITextField!

    var bottomMargin: CGFloat!
    var commandHistory = [String]()
    var historyIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        textView.layoutManager.allowsNonContiguousLayout = false
        bottomMargin = bottomLayoutConstraint.constant
        commandField.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        textView.text = "#"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        appDelegate.stopTimer()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CLIViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CLIViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(200) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
            self.msp.cliViewController = self
            self.msp.addOutputMessage(Array(("#").utf8))
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        msp.cliViewController = nil

        appDelegate.startTimer()
    }

    func keyboardDidShow(notification: NSNotification?) {
        let info = notification?.userInfo
        let kbSize = info![UIKeyboardFrameEndUserInfoKey]?.CGRectValue.size
        bottomLayoutConstraint.constant = bottomMargin + kbSize!.height
    }
    
    func keyboardWillHide(notification: NSNotification?) {
        bottomLayoutConstraint.constant = bottomMargin
    }
    
    private func sendCommand(text: String) {
        msp.addOutputMessage(Array((text + "\n").utf8))
    }
    
    @IBAction func sendAction(sender: AnyObject) {
        if historyIndex != -1 {
            // History has been used. The current command (possibly empty) has been stored in the history.
            // It must be deleted and replaced by the actual command sent.
            commandHistory.removeLast()
            historyIndex = -1
        }
        let command = commandField.text!
        commandHistory.append(command)
        let trimmedCommand = command.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if trimmedCommand == "exit" || trimmedCommand == "save" || trimmedCommand == "defaults" {
            exitWithCommand(trimmedCommand)
        } else {
            sendCommand(command)
        }
        commandField.text = ""
    }
    
    @IBAction func exitAction(sender: AnyObject) {
        exitWithCommand("exit")
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        exitWithCommand("save")
    }
    
    private func exitWithCommand(command: String) {
        SVProgressHUD.showWithStatus("Rebooting")
        sendCommand(command)
        // Wait 1500 ms
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(1500) * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
            SVProgressHUD.dismiss()
            self.navigationController?.popViewControllerAnimated(true)
        })
    }
    
    func receive(data: [UInt8]) {
        dispatch_async(dispatch_get_main_queue(), {
            let string = NSString(bytes: data, length: data.count, encoding: NSASCIIStringEncoding) as! String
            let textView = self.textView
            textView.text.appendContentsOf(string)
            textView.layoutIfNeeded()
            let contentSize = textView.contentSize
            //textView.scrollRangeToVisible(NSRange(location: textView.text.characters.count - 2, length: 1))
            let rect = CGRect(origin: CGPoint(x: 0, y: contentSize.height - textView.frame.height), size: textView.frame.size)
            textView.scrollRectToVisible(rect, animated: true)
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        sendAction(textField)
        return false
    }
    @IBAction func historyUpAction(sender: AnyObject) {
        if historyIndex == -1 {
            commandHistory.append(commandField.text!)
            historyIndex = commandHistory.count - 1
        }
        if historyIndex > 0 {
            historyIndex -= 1
            commandField.text! = commandHistory[historyIndex]
        }
    }
    @IBAction func historyDownAction(sender: AnyObject) {
        if historyIndex != -1 && historyIndex < commandHistory.count - 1 {
            historyIndex += 1
            commandField.text! = commandHistory[historyIndex]
        }
    }
}
