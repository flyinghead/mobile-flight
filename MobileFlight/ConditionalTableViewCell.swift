//
//  ConditionalTableViewCell.swift
//  MobileFlight
//
//  Created by Raphael Jean-Leconte on 09/07/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import UIKit

@IBDesignable
class ConditionalTableViewCell: UITableViewCell {

    @IBInspectable var minApiVersion: String?          // inclusive (>=)
    @IBInspectable var maxApiVersion: String?          // exclusive (<)
    
    @IBInspectable var inavSupported: Bool = true
    @IBInspectable var minInavVersion: String?
    @IBInspectable var maxInavVersion: String?
    
    @IBInspectable var betaflightSupported: Bool = true
    @IBInspectable var minBetaflightVersion: String?
    @IBInspectable var maxBetaflightVersion: String?
    
    @IBInspectable var cleanflightSupported: Bool = true
    @IBInspectable var minCleanflightVersion: String?
    @IBInspectable var maxCleanflightVersion: String?

    var visible: Bool {
        let config = Configuration.theConfig
        if minApiVersion != nil && !config.isApiVersionAtLeast(minApiVersion!) {
            return false
        }
        if maxApiVersion != nil && config.isApiVersionAtLeast(maxApiVersion!) {
            return false
        }
        if inavSupported && config.isINav {
            if (minInavVersion == nil || config.isApiVersionAtLeast(minInavVersion!)) && (maxInavVersion == nil || !config.isApiVersionAtLeast(maxInavVersion!)) {
                return true
            }
        }
        if betaflightSupported && config.isBetaflight {
            if (minBetaflightVersion == nil || config.isApiVersionAtLeast(minBetaflightVersion!)) && (maxBetaflightVersion == nil || !config.isApiVersionAtLeast(maxBetaflightVersion!)) {
                return true
            }
        }
        if cleanflightSupported && (!config.isINav && !config.isBetaflight) {
            if (minCleanflightVersion == nil || config.isApiVersionAtLeast(minCleanflightVersion!)) && (maxCleanflightVersion == nil || !config.isApiVersionAtLeast(maxCleanflightVersion!)) {
                return true
            }
        }
        return false
    }
}
