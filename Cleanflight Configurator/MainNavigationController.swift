//
//  MainNavigationController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 16/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MainNavigationController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var storyboard = UIStoryboard(name: "Configuration", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 6)
        }
        storyboard = UIStoryboard(name: "Sensors", bundle: nil)
        if let controller = storyboard.instantiateInitialViewController() {
            viewControllers!.insert(controller, atIndex: 8)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
