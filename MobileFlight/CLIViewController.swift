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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        appDelegate.stopTimer()

        NotificationCenter.default.addObserver(self, selector: #selector(CLIViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CLIViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(200) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {
            self.msp.cliViewController = self
            self.msp.addOutputMessage(Array(("#").utf8))
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        msp.cliViewController = nil

        appDelegate.startTimer()
    }

    func keyboardDidShow(_ notification: Notification?) {
        let info = notification?.userInfo
        let kbSize = (info![UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.size
        bottomLayoutConstraint.constant = bottomMargin + kbSize.height
    }
    
    func keyboardWillHide(_ notification: Notification?) {
        bottomLayoutConstraint.constant = bottomMargin
    }
    
    fileprivate func sendCommand(_ text: String) {
        msp.addOutputMessage(Array((text + "\n").utf8))
    }
    
    @IBAction func sendAction(_ sender: Any) {
        if historyIndex != -1 {
            // History has been used. The current command (possibly empty) has been stored in the history.
            // It must be deleted and replaced by the actual command sent.
            commandHistory.removeLast()
            historyIndex = -1
        }
        let command = commandField.text!
        commandHistory.append(command)
        let trimmedCommand = command.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmedCommand == "exit" || trimmedCommand == "save" || trimmedCommand == "defaults" {
            exitWithCommand(trimmedCommand)
        } else {
            sendCommand(command)
        }
        commandField.text = ""
    }
    
    @IBAction func exitAction(_ sender: Any) {
        exitWithCommand("exit")
    }
    
    @IBAction func saveAction(_ sender: Any) {
        exitWithCommand("save")
    }
    
    fileprivate func exitWithCommand(_ command: String) {
        SVProgressHUD.show(withStatus: "Rebooting")
        sendCommand(command)
        // Wait 1500 ms
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(1500) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: {
            SVProgressHUD.dismiss()
            self.navigationController?.popViewController(animated: true)
        })
    }
    
    func receive(_ data: [UInt8]) {
        DispatchQueue.main.async(execute: {
            let string = NSString(bytes: data, length: data.count, encoding: String.Encoding.ascii.rawValue)! as String
            let textView = self.textView
            textView?.text.append(string)
            textView?.layoutIfNeeded()
            let contentSize = textView?.contentSize
            //textView.scrollRangeToVisible(NSRange(location: textView.text.characters.count - 2, length: 1))
            let rect = CGRect(origin: CGPoint(x: 0, y: (contentSize?.height)! - (textView?.frame.height)!), size: (textView?.frame.size)!)
            textView?.scrollRectToVisible(rect, animated: true)
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendAction(textField)
        return false
    }
    @IBAction func historyUpAction(_ sender: Any) {
        if historyIndex == -1 {
            commandHistory.append(commandField.text!)
            historyIndex = commandHistory.count - 1
        }
        if historyIndex > 0 {
            historyIndex -= 1
            commandField.text! = commandHistory[historyIndex]
        }
    }
    @IBAction func historyDownAction(_ sender: Any) {
        if historyIndex != -1 && historyIndex < commandHistory.count - 1 {
            historyIndex += 1
            commandField.text! = commandHistory[historyIndex]
        }
    }
}
