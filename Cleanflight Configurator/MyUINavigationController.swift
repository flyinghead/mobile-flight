//
//  MyUINavigationController.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 14/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

class MyUINavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func popViewControllerAnimated(animated: Bool) -> UIViewController? {
        let viewController = super.popViewControllerAnimated(animated)
        
        if let listener = viewController as! BackButtonListener? {
            listener.backButtonTapped()
        }
        
        return viewController
    }
}

protocol BackButtonListener {
    func backButtonTapped()
}