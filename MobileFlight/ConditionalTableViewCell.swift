//
//  ConditionalTableViewCell.swift
//  MobileFlight
//
//  Created by Raphael Jean-Leconte on 09/07/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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
